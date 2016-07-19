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
# This file provides the container for the
# platform-specific class provided by the files in the
# platform-config packages.
#
############################################################

# Determine the platform
with open("/etc/onl_platform", 'r') as f:
    platform=f.read().strip()

# Append platform-specific paths for import
import sys
platform_basedir="/lib/platform-config/%s" % platform
sys.path.append("%s/python" % platform_basedir)

# Import the platform-specific class
from onlpc import OpenNetworkPlatformImplementation

# Make it available to the importer as OpenNetworkPlatform
OpenNetworkPlatform=OpenNetworkPlatformImplementation

if __name__ == "__main__":
    print OpenNetworkPlatform()





