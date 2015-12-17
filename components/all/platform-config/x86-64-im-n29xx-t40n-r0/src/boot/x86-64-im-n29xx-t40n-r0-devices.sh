############################################################
#
#    Copyright 2014 Big Switch Networks, Inc.
#    Copyright 2015 Interface Masters Technologies, Inc.
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
############################################################
# x86-64-im-n29xx-t40n-r0
############################################################

function lpc_init {
   ID=`setpci -s 00:1f.0 VENDOR_ID.L 2>/dev/null`
   if [ "$ID" = "1e558086" ]; then
      setpci -s 00:1f.0 VENDOR_ID+0x88.L=0x00fc0701
   else
      ID=`setpci -s 00:14.3 VENDOR_ID.L 2>/dev/null`
      if [ "$ID" = "439d1002" ]; then
         setpci -s 00:14.3 VENDOR_ID+0x4a.B=0x0c
      fi
   fi
}

lpc_init

exit 0
