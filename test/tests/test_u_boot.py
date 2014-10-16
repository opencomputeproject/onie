#
# Common U-Boot Tests
#

#  Copyright (C) 2013 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

try:
    import sys
    import os
    import re
    import io
    import logging
    import unittest
    from test_base import BaseTestCase
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

class UBootTestCase(BaseTestCase):
    '''
    Abstract base class for U-Boot based tests.
    '''

    BaseTestCase.prompt = "=>"

    def sync_uboot_prompt(self, timeout=-1):
        '''
        When this method is invoked the system is expected to reboot
        or power cycle autonomously.  The objective of this method is
        to look for the U-Boot banner and halt the boot process at the
        U-Boot prompt.
        '''
        self.dut.expect('Hit any key', timeout=timeout)
        self.dut.send('')

    @property
    def u_boot_version(self, timeout=-1):
        '''
        Get the running U-Boot version
        '''
        self.dut.send('')
        return self.dut.send("echo $ver")[0]

class Test100_UBootInitialize(UBootTestCase):
    '''
    Test suite to initialize a DUT.

    The tests in this suite bring the DUT to a known state, including:

    1. Power cycle the unit
    2. Install a particular version of ONIE
    '''

    org_failfast = None

    @classmethod
    def setUpClass(cls):
        UBootTestCase.setUpClass()
        # Disable further test execution if tests in this class fail.
        Test100_UBootInitialize.org_failfast = BaseTestCase.dut.test_result.failfast
        BaseTestCase.dut.test_result.failfast = True

    @classmethod
    def tearDownClass(cls):
        UBootTestCase.tearDownClass()
        # Restore original failfast setting
        BaseTestCase.dut.test_result.failfast = Test100_UBootInitialize.org_failfast

    def test_00_power_cycle(self):
        '''
        Power Cycle the DUT and synchronize to the U-Boot prompt
        '''
        logging.debug("power cycling DUT")

        self.dut.power_cycle()
        self.sync_uboot_prompt(timeout=120)
        text = self.u_boot_version
        self.assertIn("U-Boot", text,
                      "After power cycle no U-Boot version string")

    def test_10_install_onie(self):
        '''
        Install the ONIE version specified in the config file
        '''
        logging.debug("Installing ONIE")
        # clear onie_version variable -- a successful onie update will change it
        self.dut.send("setenv onie_version xxx")
        onie_url = self.dut.get_config('onie_url')
        self.dut.send('saveenv')
        logging.debug("Using ONIE url: " + onie_url)
        self.dut.send("setenv onie_debugargs install_url=" + onie_url)
        # boot ONIE with install URL - could take a while
        self.dut.sendline("run onie_update")
        # Look for ONIE update mode
        self.dut.expect("update mode detected", 60)
        # Look for installer execution
        self.dut.expect("Executing installer:", 60)
        # Wait for install and reboot
        self.sync_uboot_prompt(120)
        # check version of ONIE changed
        text = self.u_boot_version
        onie_version = self.dut.get_config('onie_version')
        self.assertIn(onie_version, text,
                      "Could not find ONIE version " + onie_version)

class Test300_UBootFeatures(UBootTestCase):
    '''
    Test cases that only involve U-Boot.  All the tests here can be
    exercised from U-Boot, possibly with a reset required.
    '''

    def setUp(self):
        logging.debug("Common U-Boot Tests setUp()")
        self.seq = range(10)

    def test_10_onie_version(self):
        text = self.u_boot_version
        onie_version = self.dut.get_config('onie_version')
        self.assertIn(onie_version, text,
                      "Could not find ONIE version " + onie_version)

    def test_15_mac_address(self):
        "Read MAC address from EEPROM"
        eeprom_mac = self.dut.uboot_mac_addr
        self.assertIsNot(eeprom_mac, None,
                         "Could not find ONIE MAC address")
        logging.info("Base MAC address: " + eeprom_mac)

    def test_15_serial_number(self):
        "Read serial number from EEPROM"
        eeprom_sn = self.dut.uboot_serial_num
        self.assertIsNot(eeprom_sn, None,
                         "Could not find ONIE serial number")
        logging.info("Serial Number: " + eeprom_sn)

    def test_20_verify_default_vars(self):
        '''
        Verify U-Boot sets environement variable defaults from the
        EEPROM contnets:

          -- 'ethaddr' variable
          -- 'serial#' variable

        '''
        # Clear variables and reboot
        eeprom_mac = self.dut.uboot_mac_addr
        eeprom_sn  = self.dut.uboot_serial_num
        self.dut.send("setenv ethaddr")
        self.dut.send("setenv serial#")
        self.dut.send('saveenv')
        self.dut.sendline("reset")
        self.sync_uboot_prompt(30)
        output = self.dut.send("echo $ethaddr")
        ethaddr = output[0]
        self.assertEqual(eeprom_mac, ethaddr,
                         "EEPROM MAC address and ethaddr variable differ\n" +
                         "  EEPROM MAC: >>>" + eeprom_mac + "<<<\n" +
                         "  ethaddr   : >>>" + ethaddr + "<<<\n")
        output = self.dut.send("echo ${serial#}")
        serial = output[0]
        self.assertEqual(eeprom_sn, serial,
                         "EEPROM serial number and serial# variable differ\n" +
                         "  EEPROM SN: >>>" + eeprom_sn + "<<<\n" +
                         "  serial#  : >>>" + serial + "<<<\n")

class Test350_NOS(UBootTestCase):
    '''
    Test cases that interact with a NOS, including NOS installation.
    '''

    def test_10_nos_dhcp_install(self):
        '''
        Test installing the DEMO NOS where the DHCP server specifies
        default-url (option 114).

        Here is a very simple configuration using dnsmasq as the DHCP
        server:

          # Map Vendor Class to dnsmasq tag 'onie'
          dhcp-vendorclass=set:onie,onie_vendor:

          # set default URL (option 114)
          dhcp-option=tag:onie,114,"http://test-04/onie/demo-nos-installer.bin"

        '''

        # Run ONIE in 'installer' mode
        self.dut.send("setenv nos_bootcmd echo")
        self.dut.sendline("boot")
        # Look for ONIE installer mode
        self.dut.expect("installer mode detected", 60)
        # Look for installer execution
        self.dut.expect("Executing installer:", 60)
        # Installer runs, system should reboot -- look for U-Boot
        self.dut.expect("Hit any key to stop autoboot:", 120)
        # Should boot into demo NOS
        self.dut.expect("Welcome to the %s platform" % self.dut.type, 120)
        self.dut.expect("Please press Enter to activate this console")
        uboot_prompt = self.dut.prompt
        self.dut.prompt = re.compile(".*:.* #")
        self.dut.send("")
        self.dut.sendline("reboot")
        # restore uboot prompt
        self.dut.prompt = uboot_prompt
        self.sync_uboot_prompt(30)
