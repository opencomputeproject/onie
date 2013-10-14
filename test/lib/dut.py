#
# DUT Base class
#

'''
Defines a base "Device Under Test" object
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
    import connection
    import power
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

# gdut -- Global DUT instance
#
# Make the single DUT object instance available to the TestCase
# classes via the gdut_get() method.
gdut = None

def gdut_set(d):
    global gdut
    if gdut is not None:
        logging.critical("global DUT is already set.\n")
        sys.exit(1)
    gdut = d

def gdut_get():
    if gdut is None:
        logging.critical("ERROR: global DUT is not set.\n")
        sys.exit(1)
    return gdut

class DUT:
    '''
    Base Device Under Test (DUT) class
    '''
    def __init__(self, name, args, config, test_result):
        if gdut is not None:
            logging.critical("ERROR: global DUT is already created.\n")
            sys.exit(1)

        self.name = name
        self.args = args
        self.config = config
        cnx_class  = connection.find_connection(config.get(name, 'console_proto'))
        self._cnx  = cnx_class(self)
        power_class  = power.find_power_control(config.get(name, 'power_proto'))
        self._power  = power_class(self)
        self.test_result = test_result

        gdut_set(self)

    # The DUT class proxies the connection class methods via its 'cnx'
    # instance variable
    def open(self, prompt=""):
        return self._cnx.open(prompt)

    def close(self):
        return self._cnx.close()

    def send(self, line, timeout=-1):
        return self._cnx.send(line, timeout)

    def sendline(self, line):
        return self._cnx.sendline(line)

    def expect(self, string, timeout=-1):
        return self._cnx.expect(string, timeout)

    def set_prompt(self, prompt=""):
        return self._cnx.set_prompt(prompt)

    # The DUT class proxies the power class methods via its 'power'
    # instance variable: open(), send(), close()
    def power_on(self):
        return self._power.on()

    def power_off(self):
        return self._power.off()

    def power_cycle(self):
        return self._power.cycle()

    def get_config(self, option):
        return self.config.get(self.name, option)
