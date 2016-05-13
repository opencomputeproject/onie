#!/usr/bin/env python

# -----------------------------------------------------------------------------
# Copyright (C) 2015-2016 Carlos Cardenas <carlos@cumulusnetworks.com>
#
# SPDX-License-Identifier:     GPL-2.0
#
# -----------------------------------------------------------------------------


from cStringIO import StringIO
import logging
import os
import os.path
import re
import sys
import threading
import time

from flask import Flask
from flask import json
from flask import request

from oce import OPTIONS, PRETTY_OPTIONS

DEFAULT_OUTPUT_DIR = 'output'
DEFAULT_PORT = 8888
DUT_CONFIG = {}
DUT_PROTOCOL = None
DUT_URLS = ['console', 'ssh', 'telnet']
DUT_URLS_MSG = \
'''
Available URLS:
console://PORT
ssh://HOST
telnet://HOST
'''

# logger
logger = logging.getLogger('OCE-EYES')

if sys.version_info >= (3, 0):
    def character(c):
        return c.decode('latin1')
else:
    def character(c):
        return c


class RESTInterface(object):
    def __init__(self, ip_addr, port, conn_obj, output_dir):
        self.conn = conn_obj
        self.ip_addr = ip_addr
        self.port = port
        self.output_dir = output_dir
        self.app = Flask('eyes')

    def status(self):
        resp = json.jsonify(status=str(self.conn))
        resp.status_code = 200
        return resp

    def start_test(self, test_num):
        self.conn.remove_handler()
        test_str = 'test-{0}'.format(test_num)
        filename = os.path.join(os.path.abspath(self.output_dir), test_str)
        self.conn.add_handler(filename)
        resp = json.jsonify(status='START - SUCCESS')
        resp.status_code = 200
        return resp

    def run_test(self):
        json_data = request.get_json(force=True)
        status = self.conn.run_cmd(json_data['cmd_str'])
        resp = None
        if status is True:
            resp = json.jsonify(status='TEST - SUCCESS')
            resp.status_code = 200
        else:
            resp = json.jsonify(status='TEST - FAILED')
            resp.status_code = 520
        return resp

    def stop_test(self):
        self.conn.remove_handler()
        resp = json.jsonify(status='STOP - SUCCESS')
        resp.status_code = 200
        return resp

    def shutdown(self):
        self.conn.stop()
        resp = json.jsonify(status='SHUTDOWN - SUCCESS')
        resp.status_code = 200
        return resp

    def reconnect(self):
        self.conn.reconnect()
        resp = json.jsonify(status='Reconnect - SUCCESS')
        resp.status_code = 200
        return resp

    def start(self):
        self.app.add_url_rule('/', 'index', self.status)
        self.app.add_url_rule('/start_test/<int:test_num>', 'start_test',
                              self.start_test, methods=['POST'])
        self.app.add_url_rule('/stop_test', 'stop_test', self.stop_test)
        self.app.add_url_rule('/run_test', 'run_test',
                              self.run_test, methods=['POST'])
        self.app.add_url_rule('/shutdown', 'shutdown',
                              self.shutdown, methods=['POST'])
        self.app.add_url_rule('/reconnect', 'reconnect',
                              self.reconnect, methods=['POST'])
        self.app.run(host=self.ip_addr, port=self.port)


class BaseConnection(threading.Thread):
    def __init__(self):
        super(BaseConnection, self).__init__()
        self.conn_logger = logging.getLogger('OCE-EYES')
        self.conn_handler = None
        self.conn_open = False
        self.timeout = 5
        self.should_stop = False

    def connected(self):
        return self.conn_open

    def login(self, username, password):
        pass

    def logout(self):
        pass

    def reconnect(self):
        pass

    def run_cmd(self, cmd_str):
        pass

    def stop(self):
        self.should_stop = True

    def add_handler(self, output_filename):
        self.conn_handler = logging.FileHandler(output_filename)
        self.conn_handler.setLevel(logging.INFO)
        self.conn_logger.addHandler(self.conn_handler)
        self.conn_logger.info('Starting...')

    def remove_handler(self):
        if self.conn_handler is not None:
            self.conn_logger.info('Stopping...')
            self.conn_logger.removeHandler(self.conn_handler)
            self.conn_handler = None


class SerialConnection(BaseConnection):
    def __init__(self, port=None, speed=115200):
        import serial_device2
        super(SerialConnection, self).__init__()
        self.serial_port = port
        self.serial_speed = speed
        self.conn = serial_device2.SerialDevice(port=self.serial_port,
                                                baudrate=self.serial_speed)
        self.conn_open = True

    def __str__(self):
        msg = 'Connnector: Serial, Port: %s, Speed: %d' % (self.serial_port,
                                                           self.serial_speed)
        return msg

    def disconnect(self):
        '''
        SerialConnector method to disconnect from serial device
        '''
        self.stop()
        self.conn.close()
        self.conn_open = False

    def run_cmd(self, cmd_str):
        # add newline to cmd_str
        new_cmd_str = '\n'.format(cmd_str)
        res = self.conn.write(new_cmd_str)
        if res == len(new_cmd_str):
            return True
        return False

    def run(self):
        import serial
        try:
            buf = StringIO()
            while self.should_stop is False:
                data = self.conn.read(1)
                # if data is a newline, flush buffer
                if data in '\r\n':
                    if len(buf.getvalue()) > 0:
                        self.conn_logger.info(buf.getvalue())
                        buf = StringIO()
                    else:
                        time.sleep(1)
                else:
                    buf.write(data)
        except serial.SerialException:
            raise
        self.disconnect()


