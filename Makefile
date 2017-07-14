#-------------------------------------------------------------------------------
#>
#
#  Copyright (C) 2013,2014,2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
# Builds the Open Network Install Environment documentation
#
#   build
#   ├── <platform>
#   │   ├── busybox
#   │   ├── initramfs
#   │   ├── kernel
#   │   ├── stamp
#   │   └── sysroot
#   ├── user/<toolchain>/
#   │        ├── btrfs-progs
#   │        ├── dmidecode
#   │        ├── dosfstools
#   │        ├── dropbear
#   │        ├── e2fsprogs
#   │        ├── efibootmgr
#   │        ├── efivar
#   │        ├── ethtool
#   │        ├── flashrom
#   │        ├── gptfdisk
#   │        ├── grub
#   │        ├── grub-host
#   │        ├── kexec-tools
#   │        ├── lvm2
#   │        ├── lzo
#   │        ├── mtd-utils
#   │        ├── parted
#   │        ├── pciutils
#   │        ├── popt
#   │        ├── stamp
#   │        ├── util-linux
#   │        └── zlib
#   ├── download
#   ├── x-tools
#   ├── docs
#   └── images
#
#<

# Don't move this, it must be in FRONT of any included makefiles
THIS_MAKEFILE = $(realpath $(firstword $(MAKEFILE_LIST)))

# Allow users to override any ?= variables early
-include local.make

#-------------------------------------------------------------------------------
#
# Setup
#

SHELL   = bash

# See if we are cleaning targets.  Allows us to skip some lengthy
# timestamp comparisions.  This captures all make goals containing the
# string "clean", including "clean" and "target-clean" variants.
ifneq (,$(findstring clean,$(MAKECMDGOALS)))
	MAKE_CLEAN = "yes"
endif

V ?= 0
Q = @
ifneq ($V,0)
	Q = 
endif

#-------------------------------------------------------------------------------
#
#  help (the default target)
#

.SUFFIXES:

PHONY += help
help:
	$(Q) sed -n -e "/^#>/,/^#</{s/^#[ <>]*//;s/\.PHONY *://;p}" $(THIS_MAKEFILE)
	$(Q) echo ""
	$(Q) echo "TARGETS"
	$(Q) for I in $(sort $(PHONY)); do echo "    $$I"; done
	$(Q) echo ""

#-------------------------------------------------------------------------------
#
#  local source trees
#

PATCHDIR     = $(realpath ./patches)
UPSTREAMDIR  = $(realpath ./upstream)
SCRIPTDIR    = $(realpath ./scripts)

#-------------------------------------------------------------------------------
#
#  project build tree
#

PROJECTDIR	=  $(abspath .)
BUILDDIR	=  $(abspath ./build)
DOWNLOADDIR	?= $(BUILDDIR)/download
export DOWNLOADDIR

# These directories are needed once for the entire project
PROJECTDIRS	= $(BUILDDIR) $(DOWNLOADDIR)
PROJECT_STAMP	= $(BUILDDIR)/stamp-project
project-stamp: $(PROJECT_STAMP)
$(PROJECT_STAMP): 
	$(Q) mkdir -pv $(PROJECTDIRS)
	$(Q) touch $@

TREE_STAMP  = $(STAMPDIR)/tree
tree-stamp: $(TREE_STAMP)
$(TREE_STAMP): $(PROJECT_STAMP)
	$(Q) mkdir -pv $(TREEDIRS)
	$(Q) touch $@

#-------------------------------------------------------------------------------
#
# stamp based profiling
#

ifdef MAKEPROF
 override PROFILE_STAMP = "touch $@.start"
else
 override PROFILE_STAMP = "true"
endif

#-------------------------------------------------------------------------------
#
# save a timestamp for "make all" profiling, only if we're starting from clean.
#

$(shell rm -f $(BUILDDIR)/.start_time)
ifeq ($(MAKECMDGOALS), all)
    $(shell mkdir -p $(BUILDDIR))
    ifeq ("$(shell ls $(BUILDDIR))", "")
        $(shell date +%s > $(BUILDDIR)/.start_time)
    endif
endif


#-------------------------------------------------------------------------------
#
# target make fragments
#

# Default mirror for packages needed by ONIE
ONIE_MIRROR	?= http://mirror.opencompute.org/onie

include docs.make

#-------------------------------------------------------------------------------
#
# top level targets
#

PHONY += source
source: $(SOURCE)
	$(Q) echo "=== Finished making $@ ==="

PHONY += download
download: $(DOWNLOAD)
	$(Q) echo "=== Finished making $@ ==="

PHONY += docs
docs: html

PHONY += all
all: docs
	$(Q) echo "=== Finished making docs ==="

PHONY += clean
clean: 	$(CLEAN)
	$(Q) echo "=== Finished making $@ ==="

PHONY += download-clean
download-clean: $(DOWNLOAD_CLEAN)
	$(Q) rm -rf $(DOWNLOADDIR)/*
	$(Q) echo "=== Finished making $@ ==="

PHONY += distclean
distclean: download-clean $(DIST_CLEAN)
	$(Q) for d in $(BUILDDIR)/* ; do \
		[ -e "$$d" ] || break ; \
		echo -n "=== Cleaning $$(basename $$d) ... " ; \
		rm -rf $$d ; \
		echo " done ===" ; done
	$(Q) rm -f $(PROJECT_STAMP)
	$(Q) echo "=== Finished making $@ ==="

.PHONY: $(PHONY)
