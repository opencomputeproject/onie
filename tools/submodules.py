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
# Submodule management. 
#
############################################################
import os
import sys
import subprocess
import shutil

# The first argument is the set of required modules
required_submodules = sys.argv[1].split(':')

# The second argument is the set of local modules
local_submodules = sys.argv[2].split(':')

# The third argument is the switchlight root
switchlight_root = sys.argv[3]


def submodule_update(module, depth=None):

    if depth and module != 'loader':
        print "shallow clone depth=%d" % int(depth)
        # Shallow clone first
        url = subprocess.check_output(['git', 'config', '-f', '.gitmodules', '--get', 
                                       'submodule.submodules/%s.url' % module])
        url = url.rstrip('\n')
        args = [ 'git', 'clone', '--depth', depth, url, 'submodules/%s' % module ]
        if subprocess.check_call(args) != 0:
            print "git error cloning module '%s'" % module
            sys.exit(1)

    # full or partial update
    args = [ 'git', 'submodule', 'update', '--init' ]
    if module == 'loader':
        args.append("--recursive")
    args.append('submodules/%s' % module)
    if subprocess.check_call(args) != 0:
        print "git error updating module '%s'. See the log in %s/submodules/%s.update.log" % (module, switchlight_root, module)
        sys.exit(1)



# 
# Get the current submodule status
#
os.chdir(switchlight_root)

#
# We only operate on the required modules that are also
# defined as local. Any other custom module paths
# are just assumed to be up to the user to manage and instantiate. 
#
git_submodule_status = {}
try:
    for entry in subprocess.check_output(['git', 'submodule', 'status']).split("\n"):
        data = entry.split()
        if len(data) >= 2:
            git_submodule_status[data[1].replace("submodules/", "")] = data[0]
except Exception as e:
    print repr(e)
    raise


if '__all__' in required_submodules:
    required_submodules = git_submodule_status.keys()
if '__all__' in local_submodules:
    local_submodules = required_submodules

for module in required_submodules:
    if module in local_submodules:
        status = git_submodule_status[module]
        if status[0] == '-':
            # This submodule has not yet been updated
            if os.path.exists("submodules/%s/modules" % module) or os.path.exists("submodules/%s/Modules" % module):
                # Shudder. The makefiles touched the module manifest as a convenience. That change should be temporary, and so should this one:
                shutil.rmtree("submodules/%s" % module)

            submodule_update(module, os.getenv("SUBMODULE_DEPTH"))





