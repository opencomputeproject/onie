#!/usr/bin/python
############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 Big Switch Networks, Inc.       
# 
# Licensed under the Eclipse Public License, Version 1.0 (the
# "License"); you may not use this file except in compliance
# with the License. You may obtain a copy of the License at
# 
#        http://www.eclipse.org/legal/epl-v10.html
# 
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
# either express or implied. See the License for the specific
# language governing permissions and limitations under the
# License.
# 
# </bsn.cl>
############################################################
#
# Platform Driver for powerpc-accton-as5610-52x-r0
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
        return "AS5610-52X"

    def platform(self):
        return 'powerpc-accton-as5610-52x-r0'

    def _plat_info_dict(self):
        return {
            platinfo.LAG_COMPONENT_MAX : 16,
            platinfo.PORT_COUNT : 52,
            }

    def _plat_oid_table(self):
        raise Exception()


if __name__ == "__main__":
    print OpenNetworkPlatformImplementation()

