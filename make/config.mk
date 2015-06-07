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
# Open Network Linux Global Configuration
#
############################################################
SHELL := /bin/bash
empty:=
space:= $(empty) $(empty)
# The current release branch or number goes here.
ONL_RELEASE_VERSION := $(shell git rev-parse --short HEAD)
ONL_RELEASE_BANNER := $(space)$(ONL_RELEASE_VERSION)$(space)

#
# These are the default submodule locations.
# These allow environment overrides for custom frankenbuilds.
#
ONL_LOCAL_SUBMODULES := none

ifndef ONL_SUBMODULE_INDIGO
ONL_SUBMODULE_INDIGO      := $(ONL)/submodules/indigo
ONL_LOCAL_SUBMODULES += indigo
endif

ifndef ONL_SUBMODULE_ONLP
ONL_SUBMODULE_ONLP      := $(ONL)/submodules/onlp
ONL_LOCAL_SUBMODULES += onlp
endif

ifndef ONL_SUBMODULE_ONLP_ACCTON
ONL_SUBMODULE_ONLP_ACCTON      := $(ONL)/submodules/onlp-accton
ONL_LOCAL_SUBMODULES += onlp-accton
endif

ifndef ONL_SUBMODULE_ONLP_DELL
ONL_SUBMODULE_ONLP_DELL      := $(ONL)/submodules/onlp-dell
ONL_LOCAL_SUBMODULES += onlp-dell
endif

ifndef ONL_SUBMODULE_ONLP_DNI
ONL_SUBMODULE_ONLP_DNI      := $(ONL)/submodules/onlp-dni
ONL_LOCAL_SUBMODULES += onlp-dni
endif

ifndef ONL_SUBMODULE_ONLP_QUANTA
ONL_SUBMODULE_ONLP_QUANTA      := $(ONL)/submodules/onlp-quanta
ONL_LOCAL_SUBMODULES += onlp-quanta
endif

ifndef ONL_SUBMODULE_LINUX_3_9_6
ONL_SUBMODULE_LINUX_3_9_6      := $(ONL)/submodules/linux-3.9.6
ONL_LOCAL_SUBMODULES += linux-3.9.6
endif

ifndef ONL_SUBMODULE_LINUX_3_8_13
ONL_SUBMODULE_LINUX_3_8_13      := $(ONL)/submodules/linux-3.8.13
ONL_LOCAL_SUBMODULES += linux-3.8.13
endif

ifndef ONL_SUBMODULE_LINUX
ONL_SUBMODULE_LINUX := $(ONL)/submodules/linux
ONL_LOCAL_SUBMODULES += linux
endif

ifndef ONL_SUBMODULE_INFRA
ONL_SUBMODULE_INFRA	:= $(ONL)/submodules/infra
ONL_LOCAL_SUBMODULES += infra
endif

ifndef ONL_SUBMODULE_LOADER
ONL_SUBMODULE_LOADER     := $(ONL)/submodules/loader
ONL_LOCAL_SUBMODULES += loader
endif

ifndef ONL_SUBMODULE_COMMON
ONL_SUBMODULE_COMMON 	 := $(ONL)/submodules/common
ONL_LOCAL_SUBMODULES += common
endif

ifndef ONL_SUBMODULE_BIGCODE
ONL_SUBMODULE_BIGCODE 	 := $(ONL)/submodules/bigcode
ONL_LOCAL_SUBMODULES += bigcode
endif

ifndef ONL_SUBMODULE_OFDPA_20
ONL_SUBMODULE_OFDPA_20 := $(ONL)/submodules/ofdpa-2.0
ONL_LOCAL_SUBMODULES += ofdpa-2.0
endif

ifndef ONL_SUBMODULE_OFDPA_20_CLOSED
ONL_SUBMODULE_OFDPA_20_CLOSED := $(ONL)/submodules/ofdpa-2.0-closed
ONL_LOCAL_SUBMODULES += ofdpa-2.0-closed
endif

ifndef ONL_SUBMODULE_LOXIGEN_ARTIFACTS
ONL_SUBMODULE_LOXIGEN_ARTIFACTS := $(ONL)/submodules/loxigen-artifacts
ONL_LOCAL_SUBMODULES += loxigen-artifacts
endif

#
# These are the required derivations from the ONL settings:
#
ifndef BUILDER
export BUILDER := $(ONL_SUBMODULE_INFRA)/builder/unix
endif

#
# Location of the local package repository
#
ONL_REPO := $(ONL)/debian/repo

# Path to package installer
ONL_PKG_INSTALL := $(ONL)/tools/onlpkg.py

#
# Make sure the required local submodules have been updated.
#
ifdef ONL_REQUIRED_SUBMODULES
space :=
space +=
ONL_REQUIRED_SUBMODULES := $(subst $(space),:,$(ONL_REQUIRED_SUBMODULES))
ONL_LOCAL_SUBMODULES := $(subst $(space),:,$(ONL_LOCAL_SUBMODULES))
endif

ifdef ONL_BUILD_CONFIG_FILE
include $(ONL_BUILD_CONFIG_FILE)
endif

ifndef ONL_BUILD_TIMESTAMP
ONL_BUILD_TIMESTAMP := $(shell date +%Y.%m.%d.%H.%M)
endif

ifndef ONL_BUILD_SHA1
ONL_BUILD_SHA1 := $(shell git rev-list HEAD -1)
endif

ifndef ONL_BUILD_CONFIG
ONL_BUILD_CONFIG := unknown
endif

ifeq ("$(origin V)", "command line")
VERBOSE := $(V)
endif
ifneq ($(VERBOSE),1)

# quiet settings
ONL_V_P := false
ONL_V_at := @
ONL_V_GEN = @set -e; echo GEN $@;

else

# verbose settings
ONL_V_P := :
ONL_PKG_INSTALL := $(ONL)/tools/onlpkg.py --verbose

endif

ifndef ONL_MAKEFLAGS
ifeq ($(VERBOSE),1)
else
ONL_MAKEFLAGS = --no-print-directory
endif
endif

#
# Inherit MODULE_DIRs for all local builds.
# This turns out to  be terribly hacky wrt the component makefiles.
# This should be a temporary solution.
#
ALL_SUBMODULES = INFRA COMMON BIGCODE ONLP ONLP_ACCTON ONLP_DNI ONLP_QUANTA ONLP_DELL INDIGO OFDPA_20 OFDPA_20_CLOSED LOXIGEN_ARTIFACTS
MODULE_DIRS := $(foreach submodule,$(ALL_SUBMODULES),$(ONL_SUBMODULE_$(submodule))/modules)
MODULE_DIRS_TOUCH := $(foreach sd,$(MODULE_DIRS),$(shell mkdir -p $(sd) && touch $(sd)/Manifest.mk))

override SUBMODULE_LOXIGEN_ARTIFACTS := $(ONL_SUBMODULE_LOXIGEN_ARTIFACTS)
export SUBMODULE_LOXIGEN_ARTIFACTS
