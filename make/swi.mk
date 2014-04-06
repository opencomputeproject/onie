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
# Common SWI build rules
#
############################################################
ifndef ONL
$(error $$ONL is not defined.)
else
include $(ONL)/make/config.mk
export ONL
endif

ifndef SWI
$(error $$SWI is not defined.)
endif

.DEFAULT_GOAL := $(SWI).swi

# We need a set of kernels
ifndef KERNELS
$(error $$KERNELS is not defined.)
else
KERNELS_LOCAL := $(foreach k,$(KERNELS),$(notdir $(k)))
endif

# We need an initrd
ifndef INITRD
$(error $$INITRD is not defined.)
else
INITRD_LOCAL := $(notdir $(INITRD))
endif

# Build config
ifndef ONL_BUILD_CONFIG
$(error $$ONL_BUILD_CONFIG is not defined.)
endif

# Release string
ifndef RELEASE
RELEASE := Open Network Linux $(ONL_RELEASE_BANNER)($(ONL_BUILD_CONFIG),$(ONL_BUILD_TIMESTAMP),$(ONL_BUILD_SHA1))
endif

ifndef ARCH
$(error $$ARCH is not defined.)
endif

$(SWI).swi: rootfs-$(ARCH).sqsh
	rm -f $@.tmp
	rm -f *.swi
	cp $(KERNELS) $(INITRD) .
	zip -n $(INITRD_LOCAL):rootfs-$(ARCH).sqsh - $(KERNELS_LOCAL) $(INITRD_LOCAL) rootfs-$(ARCH).sqsh >$@.tmp
	$(ONL)/tools/swiver $@.tmp $(SWI)-$(ONL_BUILD_TIMESTAMP).swi "$(RELEASE)"
	ln -s $(SWI)-$(ONL_BUILD_TIMESTAMP).swi $@
	rm $(KERNELS_LOCAL) $(INITRD_LOCAL) rootfs-$(ARCH).sqsh *.tmp

rootfs-$(ARCH).sqsh:
	$(MAKE) -C rootfs rootfs.all
	cp rootfs/$@ .

clean:
	$(ONL_V_at)rm -f $(KERNELS_LOCAL) $(INITRD_LOCAL) rootfs-$(ARCH).sqsh *.tmp
	$(ONL_V_at)rm -f *.swi
	$(ONL_V_at)$(MAKE) -C rootfs clean


