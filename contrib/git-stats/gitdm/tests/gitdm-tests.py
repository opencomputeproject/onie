#!/usr/bin/python
#

#
# This code is part of the LWN git data miner.
#
# Copyright 2009 Martin Nordholts <martinn@src.gnome.org>
#
# This file may be distributed under the terms of the GNU General
# Public License, version 2.

import unittest, subprocess, os

class GitdmTests(unittest.TestCase):

    ##
    # Setup test fixture.
    #
    def setUp(self):
        self.srcdir = os.getcwd ()
        self.git_dir = os.path.join (self.srcdir, "tests/testrepo")
        if not os.path.exists (self.git_dir):
            self.fail ("'" + self.git_dir + "' didn't exist, you probably "+
                       "didn't run the test with the source root as the working directory.")


    ##
    # Makes sure that the statistics collected for the test repository
    # is the expected statistics. Note that the test must be run with
    # the working directory as the source root and with git in the
    # PATH.
    #
    def testResultOutputRegressionTest(self):

        # Build paths
        actual_results_path = os.path.join (self.srcdir, "tests/actual-results.txt")
        expected_results_path = os.path.join (self.srcdir, "tests/expected-results.txt")

        # Run actual test
        self.runOutputFileRegressionTest (expected_results_path,
                                          actual_results_path,
                                          ["-o", actual_results_path])


    ##
    # Does a regression test on the datelc (data line count) file
    #
    def testDateLineCountOutputRegressionTest(self):

        # Build paths
        actual_datelc_path = os.path.join (self.srcdir, "datelc")
        expected_datelc_path = os.path.join (self.srcdir, "tests/expected-datelc")

        # Run actual test
        self.runOutputFileRegressionTest (expected_datelc_path,
                                          actual_datelc_path,
                                          ["-D"])


    ##
    # Run a test, passing path to file with expected output, path to
    # file which will countain the actual output, and arguments to
    # pass to gitdm. We both make sure the file where the result will
    # be put when gitdm is run does not exist beforehand, and we clean
    # up after we are done.
    # 
    def runOutputFileRegressionTest(self, expected_output_path, actual_output_path, arguments):

        # Make sure we can safely run the test
        self.ensureFileDoesNotExist (actual_output_path)

        try:
            # Collect statistics
            self.runGitdm (arguments)

            # Make sure we got the result we expected
            self.assertFilesEqual (expected_output_path, actual_output_path)

        finally:
            # Remove any file we created, also if test fails
            self.purgeFile (actual_output_path)


    ##
    # If passed file exists, delete it.
    #
    def purgeFile(self, filename):
        if os.path.exists (filename):
            os.remove (filename)


    ##
    # Make sure the file does not exist so we don't risk overwriting
    # an important file.
    #
    def ensureFileDoesNotExist(self, filename):
        if os.path.exists (filename):
            self.fail ("The file '" + filename + "' exists, failing "
                       "test to avoid overwriting file.")


    ##
    # Run gitdm on the test repository with the passed arguments.
    #
    def runGitdm(self, arguments):
        git_log_process = subprocess.Popen (["git", "--git-dir", self.git_dir, "log", "-p", "-M"],
                                            stdout=subprocess.PIPE)
        gitdm_process = subprocess.Popen (["./gitdm"] + arguments,
                                          stdin=git_log_process.stdout)
        gitdm_process.communicate ()


    ##
    # Makes sure the files have the same content.
    #
    def assertFilesEqual(self, file1, file2):
        f = open (file1, 'r')
        file1_contents = f.read ()
        f.close ()
        f = open (file2, 'r')
        file2_contents = f.read ()
        f.close ()
        self.assertEqual (file1_contents, file2_contents,
                          "The files '" + file1 + "' and '" +
                          file2 + "' were not equal!")


if __name__ == '__main__':
    unittest.main ()
