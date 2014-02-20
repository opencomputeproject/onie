#!/usr/bin/python
############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 BigSwitch Networks, Inc.        
# 
# 
# 
# </bsn.cl>
############################################################
#
# OpenNetworkPlatform support for Accton platforms.
#
############################################################
from onl.platform.base import OpenNetworkPlatformBase, sysinfo
import struct
import time

class OpenNetworkPlatformAccton(OpenNetworkPlatformBase):

    def manufacturer(self):
        return "Accton"

    def _sys_info_dict(self):
        return {
            sysinfo.PRODUCT_NAME : "AcctonNotImplemented",
            }

