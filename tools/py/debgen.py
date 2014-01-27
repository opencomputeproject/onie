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
# Generate a generic debian package directory.
#
# This class can be subclassed to insert package details.
#
############################################################
import time
import sys
import os
import subprocess

class DebianGenerator(object):
    def __init__(self, package, arch, summary, desc):
        self.packages = []
        self.package = package
        self.arch = arch
        self.summary = summary
        self.desc = desc
        self.copyright = 'Copyright 2013 Big Switch Networks';
        # The date string must be rfc-3339.
        self.date = subprocess.check_output(['date', '-R'])

    def add_package(self, package, summary, desc):
        """Add an additional package specification."""
        self.packages.append((package,summary,desc))

    def _gitignore(self):
        """Return the contents of the .gitignore file."""
        return "files\n"

    def _changelog(self):
        """Return the contents of the changelog file."""
        return """%(package)s (0.1.0bsn1~ubuntu1) UNRELEASED; urgency=low

  * Initial release.

 -- Support <support@bigswitch.com>  %(date)s

""" % (self.__dict__)

    def _compat(self):
        """Return the contents of the compat file."""
        return "9"

    def _copyright(self):
        """Return the contents of the copyright file."""
        return self.copyright

    def _control(self):
        """Return the contents of the control file."""
        return """Source: %(package)s
Section: misc
Priority: optional
Maintainer: Support <support@bigswitch.com>
Build-Depends: debhelper (>= 9)
Standards-Version: 3.8.4

Package: %(package)s
Architecture: %(arch)s
Depends:
Description: %(summary)s
 %(desc)s
""" % (self.__dict__)


    def _install(self):
        """Return the contents of the install file."""
        return "# Fill me out."


    def _dh_auto_install(self):
        """Return the rules for the dh_auto_install section of the rules file."""
        return "\t@echo \"Fill me out.\""

    def _dh_rules_header(self):
        return ""

    def _rules(self):
        """Return the contents of the rules file."""
        self.dh_auto_install_rules=self._dh_auto_install()
        self.rules_header=self._dh_rules_header()
        return """#!/usr/bin/make -f

DEB_DH_INSTALL_SOURCEDIR = debian/tmp
INSTALL_DIR = $(CURDIR)/$(DEB_DH_INSTALL_SOURCEDIR)
PACKAGE_NAME = %(package)s

%(rules_header)s

%%:
\tdh $@

build-arch:
\tdh build-arch

clean:
\tdh clean

override_dh_auto_install:
%(dh_auto_install_rules)s

""" % (self.__dict__)

    def __generate_file(self, path, name, contents):
        with open("%s/debian/%s" % (path, name), "w") as f:
            f.write(contents)

    def generate(self, path):
        os.makedirs("%s/debian" % path)
        self.__generate_file(path, ".gitignore", self._gitignore())
        self.__generate_file(path, "control", self._control())
        self.__generate_file(path, "compat", self._compat())
        self.__generate_file(path, "rules", self._rules())
        self.__generate_file(path, "%s.install" % self.package, self._install())
        self.__generate_file(path, "copyright", self._copyright())
        self.__generate_file(path, "changelog", self._changelog())

if __name__ == "__main__":
    import argparse

    ap=argparse.ArgumentParser(description="Create a new debian directory.")
    ap.add_argument("package", help="Package name.")
    ap.add_argument("arch", help="Package architecture.")
    ap.add_argument("summary", help="The package summary.")
    ap.add_argument("--desc", help="The package description.")

    ops = ap.parse_args()

    if ops.desc is None:
        ops.desc = ops.summary

    cg = DebianGenerator(ops.package, ops.arch, ops.summary, ops.desc)
    cg.generate(".")


