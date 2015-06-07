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
# Build a component from the architecture-any directory.
#
############################################################
ifndef ANYDIR
$(error $$ANYDIR must be specified.)
endif

ifndef ARCH
$(error $$ARCH must be specified.)
endif

ifndef TOOLCHAIN
$(error $$TOOLCHAIN must be specified.)
endif

ifndef BUILD_DIR_BASE
# Assume the build directory should be in the parent makefile's directory,
BUILD_DIR_BASE := $(abspath $(dir $(lastword $(filter-out $(lastword $(MAKEFILE_LIST)),$(MAKEFILE_LIST))))/build)
endif

export ARCH
export TOOLCHAIN
export BUILD_DIR_BASE

TARGET_DIR := $(ONL)/components/any/$(ANYDIR)
DEBUILD_DIR := debuild-$(ARCH)

all:
	$(MAKE) -C $(TARGET_DIR)

deb:
	rm -rf $(TARGET_DIR)/deb/$(DEBUILD_DIR)
	cp -R $(TARGET_DIR)/deb/debuild $(TARGET_DIR)/deb/$(DEBUILD_DIR)
	$(MAKE) -C $(TARGET_DIR) deb DEBUILD_DIR=$(DEBUILD_DIR)

clean:
	rm -rf $(TARGET_DIR)/deb/$(DEBUILD_DIR)
	$(MAKE) -C $(TARGET_DIR) clean
	rm -rf build

