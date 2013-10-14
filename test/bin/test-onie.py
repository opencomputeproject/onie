#!/usr/bin/python

'''
ONIE Test Harness
'''

# Perhaps read a style guide
# http://google-styleguide.googlecode.com/svn/trunk/pyguide.html

#-------------------------------------------------------------------------------
#
# Imports
#

try:
    import sys
    import os
    import re
    import io
    import argparse
    import logging
    import unittest
    import pexpect
    import ConfigParser
    import imp
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

#-------------------------------------------------------------------------------
#
# Functions
#

def load_config(dut_name, config_file):
    '''
    Load site configuration file and return DUT configuration.
    '''
    config = ConfigParser.ConfigParser()
    config.readfp(config_file)

    # Check if the config file is configured properly
    if config.has_option('DEFAULT', 'configure_me'):
        sys.stderr.write("ERROR: Configuration file is not setup correctly: " +
                         config_file.name + "\n")
        sys.stderr.write('After you have configured the file remove the ' +
                         '"configure_me" option\n')
        sys.exit(1)

    # Check that config file has a section for this DUT name
    if not config.has_section(dut_name):
        sys.stderr.write("ERROR: DUT section name [%s] not found in %s.\n" %
                         (dut_name, config_file.name))
        sys.exit(1)

    # Check that DUT section has required options
    for o in ('dut_type', 'console_proto', 'power_proto'):
        if not config.has_option(dut_name, o):
            sys.stderr.write("ERROR: DUT [%s]: `%s' option not found in %s.\n" %
                             (dut_name, o, config_file.name))
            sys.exit(1)

    logging.debug("dut_config: %s" % (str(config.items(dut_name))))
    return config


def dut_create(args, test_result):
    '''
    Create global DUT object of specified type.
    '''
    dut_config = load_config(args.dut_name, args.site_config)

    #
    # load the DUT class file and instantiate the DUT object
    #
    dut_type = dut_config.get(args.dut_name, 'dut_type')
    try:
        mod_path = os.path.join(args.machine_dir, "test",
                                dut_type + "_dut.py")
        mod = imp.load_source('DUT', mod_path)
    except Exception, e:
        sys.stderr.write("ERROR: Problems loading DUT class module: " + mod_path + "\n")
        sys.stderr.write("ERROR: %s\n" % str(e))
        sys.exit(1)

    class_name = dut_type + "_dut"
    dut_class = getattr(mod, class_name)

    return dut_class(args.dut_name, args, dut_config, test_result)

def test_suite_create(machine_dir, test_name):
    '''
    Create a test suite based on the command line options
    '''
    if test_name is not None:
        suite = unittest.defaultTestLoader.loadTestsFromName(test_name)
    else:
        suite = unittest.TestSuite()

        # Load platform dependent tests
        platform_test_dir = os.path.join(machine_dir, 'test')
        platform_tests = unittest.defaultTestLoader.discover(platform_test_dir,
                                                             top_level_dir=platform_test_dir)
        logging.debug("platform_tests: %s" % (str(platform_tests)))
        suite.addTests(platform_tests)

        # Load core ONIE tests
        pathname = os.path.join(os.path.dirname(sys.argv[0]), '..', 'tests')
        core_test_dir = os.path.realpath(pathname)
        core_tests = unittest.defaultTestLoader.discover(core_test_dir,
                                                         top_level_dir=core_test_dir)
        logging.debug("core_tests: %s" % (str(core_tests)))
        suite.addTests(core_tests)

    return suite

def log_level(name):
    '''
    An argparse helper for the --log-level argument
    '''
    try:
        level = getattr(logging, name)
    except AttributeError:
        print "ERROR: No such log level: %s" % name
        sys.exit(1)

    return level

# Create our own TestRunner so we can control the life cycle of the
# TestResult object.  Later we make the TestResult object available to
# the tests so that they can stop the TestRunner if necessary.
class ONIETestRunner(unittest.TextTestRunner):
    def __init__(self, stream=sys.stderr, descriptions=True, verbosity=1,
                 failfast=False, buffer=False, resultclass=None):
        unittest.TextTestRunner.__init__(self, stream, descriptions, verbosity,
                                         failfast, buffer, resultclass)
        self.test_result = self.resultclass(self.stream, self.descriptions,
                                            self.verbosity)

    def _makeResult(self):
        return self.test_result

#-------------------------------------------------------------------------------
#
# Main
#
def main():

    parser = argparse.ArgumentParser(
        description='Test ONIE features and functionality')
    parser.add_argument('-o', '--log-file',
                        required=False,
                        default='-',
                        type=argparse.FileType('w'),
                        action='store',
                        help='Output test log file')
    parser.add_argument('-c', '--console-log',
                        required=False,
                        default='-',
                        type=argparse.FileType('w'),
                        action='store',
                        help='Output DUT console log file')
    parser.add_argument('-l', '--log-level',
                        required=False,
                        default="WARNING",
                        type=log_level,
                        action='store',
                        help='Log level: DEBUG, INFO, WARNING, ERROR, CRITICAL')
    parser.add_argument('-m', '--machine-dir',
                        required=True,
                        action='store',
                        help='Machine directory')
    parser.add_argument('-s', '--site-config',
                        required=True,
                        type=argparse.FileType('r'),
                        action='store',
                        help='Site local configuration file')
    parser.add_argument('-d', '--dut-name',
                        required=True,
                        action='store',
                        help='DUT name to test')
    parser.add_argument('-t', '--test-name',
                        required=False,
                        default=None,
                        action='store',
                        help='Test to run in the form used by \
                        unittest.TestLoader.loadTestsFromName(). \
                        Default runs all tests')
    args = parser.parse_args()

    # Initialize logging
    log_format = "%(levelname)s"
    log_format += ":" + args.dut_name
    log_format += ":%(module)s.%(funcName)s:%(message)s"
    logging.basicConfig(stream = args.log_file, level = args.log_level,
                        format = log_format)

    if args.log_file.name != "<stdout>":
        print "Using log file: %s" % args.log_file.name

    # Add some directories to the module search path
    test_root = os.path.realpath(os.path.join(os.path.dirname(sys.argv[0]), '..'))
    sys.path[:0] = [os.path.join(args.machine_dir, 'test')]
    sys.path[:0] = [os.path.join(test_root, d) for d in ('lib', 'tests')]

    # Handle ctrl-C
    unittest.installHandler()

    runner = ONIETestRunner(stream=args.log_file,verbosity=2)

    # Create the DUT singleton
    dut = dut_create(args, runner.test_result)

    test_suite = test_suite_create(args.machine_dir, args.test_name)

    result = runner.run(test_suite)

    if result.wasSuccessful():
        print "All tests successful"
        return 0
    else:
        print "There were failures:"
        return 1

#--------------------
#
# execution check
#
if __name__ == '__main__':
    exit(main())
