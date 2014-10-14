#
# Base Test case class
#

#  Copyright (C) 2013 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

import unittest
import logging
from dut import *
import pexpect

# The unittest framework runs tests in lexicographical order, first by
# the class name and then by test name within a class.  To control the
# test sequence we adopt a class and test naming convention:
#
#   class names:  Test[XYZ]_<Class>, where [XYZ] is a 3 digit number.
#   test  names:  test_[XY]_<Test>, where [XY] is a 2 digit number.
#
# Lower numbered classes and tests are run first.
#
# Example: All the tests in class Test100_MeFirst() will run before
# the tests in class Test500_MeSecond().
#
# Example: Within a class the test test_10_early_test() will run
# before the test test_30_later_test().
#
# If you do not care about test ordering within a class the 2 digit
# number is optional.

class BaseTestCase(unittest.TestCase):

    '''
    Base class for all test cases
    '''

    # Make sure all tests have access to the DUT
    dut = gdut_get()
    prompt = None

    @classmethod
    def setUpClass(cls):
        logging.debug("Opening DUT connection")
        BaseTestCase.dut.open(re.compile(BaseTestCase.prompt))

    @classmethod
    def tearDownClass(cls):
        logging.debug("Closing DUT connection")
        BaseTestCase.dut.close()
