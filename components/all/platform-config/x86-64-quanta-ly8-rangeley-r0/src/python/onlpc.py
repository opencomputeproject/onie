#!/usr/bin/python
############################################################
# <bsn.cl fy=2013 v=none>
#
#        Copyright 2013, 2014 BigSwitch Networks, Inc.
#        Copyright 2015 Quanta Computer Inc.
#
#
#
# </bsn.cl>
############################################################
#
# Platform driver for the Quanta LY8.
#
############################################################
import subprocess
from onl.platform.base import *
from onl.vendor.quanta import *
import os
import shutil

class OpenNetworkPlatformImplementation(OpenNetworkPlatformQuanta):

    def _eeprom_file(self):
        return "/sys/devices/pci0000:00/0000:00:1f.3/i2c-0/i2c-27/27-0054/eeprom"

    def model(self):
        return "LY8-Rangeley"

    def platform(self):
        return "x86-64-quanta-ly8-rangeley-r0"

    def _plat_info_dict(self):
        return {
            platinfo.PORT_COUNT : 54,
            }

    def sys_init(self):
        pass

    def sys_oid_platform(self):
        return ".8.1"

    def baseconfig(self):
        try:
            files = os.listdir("%s/etc/init.d" % self.platform_basedir())
            for file in files:
                src = "%s/etc/init.d/%s" % (self.platform_basedir(), file)
                dst = "/etc/init.d/%s" % file
                os.system("cp -f %s %s" % (src, dst))
                os.system("/usr/sbin/update-rc.d %s defaults" % file)
        except:
            pass

        # make ds1339 as default rtc
        os.system("ln -snf /dev/rtc1 /dev/rtc")
        os.system("hwclock --hctosys")

        # set system led to green
        os.system("%s/sbin/systemled green" % self.platform_basedir())

        return True

if __name__ == "__main__":
    print OpenNetworkPlatformImplementation()