class SSHConnection(BaseConnection):
    def __init__(self, host=None, port=22):
        import paramiko
        super(SSHConnection, self).__init__()
        self.host = host
        self.port = port
        self.conn = paramiko.client.SSHClient()
        self.key_policy = paramiko.AutoAddPolicy()
        self.conn.set_missing_host_key_policy(self.key_policy)

    def __str__(self):
        msg = 'Connnector: SSH, Hostname: %s, Port: %s' % (self.host,
                                                           self.port)
        return msg

    def login(self, username, password):
        self.username = username
        self.password = password
        self.conn.connect(hostname=self.host, port=self.port,
                          username=self.username, password=self.password,
                          timeout=self.timeout)
        self.conn_open = True

    def logout(self):
        self.conn.close()
        self.conn_open = False

    def reconnect(self):
        self.logout()
        self.conn.connect(hostname=self.host, port=self.port,
                          username=self.username, password=self.password,
                          timeout=self.timeout)
        self.conn_open = True

    def run_cmd(self, cmd_str):
        try:
            self.conn_logger.info('EXECUTING: {0}'.format(cmd_str))
            (stdin, stdout, stderr) = self.conn.exec_command(cmd_str)
            stdin.close()
            self.conn_logger.info('STDOUT:\n{0}'.
                                  format(''.join(stdout.readlines())))
            stdout.close()
            self.conn_logger.info('STDERR:\n{0}'.
                                  format(''.join(stderr.readlines())))
            stderr.close()
            return True
        except paramiko.SSHException:
            return False

    def run(self):
        '''
        No need to run a loop as only way to read from paramiko
        is with exec_command which blocks
        '''
        pass


class TelnetConnection(BaseConnection):
    def __init__(self, host=None, port=23):
        import telnetlib
        super(TelnetConnection, self).__init__()
        self.host = host
        self.port = port
        self.conn = telnetlib.Telnet()

    def __str__(self):
        msg = 'Connnector: Telnet, Hostname: %s, Port: %s' % (self.host,
                                                              self.port)
        return msg

    def login(self, username, password):
        self.conn.open(self.host, self.port, self.timeout)
        self.conn_open = True

    def logout(self):
        self.conn.close()
        self.conn_open = False

    def run_cmd(self, cmd_str):
        pass


def validate_interface(iface):
    import netifaces
    if iface == 'all' or iface in netifaces.interfaces():
        return True
    else:
        return False


def get_ip_addr_from_interface(iface):
    if iface == 'all':
        return '0.0.0.0'

    import netifaces
    ip_addr_str = None
    addrs = netifaces.ifaddresses(iface)

    # Check for IPv4 address, first
    if netifaces.AF_INET in addrs:
        # get first addr
        ip_addr_str = addrs[netifaces.AF_INET][0]['addr']
    elif netifaces.AF_INET6 in addrs:
        # get first addr
        ip_addr_str = addrs[netifaces.AF_INET6][0]['addr']

    return ip_addr_str


def validate_eyes_url():
    s_url = DUT_CONFIG['options']['eyes_dut_url'].split('://')
    if len(s_url) == 2 and s_url[0] in DUT_URLS:
        return True
    else:
        return False


def validate_options(options):
    # check all keys in args.option to ensure they are supported
    # while checking, type convert
    for key, value in options.iteritems():
        if key in OPTIONS.keys():
            options[key] = OPTIONS[key](value)
        else:
            logger.critical('Unsupported option: {0}'.format(key))
            parser.print_help()
            sys.exit(-1)


def load_dut_config(filename):
    import json
    global DUT_CONFIG
    try:
        DUT_CONFIG = json.load(open(filename, 'r'))
        logger.info('Loaded DUT config from {0}'.format(filename))

        # check options
        if DUT_CONFIG['options'] is not None and\
           len(DUT_CONFIG['options'].keys()) > 0:
            validate_options(DUT_CONFIG['options'])

    except:
        logger.critical('Invalid DUT config file. Aborting...')
        sys.exit(-1)


