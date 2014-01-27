#!/usr/bin/python
############################################################
# <bsn.cl fy=2013 v=onl>
# 
#        Copyright 2013, 2014 BigSwitch Networks, Inc.        
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
############################################################
#
# Platform Driver for the Quanta LB9A
#
############################################################
import os
import struct
import time
import subprocess
from onl.platform.base import *
from onl.vendor.quanta import *

class OpenNetworkPlatformImplementation(OpenNetworkPlatformQuanta):

    def _eeprom_file(self):
        return "/sys/devices/e0000000.soc8541/e0003000.i2c/i2c-0/0-0054/eeprom"

    def model(self):
        return "LB9A"

    def platform(self):
        return "powerpc-quanta-lb9a-r0"

    def _plat_info_dict(self):
        return {
            platinfo.LAG_COMPONENT_MAX : 8,
            platinfo.PORT_COUNT : 52
            }

    def _plat_oid_table(self):
        return {
            oids.TEMP_SENSORS : {
                'ctemp1' : '.1.3.6.1.4.1.2021.13.16.2.1.3.1',
                'ctemp2' : '.1.3.6.1.4.1.2021.13.16.2.1.3.5',
                'ctemp3' : '.1.3.6.1.4.1.2021.13.16.2.1.3.9',
                'ctemp4' : '.1.3.6.1.4.1.2021.13.16.2.1.3.13',
                'ctemp5' : '.1.3.6.1.4.1.2021.13.16.2.1.3.17',
                'pwr-temp1' : '.1.3.6.1.4.1.2021.13.16.2.1.3.41',
                'pwr-temp2' : '.1.3.6.1.4.1.2021.13.16.2.1.3.44',
                'pwr-temp3' : '.1.3.6.1.4.1.2021.13.16.2.1.3.46',
                },
            oids.CHASSIS_FAN_SENSORS : {
                'cfan1' : '.1.3.6.1.4.1.2021.13.16.3.1.3.1',
                'cfan2' : '.1.3.6.1.4.1.2021.13.16.3.1.3.5',
                'cfan3' : '.1.3.6.1.4.1.2021.13.16.3.1.3.9',
                'cfan4' : '.1.3.6.1.4.1.2021.13.16.3.1.3.13',
                },
            oids.POWER_FAN_SENSORS : {
                'pwr-fan' : '.1.3.6.1.4.1.2021.13.16.3.1.3.33',
                },
            oids.POWER_SENSORS : {
                'power' : '.1.3.6.1.4.1.2021.13.16.5.1.3.8'
                },
            }

    def sys_init(self):
        pass


if __name__ == "__main__":
    print OpenNetworkPlatformImplementation()

