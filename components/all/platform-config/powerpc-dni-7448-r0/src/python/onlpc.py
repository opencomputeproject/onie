#!/usr/bin/python
############################################################
#
# Platform Driver for powerpc-dni-7448-r0
#
############################################################
import os
import struct
import time
import subprocess
from onl.platform.base import *
from onl.vendor.dni import *

class OpenNetworkPlatformImplementation(OpenNetworkPlatformDNI):

    def model(self):
        return "7448"

    def platform(self):
        return 'powerpc-dni-7448-r0'

    def _plat_info_dict(self):
        return {
            platinfo.LAG_COMPONENT_MAX : 16,
            platinfo.PORT_COUNT : 52
            }

    def oid_table(self):
        raise Exception()


if __name__ == "__main__":
    print OpenNetworkPlatformImplementation()

