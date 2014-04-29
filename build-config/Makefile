#-------------------------------------------------------------------------------
#
#>
# Builds the Open Network Install Environment install images
#
# The image contains:
#
#   u-boot
#   kernel
#   initramfs loaded with the ONIE discovery and execution application.
#
# THIS MAKEFILE USES SUDO TO EXECUTE VARIOUS OPERATIONS WITH ROOT PRIVILEGES!!!!
#
# The configuration for a specific platform must be located in
# ../machine/<platform>
#
# The build specification is in this directory, and the results of the process end
# up in ../build.  The dependencies follow a source, patch, build, install
# sequence and use stamps to track targets.
#
# Typical usage is to checkout a tree and type:
#
#    make MACHINE=<platform> all
#
# Note: The directory ../machine/<platform> must exist.
#
# The result of the build creates the following directory tree...
# 
#   build
#   ├── <platform>
#   │   ├── busybox
#   |   |-- i2ctools
#   │   ├── initramfs
#   │   ├── kernel
#   │   ├── stamp
#   │   ├── sysroot
#   │   ├── u-boot
#   │   ├── uclibc
#   │   ├── e2fsprogs
#   │   ├── zlib
#   │   ├── lzo
#   │   ├── mtdutils
#   │   └── dropbear
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

PATCHDIR     = $(realpath ../patches)
UPSTREAMDIR  = $(realpath ../upstream)
CONFDIR	     = $(realpath ../rootconf)
SCRIPTDIR    = $(realpath ./scripts)

#-------------------------------------------------------------------------------
#
#  project build tree
#

PROJECTDIR	=  $(abspath ..)
BUILDDIR	=  $(abspath ../build)
IMAGEDIR	=  $(BUILDDIR)/images
TESTDIR		=  $(PROJECTDIR)/test
DOWNLOADDIR	?= $(BUILDDIR)/download
export DOWNLOADDIR

# These directories are needed once for the entire project
PROJECTDIRS	= $(BUILDDIR) $(IMAGEDIR) $(DOWNLOADDIR)
PROJECT_STAMP	= $(BUILDDIR)/stamp-project
project-stamp: $(PROJECT_STAMP)
$(PROJECT_STAMP): 
	$(Q) mkdir -pv $(PROJECTDIRS)
	$(Q) touch $@

#-------------------------------------------------------------------------------
#
#  Target machine -- Usually specified on command line
#
MACHINE  ?= kvm_x86_64
MACHINE_PREFIX = $(MACHINE)-r$(MACHINE_REV)

MACHINEROOT ?= $(realpath ../machine)
MACHINEDIR   = $(MACHINEROOT)/$(MACHINE)

#-------------------------------------------------------------------------------
#
#  machine build tree
#

MBUILDDIR	=  $(BUILDDIR)/$(MACHINE_PREFIX)
STAMPDIR	=  $(MBUILDDIR)/stamp
SYSROOTDIR	=  $(MBUILDDIR)/sysroot
DEV_SYSROOT	=  $(MBUILDDIR)/dev-sysroot
INITRAMFSDIR	=  $(MBUILDDIR)/initramfs

# These directories are needed per machine
TREEDIRS     += $(STAMPDIR) $(STAGE_SYSROOT) $(INITRAMFSDIR)

