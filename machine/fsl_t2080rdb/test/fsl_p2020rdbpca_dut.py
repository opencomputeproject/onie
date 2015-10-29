# FSL T2080RDB DUT Class
#
# Defines a DUT object for the FSL T2080RDB Board
#
# Shengzhou Liu <Shengzhou.Liu@freescale.com>
#
# SPDX-License-Identifier:     GPL-2.0

'''
FSL T2080RDB DUT Class
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
    import argparse
    import logging
    from dut import DUT
except ImportError, e:
    raise ImportError (str(e) + "- required module not found")

class fsl_t2080rdb_dut(DUT):

    def __init__(self, name, args, config, test_result):
        logging.debug("FSL T2080RDB DUT constructor")
        DUT.__init__(self, name, args, config, test_result)
