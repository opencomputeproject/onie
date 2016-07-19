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
# OpenNetworkPlatform support for Quanta platforms.
#
############################################################
from onl.platform.base import OpenNetworkPlatformBase, sysinfo
import struct
import time
import binascii
import sys
import string

class OpenNetworkPlatformQuanta(OpenNetworkPlatformBase):

    def manufacturer(self):
        return "Quanta"

    def onie_eeprom(self):
        ONIE_EEPROM_SIZE = 256
        ONIE_HEADER_LENGTH = 11
        ONIE_CRC32_LENGTH = 4
        info = {}

        f = file(self._eeprom_file())

        arr = []

        try:
            if f.read(8) != "TlvInfo\0":
                # Magic number does not match.
                return None
            info["Magic"] = "TlvInfo"

        except IOError:
            return None

        f = file(self._eeprom_file())
        for i in range(0, ONIE_EEPROM_SIZE, 1):
            b = f.read(1)
            if not b:
                return None
            arr.append(b)

        total_length = ord(arr[10])

        start = 0
        end = ONIE_HEADER_LENGTH + total_length - ONIE_CRC32_LENGTH
        data = ''.join(arr[start:end])
        crc32 = binascii.crc32(data) & 0xffffffff
        crc32_str = hex(crc32)

        start = ONIE_HEADER_LENGTH + total_length - ONIE_CRC32_LENGTH
        end = ONIE_HEADER_LENGTH + total_length
        read_crc32 = arr[start:end]
        s = ''.join(read_crc32)
        read_crc32_str = '0x%08x' % struct.unpack('>I', s)

        if crc32_str != read_crc32_str:
    #        print 'crc_str: %s, read_crc32_str: %s' % (crc32_str, read_crc32_str)
            sys.stderr.write("ONIE eeprom crc32 does not match ...")
            sys.stderr.flush()
            return None

        info["CRC32"] = read_crc32_str

        #
        # EEPROM data mappings.
        # codebyte : (field, unpack-size)
        #
        fields = {
            0x21: (sysinfo.PRODUCT_NAME, None),
            0x22: (sysinfo.PART_NUMBER, None),
            0x23: (sysinfo.SERIAL_NUMBER, None),
            0x24: (sysinfo.MAC_ADDRESS, "MAC"),
            0x25: ("Manufacture Date", None),
            0x26: ("Device Version", "!B"),
            0x27: ("Label Revision", None),
            0x28: ("Platform Name", None),
            0x29: ("ONIE Version", None),
            0x2a: ("Number of MACs", "!H"),
            0x2b: ("Manufacturer", None),
            0x2c: ("Country Code", None),
            0x2d: ("Vendor", None),
            0x2e: ("Diag Version", "SOFTWARE_VERSION"),
            0xfd: ("Model Name", None),
            }

        i = ONIE_HEADER_LENGTH
        while i < ONIE_HEADER_LENGTH + total_length:
            t = ord(arr[i])
            i += 1
            l = ord(arr[i])
            i += 1
            v = arr[i:i+l]
            i += l

            if t in fields:
                try:
                    tn, c = fields[t]
    #                print "t: %x, l: %d, tn: %s, v: %s" % (t, l, tn, v)
                    if c == "MAC":
                        v = "%02x:%02x:%02x:%02x:%02x:%02x" % struct.unpack("!6B", string.join(v, ''))
                    if c == "SOFTWARE_VERSION":
                        v = "%d.%d.%d.%d (0x%02x%02x)" % (((ord(v[0])&0xf0)>>4),(ord(v[0])&0xf),((ord(v[1])&0xf0)>>4),(ord(v[1])&0xf),ord(v[2]),ord(v[3]))
                    elif c:
                        v = struct.unpack(c, string.join(v, ''))[0]
                    else:
                        v = string.join(v, '')

                except struct.error:
                    pass

                info[tn] = v

        return info

    def _sys_info_dict(self):
        info = self.onie_eeprom()
        if (info != None) and (info != {}):
            return info

        info = {}

        # _eeprom_file() is provided by the derived platform class
        f = file(self._eeprom_file())

        try:
            if f.read(3) != "\xff\x01\xe0":
                # Magic number does not match.
                return None
        except IOError:
            return None

        f = file(self._eeprom_file())

        #
        # EEPROM data mappings.
        # codebyte : (field, unpack-size)
        #
        fields = {
            0xff: (sysinfo.MAGIC, "!B"),
            0x01: (sysinfo.PRODUCT_NAME, None),
            0x02: (sysinfo.PART_NUMBER, None),
            0x03: (sysinfo.SERIAL_NUMBER, None),
            0x04: (sysinfo.MAC_ADDRESS, "MAC"),
            0x05: (sysinfo.MANUFACTURE_DATE, "DATE"),
            0x06: (sysinfo.CARD_TYPE, "!L"),
            0x07: (sysinfo.HARDWARE_VERSION, "!L"),
            0x08: (sysinfo.LABEL_VERSION, None),
            0x09: (sysinfo.MODEL_NAME, None),
            0x0a: (sysinfo.SOFTWARE_VERSION, "!L"),
            0x00: (sysinfo.CRC16, "!H"),
            }

        while True:
            # Read type codebyte
            t = f.read(1)
            if not t:
                break
            t = ord(t)
            # Read length
            l = f.read(1)
            if not l:
                break
            l = ord(l)
            if l < 1:
                break
            # Read value
            v = f.read(l)
            if len(v) != l:
                break
            # Populate field by type
            if t in fields:
                try:
                    t, c = fields[t]
                    if c == "MAC":
                        v = "%02x:%02x:%02x:%02x:%02x:%02x" % struct.unpack("!6B", v)
                    if c == "DATE":
                        v = time.gmtime(time.mktime(struct.unpack("!HBB", v)
                                                    + (0, 0, 0, 0, 0, 0)))
                        v = time.strftime("%a, %d %b %Y %H:%M:%S +0000", v)
                    elif c:
                        v = struct.unpack(c, v)[0]
                except struct.error:
                    pass

                info[t] = v

        return info



