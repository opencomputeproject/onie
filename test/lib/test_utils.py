#
# Collection of useful test utility methods
#

#  Copyright (C) 2013 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0

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
    import subprocess
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

#-------------------------------------------------------------------------------
#
# Functions
#

def exec_command(cmd):
    '''
    Helper routine for running external shell commands.
    '''
    retval = 0
    try:
        logging.debug("Executing: " + cmd)
        output = subprocess.check_output(cmd,
                                         shell=True,
                                         stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError, e:
        retval = e.returncode
        output = e.output
        logging.warning("Shell command failed: " + cmd)
        logging.warning("Failed command output: " + output)

    return (retval, output)
