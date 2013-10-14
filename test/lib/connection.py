#
# DUT Connection classes
#

'''
Defines a Connection object that the test fixture uses to communicate
with a DUT.
'''

#-------------------------------------------------------------------------------
#
# Imports
#

try:
    import sys
    import os
    import re
    import io
    import logging
    import pexpect
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

class Connection:
    '''
    Base connection class
    '''

    proto = None

    def __init__(self, dut):
        self.dut = dut
        self.child = None

    def open(self, prompt=""):
        '''
        Open the DUT communication channel.

        prompt -- default CLI prompt to synchronize to
        '''

        self.prompt = re.compile(prompt)
        to = int(self.dut.get_config('timeout'))
        logging.info("Opening connection: " + self.command)
        self.child = pexpect.spawn(self.command, timeout=to)
        logging.info("Logging console output: " + self.dut.args.console_log.name)
        self.child.logfile = self.dut.args.console_log
        self._login()
        self.send('')
        
    def _login(self):
        '''
        After open() _login() is called to provide any required chat.
        '''
        pass

    def close(self):
        '''
        Close the DUT communication channel
        '''

        self.child.close(force=True)

    def expect(self, pattern, timeout=-1):
        '''
        Monitor DUT communication channel, looking for a pattern.

        pattern -- pattern to look for
        timeout -- how many seconds to wait for pattern to show up. -1 is connection default.
        '''

        try:
            self.child.expect(pattern, timeout=timeout)
        except pexpect.EOF, e:
            logging.critical("pexpect received EOF while expecting: " + pattern)
            raise
        except pexpect.TIMEOUT, e:
            if timeout != -1:
                to = timeout
            else:
                to = self.child.timeout
            logging.critical("pexpect received TIMEOUT (%d secs) while expecting: %s" %
                             (to, pattern))
            raise

        logging.debug("before text: %s" % (self.child.before))
        logging.debug("match  text: %s" % (self.child.match))
        logging.debug("after  text: %s" % (self.child.after))

        return self.child.before

    def send(self, line, timeout=-1):
        '''
        Send line to DUT and wait for DUT prompt.

        line    -- string to send to DUT.  A newline is added automatically.
        timeout -- how many seconds to wait for prompt. -1 is connection default.
        '''

        self.child.sendline(line)

        try:
            output = self.expect(self.prompt, timeout)
        except pexpect.EOF, e:
            logging.critical("pexpect received EOF while sending: " + line)
            sys.exit(1)
        except pexpect.TIMEOUT, e:
            if timeout != -1:
                to = timeout
            else:
                to = self.child.timeout
            logging.critical("pexpect received TIMEOUT (%d secs) while sending: %s" %
                             (to, line))
            sys.exit(1)

        # Return the output, split into lines.  Also skip the first
        # line as it is just an echo of the command sent.
        return output.splitlines()[1:]

    def sendline(self, line):
        '''
        Send line to DUT and return immediately.

        line    -- string to send to DUT.  A newline is added automatically.
        '''
        self.child.sendline(line)

    def set_prompt(self, pattern):
        '''
        Set the prompt to wait for when issuing CLI commands.

        pattern -- The pattern representing the prompt.
        '''
        self.prompt = re.compile(pattern)

class SimpleTelnetConnection(Connection):
    '''
    Simple telnet connection that does not require a password.
    '''
    proto = "telnet-simple"

    def __init__(self, dut):
        server = dut.get_config('telnet_server')
        port = dut.get_config('telnet_port')
        self.command = "/usr/bin/telnet %s %s" % (server, port)
        Connection.__init__(self, dut)

class AuthTelnetConnection(SimpleTelnetConnection):
    '''
    Authenticated telnet connection that requires a username and
    password.
    '''

    proto = "telnet"

    def _login(self):

        index = self.child.expect(["login: ", pexpect.EOF, pexpect.TIMEOUT])
        if index == 1:
            logging.critical("pexect received EOF during telnet login")
            sys.exit(1)
        elif index == 2:
            to = self.child.timeout
            logging.critical("received TIMEOUT (%d secs) during telnet login" %
                             (to))
            sys.exit(1)

        user = self.dut.get_config('telnet_user')
        self.child.sendline(user)

        index = self.child.expect(["Password: ", pexpect.EOF, pexpect.TIMEOUT])
        if index == 1:
            logging.critical("pexect received EOF during telnet password")
            sys.exit(1)
        elif index == 2:
            to = self.child.timeout
            logging.critical("received TIMEOUT (%d secs) during telnet password" %
                             (to))
            sys.exit(1)

        pw   = self.dut.get_config('telnet_pass')
        self.child.sendline(pw)

class SSHConnection(Connection):
    '''
    Authenticated SSH connection that requires a username and password.
    '''

    proto = "ssh"

    def __init__(self, dut):
        server = dut.get_config('ssh_server')
        port = dut.get_config('ssh_port')
        user = dut.get_config('ssh_user')
        self.command = "/usr/bin/ssh -p %s %s@%s" % (port, user, server)
        Connection.__init__(self, dut)

    def _login(self):
        index = self.child.expect(["Password: ", pexpect.EOF, pexpect.TIMEOUT])
        if index == 1:
            logging.critical("pexect received EOF during ssh login")
            sys.exit(1)
        elif index == 2:
            to = self.child.timeout
            logging.critical("pexect received TIMEOUT (%d secs) during ssh login" %
                             (to))
            sys.exit(1)

        pw   = self.dut.get_config('ssh_pass')
        self.child.sendline(pw)

#
# Registry of available Connection classes
#
connection_protos = (SimpleTelnetConnection,
                     AuthTelnetConnection,
                     SSHConnection,)

class NoSuchConnection(RuntimeError):
    pass

def find_connection(proto):
    for c in connection_protos:
        if c.proto == proto:
            return c

    raise NoSuchConnection('Connection proto not found: %s' % (proto))
