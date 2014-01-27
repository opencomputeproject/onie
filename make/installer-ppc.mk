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
# Common Powerpc Installers
#
############################################################
ifndef ONL
$(error $$ONL is not set.)
else
include $(ONL)/make/config.mk
endif

# The platform list must be specified
ifndef INSTALLER_PLATFORMS
$(error $$INSTALLER_PLATFORMS not defined)
endif
# The SWI to include in the installer must be specified
ifndef INSTALLER_SWI
$(error $$INSTALLER_SWI is not set)
endif

# The final name of the installer file must be specified.
ifndef INSTALLER_NAME
$(error $$INSTALLER_NAME is not set)
endif

# Get the platform loaders from each platform package
PLATFORM_LOADERS := $(foreach p,$(INSTALLER_PLATFORMS),$(shell $(ONL_PKG_INSTALL) platform-$(p):powerpc --find-file onl.$(p).loader))
# Get the platform config package for each platform

$(INSTALLER_NAME): $(INSTALLER_NAME).cpio
	$(ONL_V_at)cp /dev/null $@
	$(ONL_V_at)sed \
	  -e 's^@ONLVERSION@^$(RELEASE)^g' \
	  $(ONL)/builds/installer/installer.sh \
	>> $@
	$(ONL_V_GEN)gzip -9 < $@.cpio >> $@
	$(ONL_V_at)rm $@.cpio
	rm -rf latest.installer
	ln -s $(INSTALLER_NAME) latest.installer

$(INSTALLER_NAME).cpio: $(PLATFORM_DIRS) $(INSTALLER_SWI)
	$(ONL_V_at)cp $(PLATFORM_LOADERS) .
	$(foreach p,$(INSTALLER_PLATFORMS), $(ONL_PKG_INSTALL) platform-config-$(p):all --extract .;)
	$(ONL_V_at)cp $(INSTALLER_SWI) onl-powerpc.swi
	$(ONL_V_GEN)set -o pipefail ;\
	if $(ONL_V_P); then v="-v"; else v="--quiet"; fi ;\
	find *.loader lib onl-powerpc.swi \
	| cpio $$v -H newc -o > $@
	$(ONL_V_at)rm -f onl-powerpc.swi
	$(ONL_V_at)rm -rf ./lib ./usr *.loader

$(INSTALLER_SWI):
	$(MAKE) -C $(dir $(INSTALLER_SWI))

# Build config
ifndef ONL_BUILD_CONFIG
$(error $$ONL_BUILD_CONFIG is not defined.)
endif

# Release string, copied from swi.mk
ifndef RELEASE
RELEASE := Open Network Linux$(ONL_RELEASE_BANNER)($(ONL_BUILD_CONFIG),$(ONL_BUILD_TIMESTAMP),$(ONL_BUILD_SHA1))
endif

clean:
	rm -f *.cpio *.jffs2 *.loader *.swi *.installer
