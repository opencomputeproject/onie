# -*- Makefile -*-
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
# Common rules for component debian builds.
#
############################################################

ifndef ARCH
$(error $$ARCH must be specified before including this makefile.)
else

ifeq ($(ARCH),all)
ARCH_OPTIONS :=
else
ARCH_OPTIONS := -a$(ARCH)
endif
endif


ifndef ONL
$(error $$ONL must be specified before including this makefile.)
endif

ifndef PACKAGE_NAMES
$(error $$PACKAGE_NAMES must be specified.)
endif

include $(ONL)/make/config.mk

DEBUILD = debuild --prepend-path=/usr/lib/ccache -eONL -eBUILD_DIR_BASE $(DEBUILD_ARGS) $(ARCH_OPTIONS) -b -us -uc

PACKAGE_DIR := $(ONL)/debian/repo

ifndef DEBUILD_DIR
DEBUILD_DIR := debuild
endif

# For .deb signing
ifndef ONL_GNUPGHOME
ONL_GNUPGHOME := $(ONL)/make/default_sign/gnupg
endif
ifndef DPKG_SIG
DPKG_SIG := dpkg-sig
endif

deb:
	$(ONL_V_at)$(MAKE) -C ../ $(ONL_MAKEFLAGS)
	cd $(DEBUILD_DIR); $(DEBUILD)
	GNUPGHOME=$(ONL_GNUPGHOME) $(DPKG_SIG) --sign builder *$(ARCH)*.deb  \
	&& echo Packages Signed # sign packages
	$(ONL_PKG_INSTALL) --add-pkg *$(ARCH)*.deb
	rm *$(ARCH)*.deb
	rm -rf $(DEBUILD_DIR)/debian/tmp $(foreach p,$(PACKAGE_NAMES),$(DEBUILD_DIR)/debian/$(p)/ $(DEBUILD_DIR)/debian/$(p)-dbg) || echo rm failed

clean:
	cd $(DEBUILD_DIR); $(DEBUILD) -Tclean
	rm -f *$(ARCH)*.deb *.changes *.build
dch:
	cd build; EMAIL="$(USER)@bigswitch.com" dch -i

all: deb


