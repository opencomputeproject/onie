#
# DUT Power Control classes
#

'''
Defines a 'PowerControl' object that a the test fixture uses to power cycle
the DUT.
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
    from test_utils import *
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

class PowerControl(object):
    '''
    Base power control class
    '''

    proto = None

    def __init__(self, dut):
        self.dut = dut
        self.child = None

    def on(self):
        '''
        Power on the DUT.
        '''
        raise NotImplementedError

    def off(self):
        '''
        Power off the DUT.
        '''
        raise NotImplementedError

    def cycle(self):
        '''
        Power cycle the DUT.
        '''
        raise NotImplementedError

class PowcPowerControl(PowerControl):
    '''
    Home grown power control class that uses an external script called
    "powc".
    '''
    proto = "powc"

    def __init__(self, dut):
        self.exe = dut.config.get(dut.name, 'powc_exe')
        self.server = dut.config.get(dut.name, 'powc_server')
        self.port = dut.config.get(dut.name, 'powc_port')

    def off(self):
        cmd = "%s off %s %s" % (self.exe, self.server, self.port)
        (retval, output) = exec_command(cmd)
        if retval != 0:
            logging.critical("Problems powering off DUT: " + cmd)
            sys.exit(1)

    def cycle(self):
        cmd = "%s cycle %s %s" % (self.exe, self.server, self.port)
        (retval, output) = exec_command(cmd)
        if retval != 0:
            logging.critical("Problems power cycling DUT: " + cmd)
            sys.exit(1)

    def on(self):
        # For this proto 'on' is the same as 'cycle'.
        self.cycle()

#
# Registry of available Power Control classes
#
power_protos = (PowcPowerControl,
                )

class NoSuchPowerControl(RuntimeError):
    pass

def find_power_control(proto):
    for c in power_protos:
        if c.proto == proto:
            return c

    raise NoSuchPowerControl('Power control proto not found: %s' % (proto))
