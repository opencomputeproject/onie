#
# Common U-Boot Tests
#

try:
    import sys
    import os
    import re
    import io
    import logging
    import unittest
    import random
    from test_base import BaseTestCase
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

class UBootTestCase(BaseTestCase):
    '''
    Abstract base class for U-Boot based tests.
    '''
    def sync_uboot_prompt(self, timeout=-1):
        '''
        When this method is invoked the system is expected to reboot
        or power cycle autonomously.  The objective of this method is
        to look for the U-Boot banner and halt the boot process at the
        U-Boot prompt.
        '''
        self.dut.expect('Hit any key', timeout=timeout)
        self.dut.send('')

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
        BaseTestCase.setUpClass()
        # Disable further test execution if tests in this class fail.
        Test100_UBootInitialize.org_failfast = BaseTestCase.dut.test_result.failfast
        BaseTestCase.dut.test_result.failfast = True

    @classmethod
    def tearDownClass(cls):
        BaseTestCase.tearDownClass()
        # Restore original failfast setting
        BaseTestCase.dut.test_result.failfast = Test100_UBootInitialize.org_failfast

    def test_00_power_cycle(self):
        '''
        Power Cycle the DUT and synchronize to the U-Boot prompt
        '''
        logging.debug("power cycling DUT")

        self.dut.power_cycle()
        self.sync_uboot_prompt(timeout=120)
        text = self.dut.send("echo $ver")
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
        self.sync_uboot_prompt(300)
        # check version of ONIE changed
        text = self.dut.send("echo $ver")
        onie_version = self.dut.get_config('onie_version')
        self.assertIn(onie_version, text,
                      "Could not find ONIE version " + onie_version)

class Test300_UBootFeatures(UBootTestCase):

    BaseTestCase.prompt = "=>"

    def setUp(self):
        logging.debug("Common U-Boot Tests setUp()")
        self.seq = range(10)

    def test_20_shuffle(self):
        # make sure the shuffled sequence does not lose any elements
        logging.debug("test_shuffle() - " + self.dut.name)
        text = self.dut.send("echo $ver")
        logging.debug("echo $ver: " + text)
        onie_version = self.dut.get_config('onie_version')
        self.assertIn(onie_version, text,
                      "Could not find ONIE version " + onie_version)
        random.shuffle(self.seq)
        self.seq.sort()
        self.assertEqual(self.seq, range(10))

        # should raise an exception for an immutable sequence
        self.assertRaises(TypeError, random.shuffle, (1,2,3))

    def test_20_choice(self):
        logging.debug("test_choice()")
        element = random.choice(self.seq)
        self.assertTrue(element in self.seq)

    def test_20_sample(self):
        logging.debug("test_sample()")
        with self.assertRaises(ValueError):
            random.sample(self.seq, 20)
        for element in random.sample(self.seq, 5):
            self.assertTrue(element in self.seq)
