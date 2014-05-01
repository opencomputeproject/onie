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
# Common rootfs build rules.
#
############################################################

ifndef ONL
$(error $$ONL not defined.)
endif

ifndef ROOTFS_BUILD_DIR
$(error $$ROOTFS_BUILD_DIR is not specified.)
endif

ifndef ROOTFS_ARCH
$(error $$ROOTFS_ARCH is not specified.)
endif

include $(ONL)/make/config.mk
include $(ONL)/make/packages.mk

ROOTFS_NAME=rootfs-$(ROOTFS_ARCH)
ROOTFS_DIR=$(ROOTFS_BUILD_DIR)/$(ROOTFS_NAME)

ifndef ROOTFS_ARCH_REPO_NAME
ROOTFS_ARCH_REPO_NAME := repo.$(ROOTFS_ARCH)
endif

ifndef ROOTFS_ARCH_REPO_PATH
ROOTFS_ARCH_REPO_PATH := $(ROOTFS_BUILD_DIR)/$(ROOTFS_ARCH_REPO_NAME)
endif

ifndef ROOTFS_ALL_REPO_NAME
ROOTFS_ALL_REPO_NAME := repo.all
endif

ifndef ROOTFS_ALL_REPO_PATH
ROOTFS_ALL_REPO_PATH := $(ROOTFS_BUILD_DIR)/$(ROOTFS_ALL_REPO_NAME)
endif

ifndef ROOTFS_CLEANUP_NAME
ROOTFS_CLEANUP_NAME := cleanup
endif

ifndef ROOTFS_CLEANUP_PATH
ROOTFS_CLEANUP_PATH := $(ROOTFS_BUILD_DIR)/$(ROOTFS_CLEANUP_NAME)
endif

rootfs.all: $(ROOTFS_DIR).sqsh $(ROOTFS_DIR).cpio

export ONL

ifndef APT_CACHE
APT_CACHE := 10.198.0.0:3142/
endif

ifndef NO_PACKAGE_DEPENDENCY
PACKAGE_DEPENDENCY = $(ONL_PACKAGE_MANIFEST)
endif

$(ROOTFS_BUILD_DIR)/.$(ROOTFS_NAME).done: $(PACKAGE_DEPENDENCY)
	$(ONL_V_at)sudo update-binfmts --enable
	$(ONL_V_at)sudo rm -rf $(ROOTFS_DIR)
	$(ONL_V_GEN)set -e ;\
	if $(ONL_V_P); then set -x; fi ;\
	arch_repo=$$(mktemp) ;\
	all_repo=$$(mktemp) ;\
	trap "rm -f $$arch_repo $$all_repo" 0 1 ;\
	echo $$arch_repo ;\
	sed "s%__DIR__%$(ONL_REPO)%g" $(ROOTFS_ARCH_REPO_PATH) >$$arch_repo ;\
	sed "s%__DIR__%$(ONL_REPO)%g" $(ROOTFS_ALL_REPO_PATH) >$$all_repo ;\
	$(ONL)/tools/scripts/onl-mkws \
	  -e ONL=$(ONL) \
	  --apt-cache $(APT_CACHE) \
	  --nested \
	  -a $(ROOTFS_ARCH) \
	  --extra-repo $$arch_repo \
	  --extra-repo $$all_repo \
	  --extra-config $(ROOTFS_CLEANUP_PATH) \
	  $(ROOTFS_DIR)
	find $(ROOTFS_DIR)/etc/apt -name "*.list" -print0 | sudo xargs -0 sed -i 's/$(subst /,\/,$(APT_CACHE))//g'
	$(ONL_V_at)touch $@

$(ROOTFS_DIR).sqsh: $(ROOTFS_BUILD_DIR)/.$(ROOTFS_NAME).done
	$(ONL_V_GEN)set -e ;\
	if $(ONL_V_P); then set -x; fi ;\
	f=$$(mktemp) ;\
	trap "rm -f $$f" 0 1 ;\
	sudo mksquashfs $(ROOTFS_DIR) $$f -no-progress -noappend -comp gzip;\
	sudo cat $$f > $(ROOTFS_DIR).sqsh

$(ROOTFS_DIR).cpio: $(ROOTFS_BUILD_DIR)/.$(ROOTFS_NAME).done
	sudo -- /bin/sh -c "cd $(ROOTFS_DIR); find . -print0 | cpio -0 -H newc -o" > $@

$(ROOTFS_NAME).sqsh: $(ROOTFS_DIR).sqsh

$(ROOTFS_NAME).cpio: $(ROOTFS_DIR).cpio

clean:
	$(ONL_V_at)sudo rm -rf $(ROOTFS_DIR)
	$(ONL_V_at)rm -f $(ROOTFS_DIR).sqsh
	$(ONL_V_at)rm -f $(ROOTFS_DIR).cpio
	$(ONL_V_at)rm -f $(ROOTFS_BUILD_DIR)/.$(ROOTFS_NAME).done
