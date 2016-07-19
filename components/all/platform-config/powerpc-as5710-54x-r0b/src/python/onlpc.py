#!/usr/bin/python
############################################################
#
# Platform Driver for powerpc-as5710-54x-r0b
#
############################################################
import os
import struct
import time
import subprocess
from onl.platform.base import *
from onl.vendor.accton import *

class OpenNetworkPlatformImplementation(OpenNetworkPlatformAccton):

    def model(self):
        return "AS5710-54X"

    def platform(self):
        return 'powerpc-as5710-54x-r0b'

    def _plat_info_dict(self):
        return {
            platinfo.LAG_COMPONENT_MAX : 16,
            platinfo.PORT_COUNT : 54
            }

    def _plat_oid_table(self):
        return None

    def get_environment(self):
        return "Not implemented."



if __name__ == "__main__":
    import sys

    p = OpenNetworkPlatformImplementation()
    if len(sys.argv) == 1 or sys.argv[1] == 'info':
        print p
    elif sys.argv[1] == 'env':
        print p.get_environment()


