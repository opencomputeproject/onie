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
# Generate a new Open Network Linux component directory.
#
############################################################

import time
import sys
import os
from debgen import DebianGenerator

class ComponentGenerator(DebianGenerator):
    def __init__(self, name, package, arch, summary, desc):
        DebianGenerator.__init__(self, package, arch, summary, desc);
        self.name = name

    def _required_submodules(self):
        return None
    def _required_packages(self):
        return None

    def _makefile(self):
        self.required_submodules = "# ONL_REQUIRED_SUBMODULES := "
        self.required_packages = "# ONL_REQUIRED_PACKAGES := "
        if self._required_submodules():
            self.required_submodules = self.required_submodules[2:] + self._required_submodules()
        if self._required_packages():
            self.required_packages = self.required_packages[2:] + self._required_packages()

        """Return the contents of the top-level makefile for the component."""
        return """ifndef ONL
$(error $$ONL is undefined.)
endif

%(required_submodules)s
%(required_packages)s

include $(ONL)/make/component.mk
""" % (self.__dict__)

    def _makefile_dot_comp_all_rules(self):
        return "\t@echo Nothing to be done."

    def _makefile_dot_comp(self):
        """Return the contents of the top-level Makefile.comp"""
        self.comp_all_rules = self._makefile_dot_comp_all_rules()
        return """# -*- Makefile -*-
############################################################
#
# @make-cl-start
# @make-cl-end
#
############################################################
ifndef ONL
$(error $$ONL is not set)
endif

include $(ONL)/make/config.mk

all:
%(comp_all_rules)s

.PHONY: deb
deb:
\t$(MAKE) -C deb
""" % (self.__dict__)

    def _deb_makefile(self):
        return """ARCH=%(arch)s
PACKAGE_NAMES=%(package)s
include %(relpath)s/../make/debuild.mk
""" % (self.__dict__)

    def __generate_file(self, path, name, contents):
        with open("%s/%s" % (path, name), "w") as f:
            f.write(contents)

    def generate(self, path):
        # Relative path to the ONL root from the target package
        # directory
        location="%s/%s" % (path, self.name)
        os.makedirs(location)
        self.relpath = os.path.relpath(os.getenv('ONL'),location)
        self.__generate_file(location, "Makefile", self._makefile())
        self.__generate_file(location, "Makefile.comp", self._makefile_dot_comp())
        location += "/deb"
        os.makedirs(location)
        self.__generate_file(location, "Makefile", self._deb_makefile())
        location += "/debuild"
        os.makedirs(location)
        DebianGenerator.generate(self, location)


if __name__ == "__main__":
    import argparse

    ap=argparse.ArgumentParser(description="Create a new component directory.")
    ap.add_argument("name", help="The name of the component.")
    ap.add_argument("arch", help="Package architecture.")
    ap.add_argument("summary", help="The package summary.")
    ap.add_argument("--package", help="The name of the package. Defaults to the name.")
    ap.add_argument("--desc", help="The package description.")

    ops = ap.parse_args()

    if ops.package is None:
        ops.package = ops.name
    if ops.desc is None:
        ops.desc = ops.summary

    cg = ComponentGenerator(ops.name, ops.package, ops.arch, ops.summary,
                            ops.desc)

    cg.generate(".")
