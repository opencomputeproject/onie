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
# Platform driver for the DELL S6000.
#
############################################################
import subprocess
from onl.platform.base import *
from onl.vendor.dell import *

class OpenNetworkPlatformImplementation(OpenNetworkPlatformDELL):

    def model(self):
        return "S6000-ON"

    def platform(self):
        return "x86-64-dell-s6000-s1220-r0"

    def _plat_info_dict(self):
        return {
            platinfo.LAG_COMPONENT_MAX : 24,
            platinfo.PORT_COUNT : 32,
            platinfo.ENHANCED_HASHING : True,
            platinfo.SYMMETRIC_HASHING : True,
            }

    def sys_init(self):
        pass

    def sys_oid_platform(self):
        return ".6000.1"

if __name__ == "__main__":
    print OpenNetworkPlatformImplementation()


