#!/usr/bin/python
############################################################
# <bsn.cl fy=2013 v=none>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#
#
#
# </bsn.cl>
############################################################
#
# Platform driver for the Accton AS6712-32X
#
############################################################
import subprocess
from onl.platform.base import *
from onl.vendor.accton import *

class OpenNetworkPlatformImplementation(OpenNetworkPlatformAccton):

    def model(self):
        return "AS6712-32X"

    def platform(self):
        return "x86-64-accton-as6712-32x-r0"

    def _plat_info_dict(self):
        return {
            platinfo.LAG_COMPONENT_MAX : 24,
            platinfo.PORT_COUNT : 54,
            platinfo.ENHANCED_HASHING : True,
            platinfo.SYMMETRIC_HASHING : True,
            }

    def sys_init(self):
        pass

    def sys_oid_platform(self):
        return ".6712.32"

if __name__ == "__main__":
    print OpenNetworkPlatformImplementation()

