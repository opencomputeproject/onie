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
        logging.critical("global DUT is not set.\n")
        sys.exit(1)
    return gdut

class DUT:
    '''
    Base Device Under Test (DUT) class
    '''
    def __init__(self, name, args, config, test_result):
        if gdut is not None:
            logging.critical("global DUT is already created.\n")
            sys.exit(1)

        self.name = name
        self.args = args
        self.config = config
        cnx_class  = connection.find_connection(config.get(name, 'console_proto'))
        self._cnx  = cnx_class(self)
        power_class  = power.find_power_control(config.get(name, 'power_proto'))
        self._power  = power_class(self)
        self.test_result = test_result
        self.uboot_eeprom = None

        gdut_set(self)


    def read_uboot_eeprom(self):
        '''
        Issue the 'sys_eeprom' command from U-Boot and save the
        result.  Platforms that use a different command will want to
        sub-class this DUT.
        '''
        self.uboot_eeprom = self.send('sys_eeprom')

    def _parse_tlv_eeprom(self, code):
        '''
        Screen scrape the text representation of the ONIE TLV EEPROM
        contents, looking for the specified field.

        code -- the TLV code to look for.
        '''
        m = re.search('.*0x%02X\s+[0-8]+\s+(.*)' % (code), self.uboot_eeprom)
        if m is None or m.lastindex != 1:
            logging.warning("Unable to find TLV code 0x%02X in EEPROM data:" %
                            (code) + "\n" + self.uboot_eeprom)
            return None
        return m.group(1).strip('\r\n')

    def get_uboot_mac_addr(self):
        '''
        Retreive the Ethernet management MAC address from the EEPROM,
        using the U-Boot CLI.
        '''
        if self.uboot_eeprom is None:
            self.read_uboot_eeprom()

        # Screen scrape the MAC address
        # Base MAC Address     0x24   6 00:04:9F:02:80:A4
        mac = self.parse_tlv_eeprom(0x24)
        if mac is None:
            logging.critical("Unable to find MAC address in EEPROM data:" +
                             "\n" + self.uboot_eeprom)
        return mac

    def get_uboot_serial_num(self):
        '''
        Retreive the DUT serial number the EEPROM, using the U-Boot
        CLI.
        '''
        if self.uboot_eeprom is None:
            self.read_uboot_eeprom()

        # Screen scrape the Serial Number
        # Serial Number        0x23  22 fake-serial-0123456789
        sn = self.parse_tlv_eeprom(0x23)
        if sn is None:
            logging.critical("Unable to find serial number in EEPROM data:" +
                             "\n" + self.uboot_eeprom)
        return sn

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
