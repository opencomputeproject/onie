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

import pprint

############################################################
#
# System-specific information keys.
# These represent information about a particular box.
#
############################################################

class sysinfo(object):
    MAGIC='_magic'
    CRC16='_crc16'
    PRODUCT_NAME='Product Name'
    PART_NUMBER='Part Number'
    SERIAL_NUMBER='Serial Number'
    MAC_ADDRESS='MAC Address'
    MANUFACTURE_DATE='Manufactured Date'
    CARD_TYPE='Card Type'
    HARDWARE_VERSION='Hardware Version'
    LABEL_VERSION='Label Version'
    MODEL_NAME='Model'
    SOFTWARE_VERSION='Software Version'
    DEVICE_VERSION='Device Version'

############################################################
#
# Platform-specific information keys.
# These represent information about a particular type of box.
#
############################################################
class platinfo(object):
    LAG_COMPONENT_MAX='Maximum number of component ports in a LAG'
    PORT_COUNT='Total Physical Ports'


############################################################
#
# Platform OIDs
#
############################################################
class oids(object):
    TEMP_SENSORS='temp_sensors'
    CHASSIS_FAN_SENSORS='chassis_fan_sensors'
    POWER_FAN_SENSORS='power_fan_sensors'
    POWER_SENSORS='power_sensors'
    CPU_LOAD='CPU_load'
    MEM_TOTAL_FREE='mem_total_free'
    INTERFACES='interfaces'
    FLOW_TABLE_L2_UTILIZATION='flow_table_l2_util'
    FLOW_TABLE_TCAM_FM_UTILIZATION='flow_table_tcam_fm_util'
    LINK_TABLE_UTILIZATION='link_table_util'



############################################################
#
# Symbolic port base
#
############################################################
class basenames(object):
    PHY="ethernet"
    LAG="port-channel"

############################################################
#
# Open Network Platform Base
# Baseclass for all OpenNetworkPlatform objects.
#
############################################################

class OpenNetworkPlatformBase(object):

    def __init__(self):
        self.sys_info = None

    def platform_basedir(self):
        return "/lib/platform-config/%s" % self.platform()

    def baseconfig(self):
        return True


    def manufacturer(self):
        raise Exception("Manufacturer is not set.")

    def model(self):
        raise Exception("Model is not set.")

    def platform(self):
        raise Exception("Platform is not set.")

    def description(self):
        return "%s %s (%s)" % (self.manufacturer(), self.model(),
                               self.platform())

    def serialnumber(self):
        return self.sys_info_get(sysinfo.SERIAL_NUMBER)

    def hw_description(self):
        return "%s (%s)" % (self.sys_info_get(sysinfo.PRODUCT_NAME),
                            self.sys_info_get(sysinfo.PART_NUMBER))

    def portcount(self):
        return self.plat_info_get(platinfo.PORT_COUNT)


    def __getattr__(self, key):
        class __InfoContainer(object):
            def __init__(self, d, klass):
                # Set all known info keys to None
                for (m,n) in klass.__dict__.iteritems():
                    if m == m.upper():
                        setattr(self, m, None)
                if d:
                    for (k,v) in d.iteritems():
                        for (m,n) in klass.__dict__.iteritems():
                            if n == k:
                                setattr(self, m, v);
                                break
        if key == "platinfo":
            return __InfoContainer(self.plat_info_get(), platinfo)
        if key == "sysinfo":
            return __InfoContainer(self.sys_info_get(), sysinfo)
        return None

    def _sys_info_dict(self):
        raise Exception("Must be provided by the deriving class.")

    def _plat_info_dict(self):
        raise Exception("Must be provided by the deriving class.")

    def _plat_oid_table(self):
        raise Exception("Must be provided by the deriving class.")

    def oid_table(self):
        # Fixme -- all of this
        common = {
            oids.CPU_LOAD : {
                'cpuload'        : '.1.3.6.1.4.1.2021.10.1.5.1',
                },

            oids.MEM_TOTAL_FREE : {
                'memtotalfree'   : '.1.3.6.1.4.1.2021.4.11.0',
                },

            oids.INTERFACES: {
                'interfaces'     : '.1.3.6.1.2.1.2',
                },

            oids.FLOW_TABLE_L2_UTILIZATION : {
                'ft_l2_utilization'    : '.1.3.6.1.4.1.37538.2.1.1.3',
                },

            oids.FLOW_TABLE_TCAM_FM_UTILIZATION : {
                'ft_tcam_fm_utilization'    : '.1.3.6.1.4.1.37538.2.1.2.3',
                },

            oids.LINK_TABLE_UTILIZATION : {
                'ft_link_utilization'    : '.1.3.6.1.4.1.37538.2.2.1.3',
                },

            }
        common.update(self._plat_oid_table())
        return common


    def sys_info_get(self, field=None):
        """Provide the value of a sysinfo key or the entire dict"""
        if self.sys_info is None:
            self.sys_info = self._sys_info_dict()

        if self.sys_info:
            if field:
                return self.sys_info.get(field)
            else:
                return self.sys_info
        else:
            return {}

    def plat_info_get(self, field=None):
        """Provide the value of a platinfo key or the entire dict"""
        pi = self._plat_info_dict()
        if field and pi:
            return pi.get(field)
        else:
            return pi

    def sys_init(self):
        """Optional system initialization."""
        return True

    def __infostr(self, d, indent="    "):
        """String representation of a platform information dict."""
        # A little prettier than pprint.pformat(), especially
        # if we are displaying the infromation to the user.
        # We also want to hide keys that start with an underscore.
        return "\n".join( sorted("%s%s: %s" % (indent,k,v) for k,v in d.iteritems() if not k.startswith('_')))

    def __str__(self):
        return """Manufacturer: %s
Model: %s
Platform: %s
Description: %s
System Information:
%s

Platform Information:
%s

""" % (self.manufacturer(),
       self.model(),
       self.platform(),
       self.description(),
       self.__infostr(self.sys_info_get()),
       self.__infostr(self.plat_info_get()),
       )




