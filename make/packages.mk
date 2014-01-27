# -*- Makefile -*-
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
# Update the package files update rebuild or install.
#
############################################################

ARCHS := powerpc amd64 i386 all

ONL_PACKAGES_powerpc := $(wildcard $(ONL_REPO)/powerpc/*.deb)
ONL_PACKAGES_amd64   := $(wildcard $(ONL_REPO)/amd64/*.deb)
ONL_PACKAGES_i386    := $(wildcard $(ONL_REPO)/i386/*.deb)
ONL_PACKAGES_all     := $(wildcard $(ONL_REPO)/all/*.deb)

ONL_PACKAGES := $(foreach arch,$(ARCHS), $(ONL_PACKAGES_$(arch)))

# Debian Package Manifest
ONL_PACKAGE_MANIFEST := $(foreach arch,$(ARCHS),$(ONL_REPO)/$(arch)/Packages)

# Rebuild the package manifests whenever the component packages are updated.
$(ONL_REPO)/%/Packages: $(ONL_PACKAGES)
	cd $(dir $@); dpkg-scanpackages . > Packages

all: $(ONL_PACKAGE_MANIFEST)