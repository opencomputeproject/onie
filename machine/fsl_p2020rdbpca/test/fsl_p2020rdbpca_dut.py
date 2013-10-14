#
# FSL P2020_RDB-PCA DUT Class
#
# Defines a DUT object for the FSL P2020_RDB-PCA Board
#

'''
FSL P2020_RDB-PCA DUT Class
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

class fsl_p2020rdbpca_dut(DUT):

    def __init__(self, name, args, config, test_result):
        logging.debug("FSL P2020_RDB-PCA DUT constructor")
        DUT.__init__(self, name, args, config, test_result)
