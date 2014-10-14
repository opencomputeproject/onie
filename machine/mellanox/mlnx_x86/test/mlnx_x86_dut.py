#
# mlnx_x86 DUT Class
#
# Defines a DUT object for the mlnx_x86 Board
#

'''
mlnx_x86 DUT Class
'''

DUT_TYPE = "mlnx_x86"

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
    from dut import DUT
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

class mlnx_x86_dut(DUT):

    def __init__(self, name, args, config, test_result):
        logging.debug(DUT_TYPE + " DUT constructor")
        DUT.__init__(self, name, args, config, test_result)