def main():
    import argparse
    parser = argparse.ArgumentParser(description="OCE-EYES")
    parser.add_argument('-d', '--dut-config', action='store', metavar='CONFIG',
                        default=None,
                        help='DUT configuration file')
    parser.add_argument('-I', '--interface', action='store',
                        help='Interface to bind against')
    parser.add_argument('-p', '--port', action='store',
                        help='port to use')
    parser.add_argument('-v', '--verbose', action='store_true',
                        default=False,
                        help='increase the verbosity level')
    parser.add_argument('-O', '--output-dir', action='store', metavar='DIR',
                        default=DEFAULT_OUTPUT_DIR,
                        help='output director (default: {0})'.
                        format(DEFAULT_OUTPUT_DIR))
    # parser.add_argument('--interactive', action='store_true',
    #                     default=False,
    #                     help='open an interactive shell to DUT')
    args = parser.parse_args()

    ch = logging.StreamHandler()
    ch.setLevel(logging.INFO)
    fmt_str = '%(asctime)s - %(levelname)s - %(message)s'
    formatter = logging.Formatter(fmt_str, '%Y-%m-%dT%H:%M:%S')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    logger.setLevel(logging.INFO)

    # check args.output_dir and create dir structure if necessary
    abspath = os.path.abspath(args.output_dir)
    if os.path.exists(abspath):
        # if file, remove it
        if os.path.isfile(abspath):
            os.remove(abspath)
    else:
        os.makedirs(abspath)

    if args.verbose:
        ch.setLevel(logging.DEBUG)
        logger.setLevel(logging.DEBUG)

    if args.dut_config is not None:
        load_dut_config(args.dut_config)

    if args.interface is None:
        # check DUT_CONFIG
        if 'options' in DUT_CONFIG and \
           'eyes_interface' in DUT_CONFIG['options']:
            args.interface = DUT_CONFIG['options']['eyes_interface']
        else:
            args.interface = 'all'

    if validate_interface(args.interface) is False:
        logger.critical('Interface {0} is not present'.format(args.interface))
        parser.print_help()
        sys.exit(-1)

    if args.port is None:
        # check DUT_CONFIG
        if 'options' in DUT_CONFIG and 'eyes_port' in DUT_CONFIG['options']:
            args.port = DUT_CONFIG['options']['eyes_port']
        else:
            args.port = DEFAULT_PORT

    if 'options' not in DUT_CONFIG:
        logger.critical('Missing options in DUT_CONFIG')
        parser.print_help()
        sys.exit(-1)
    elif 'eyes_dut_url' not in DUT_CONFIG['options']:
        logger.critical('URL is not present to connect to DUT')
        parser.print_help()
        sys.exit(-1)
    elif validate_eyes_url() is False:
        logger.critical('URL to connect to DUT is invalid')
        logger.critical(DUT_URLS_MSG)
        sys.exit(-1)
    else:
        # check the remainder of the eyes_dut_* options
        (proto, host_port) = DUT_CONFIG['options']['eyes_dut_url'].split('://')

        # double check if eyes_dut_{user,password} is required for proto

        if 'eyes_dut_user' not in DUT_CONFIG['options']:
            logger.critical('Missing Username to log into DUT')
            parser.print_help()
            sys.exit(-1)

        if 'eyes_dut_password' not in DUT_CONFIG['options']:
            logger.critical('Missing Password to log into DUT')
            parser.print_help()
            sys.exit(-1)

        if proto == 'console':
            # optional is speed, default is 115200
            if 'eyes_dut_console_speed' not in DUT_CONFIG['options']:
                DUT_CONFIG['options']['eyes_dut_console_speed'] = 115200

        if proto in ['ssh', 'telnet']:
            # optional is port
            if 'eyes_dut_port' not in DUT_CONFIG['options']:
                if proto == 'ssh':
                    DUT_CONFIG['options']['eyes_dut_port'] = 22
                if proto == 'telnet':
                    DUT_CONFIG['options']['eyes_dut_port'] = 23

        # ready to launch a connection
        username = DUT_CONFIG['options']['eyes_dut_user']
        password = DUT_CONFIG['options']['eyes_dut_password']
        client = None
        if proto == 'console':
            con_port_speed = DUT_CONFIG['options']['eyes_dut_console_speed']
            client = SerialConnection(host_port, con_port_speed)
        elif proto == 'ssh':
            port = DUT_CONFIG['options']['eyes_dut_port']
            client = SSHConnection(host_port, port)
        elif proto == 'telnet':
            port = DUT_CONFIG['options']['eyes_dut_port']
            client = TelnetConnection(host_port, port)
        else:
            logger.critical('Invalid Proto: %s'.format(proto))
            parser.print_help()
            sys.exit(-1)

        # start the connection
        client.start()
        client.login(username, password)

        # ready to bind REST interface
        rest_ip_addr_str = get_ip_addr_from_interface(args.interface)
        if rest_ip_addr_str is None:
            logger.critical('No valid IP address found on {0}'.
                            format(args.interface))
            logger.critical('Shutting down...')
            client.stop()
            sys.exit(-1)
        rest = RESTInterface(rest_ip_addr_str, args.port, client, abspath)
        # start up the web thread
        rest.start()

        try:
            client.logout()
            client.stop()
            client.join(True)
        except KeyboardInterrupt:
            client.stop()
        client.join()


if __name__ == '__main__':
    main()
