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
#
# Generate a new Open Nework Linux vendor configuration 
# component.
#
############################################################

import time
import sys
import os
from compgen import ComponentGenerator

class VendorConfigGenerator(ComponentGenerator):
    def __init__(self, vendor):
        self.vendor = vendor
        summary="Vendor Configuration files for %s." % self.vendor
        ComponentGenerator.__init__(self, vendor, "vendor-config-" + self.vendor,
                                    "all", summary, summary)

    def _makefile_dot_comp_all_rules(self):
        return "\t@echo Run 'make deb'"

    def _required_packages(self):
        return "vendor-config-onl:all"

    def _rules(self):
        return """#!/usr/bin/make -f
VENDOR_NAME=%(vendor)s
include $(ONL)/make/vendor-config-rules.mk
""" % (self.__dict__)

    def __generate_file(self, path, name, contents):
        with open("%s/%s" % (path, name), "w") as f:
            f.write(contents)

    def _install(self):
        return "/usr/lib/python2.7/dist-packages/*"

    def generate(self, path):
        # Generate the entire component:
        ComponentGenerator.generate(self, path)
        self.path = "%s/%s" % (path, self.vendor)
        # the platform directory layout is this
        os.makedirs('%(path)s/src/python/%(vendor)s' % (self.__dict__))
        self.__generate_file("%(path)s/src/python/%(vendor)s" % (self.__dict__),
                             "__init__.py",
                             "# Vendor classes here")



if __name__ == '__main__':
    if len(sys.argv) != 2:
        print "usage: %s <vendor-name>" % sys.argv[0]
        sys.exit(1)

    vc = VendorConfigGenerator(sys.argv[1])
    vc.generate('.')