ifneq (,$(MAKECMDGOALS))
  ifeq (,$(filter lsb-release-tag help distclean %build-host doc% %html %pdf, $(MAKECMDGOALS)))
    ifeq ($(wildcard $(MACHINEDIR)/*),)
      $(warning Unable to find machine directory '$(MACHINEDIR)')
      $(warning You must set the MACHINE= variable when invoking make.)
      $(warning You can also set the machine root directory with MACHINEROOT= .)
      $(error Unable to find valid machine configuration directory.)
    endif
    include $(MACHINEDIR)/machine.make
    ARCHDIR ?= $(realpath ./arch)
    include $(ARCHDIR)/$(ONIE_ARCH).make
  endif
endif

PLATFORM  = $(ARCH)-$(MACHINE_PREFIX)

# Verify partition type
ifneq ($(filter-out gpt msdos, $(PARTITION_TYPE)),)
  $(warning Unsupported partition type: $(PARTITION_TYPE))
  $(error Supported partition types: gpt, msdos)
endif

TREE_STAMP  = $(STAMPDIR)/tree
tree-stamp: $(TREE_STAMP)
$(TREE_STAMP): $(PROJECT_STAMP)
	$(Q) mkdir -pv $(TREEDIRS)
	$(Q) touch $@

#-------------------------------------------------------------------------------
#
# Determine build id tag
#
# - The version is derived from the current git branch and the build
# - date.
#
LSB_RELEASE_TAG	?= $(shell [ -r ./conf/lsb-release ] && cat ./conf/lsb-release)
ifeq ($(LSB_RELEASE_TAG),)
  GIT_BRANCH = $(shell cd $(MACHINEDIR) && git rev-parse --abbrev-ref HEAD)
  BUILD_DATE = $(shell date +%Y%m%d%H%M)
  ifneq ($(RELEASE),)
    # Optional: If RELEASE specified on the command line insert the
    # string after the branch name.
    LSB_RELEASE_TAG = $(GIT_BRANCH)-$(RELEASE)-$(BUILD_DATE)
  else
    LSB_RELEASE_TAG = $(GIT_BRANCH)-$(BUILD_DATE)
  endif
  DIRTY  = $(shell cd $(MACHINEDIR) && git status | \
		egrep -q '(Your branch is ahead|modified:|Untracked files:)' && echo dirty)
  ifneq ($(DIRTY),)
    LSB_RELEASE_TAG := $(LSB_RELEASE_TAG)-$(DIRTY)
  endif
endif

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
ONIE_MIRROR	?= http://dev.cumulusnetworks.com/~curt/mirror/onie

include make/crosstool-ng.make
include make/kernel-download.make
include make/uclibc-download.make
include make/xtools.make
include make/sysroot.make
include make/kernel.make
ifeq ($(UBOOT_ENABLE),yes)
  include make/u-boot.make
endif
include make/compiler.make
include make/busybox.make
include make/zlib.make
include make/lzo.make
include make/e2fsprogs.make
include make/mtdutils.make
include make/dropbear.make
ifeq ($(GPT_ENABLE),yes)
  include make/popt.make
  include make/gptfdisk.make
endif
ifeq ($(LVM2_ENABLE),yes)
  include make/lvm2.make
endif
ifeq ($(PARTED_ENABLE),yes)
  include make/parted.make
endif
ifeq ($(GRUB_ENABLE),yes)
  include make/grub.make
endif
ifeq ($(I2CTOOLS_ENABLE),yes)
  include make/i2ctools.make
endif
ifeq ($(DMIDECODE_ENABLE),yes)
  include make/dmidecode.make
endif
include make/images.make
include make/demo.make
include make/docs.make

#-------------------------------------------------------------------------------
#
# top level targets
#

PHONY += all source demo clean userspace-clean download download-clean docs

source: $(SOURCE)
	$(Q) echo "=== Finished making $@ ==="

download: $(DOWNLOAD)
	$(Q) echo "=== Finished making $@ ==="

all: $(KERNEL) $(UBOOT) $(SYSROOT) $(IMAGE)
	$(Q) echo "=== Finished making onie-$(PLATFORM) $(LSB_RELEASE_TAG) ==="

demo: $(KERNEL) $(DEMO_IMAGE)
	$(Q) echo "=== Finished making demo onie-$(PLATFORM) $(LSB_RELEASE_TAG) ==="

docs: html pdf

userspace-clean: $(USERSPACE_CLEAN)
	$(Q) echo "=== Finished making $@ ==="

clean: 	$(CLEAN) $(USERSPACE_CLEAN)
	$(Q) rm -rf $(BUILDDIR)/images/*$(MACHINE_PREFIX)*
	$(Q) rm -rf $(MBUILDDIR)
	$(Q) echo "=== Finished making $@ for $(PLATFORM) ==="

download-clean: $(DOWNLOAD_CLEAN)
	$(Q) rm -rf $(DOWNLOADDIR)/*
	$(Q) echo "=== Finished making $@ ==="

distclean: download-clean $(DIST_CLEAN)
	$(Q) for d in $(BUILDDIR)/* ; do \
		[ -e "$$d" ] || break ; \
		echo -n "=== Cleaning $$(basename $$d) ... " ; \
		rm -rf $$d ; \
		echo " done ===" ; done
	$(Q) rm -f $(PROJECT_STAMP)
	$(Q) echo "=== Finished making $@ ==="

PHONY += lsb-release-tag
lsb-release-tag:
	$(Q) echo $(LSB_RELEASE_TAG)

PHONY += machine-prefix
machine-prefix:
	$(Q) echo $(MACHINE_PREFIX)

# Install required build packages for a debian based build host
DEBIAN_BUILD_HOST_PACKAGES	= build-essential stgit u-boot-tools python-sphinx rst2pdf \
				  gperf device-tree-compiler python-all-dev genisoimage syslinux-common
PHONY += debian-prepare-build-host
debian-prepare-build-host:
	$(Q) sudo apt-get update
	$(Q) sudo apt-get install $(DEBIAN_BUILD_HOST_PACKAGES)

PHONY += test-onie
SITE_CONFIG ?= $(TESTDIR)/site.conf
DUT_NAME    ?= onie-test-01
DUT_LOG_DIR ?= /tmp/$(DUT_NAME)
DUT_LOG     = $(DUT_LOG_DIR)/test-onie-$$(date +%s).log

test-onie:
	$(Q) mkdir -p $(DUT_LOG_DIR)
	$(Q) $(TESTDIR)/bin/test-onie.py \
		--machine-dir=$(MACHINEDIR) --site-config=$(SITE_CONFIG) \
		--dut-name=$(DUT_NAME) --log-level=INFO \
		--console-log=$(DUT_LOG)

.PHONY: $(PHONY)
