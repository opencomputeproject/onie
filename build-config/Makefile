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
#  Target Architecture and Toolchain Setup
#

ARCH        ?= powerpc
TARGET      ?= $(ARCH)-linux
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= /opt/eldk-5.3/powerpc-softfloat/sysroots/i686-eldk-linux/usr/bin/powerpc-nf-linux

# Determine the location of the compiler libraries and start files.
# These are needed later for linking user space binaries with uClibc.
CROSSCOMPILER_LIBS ?= $(shell dirname $$(dirname $$(PATH=$(CROSSBIN):$(PATH) $(CROSSPREFIX)gcc -print-libgcc-file-name)))
ifeq ($(CROSSCOMPILER_LIBS),)
  $(error Unable to determine compiler libraries for cross compiler $(CROSSPREFIX))
endif

ifeq ($(ARCH), powerpc)
else
  $(error Error: Unknown architecture '$(ARCH)')
endif

UCLIBC_FLAGS=--sysroot=$(UCLIBC_DEV_SYSROOT) -muclibc -L$(CROSSCOMPILER_LIBS) -L$(CROSSCOMPILER_LIBS)/../../../lib

#-------------------------------------------------------------------------------
#
#  Target Platform -- Usually specified on command line
#
MACHINE  ?= fsl_p2020rdbpca
MACHINE_PREFIX = $(MACHINE)
PLATFORM  = $(ARCH)-$(MACHINE_PREFIX)

#-------------------------------------------------------------------------------
#
#  local source trees
#

PATCHDIR     = $(realpath ../patches)
UPSTREAMDIR  = $(realpath ../upstream)
CONFDIR	     = $(realpath ../rootconf)
SCRIPTDIR    = $(realpath ./scripts)
MACHINEROOT ?= $(realpath ../machine)
MACHINEDIR   = $(MACHINEROOT)/$(MACHINE)

ifneq (,$(MAKECMDGOALS))
  ifeq (,$(filter lsb-release-tag help clean-all %build-host doc% %html %pdf, $(MAKECMDGOALS)))
    ifeq ($(wildcard $(MACHINEDIR)/*),)
      $(warning Unable to find machine directory '$(MACHINEDIR)')
      $(warning You must set the MACHINE= variable when invoking make.)
      $(warning You can also set the machine root directory with MACHINEROOT= .)
      $(error Unable to find valid machine configuration directory.)
    endif
    include $(MACHINEDIR)/machine.make
  endif
endif

#-------------------------------------------------------------------------------
#
#  build tree
#

PROJECTDIR  =  $(abspath ..)
BUILDDIR    =  $(abspath ../build)
MBUILDDIR   =  $(BUILDDIR)/$(MACHINE_PREFIX)
STAMPDIR    =  $(MBUILDDIR)/stamp
SYSROOTDIR  =  $(MBUILDDIR)/sysroot
INITRAMFSDIR=  $(MBUILDDIR)/initramfs
IMAGEDIR    =  $(BUILDDIR)/images

TREEDIRS     += $(BUILDDIR) $(STAMPDIR) $(SYSROOTDIR) \
		$(IMAGEDIR) $(INITRAMFSDIR)

TREE_STAMP  = $(STAMPDIR)/tree
tree-stamp: $(TREE_STAMP)
$(TREE_STAMP):
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

include make/sysroot.make
include make/kernel.make
include make/u-boot.make
include make/uclibc.make
include make/busybox.make
include make/zlib.make
include make/lzo.make
include make/e2fsprogs.make
include make/mtdutils.make
include make/dropbear.make
include make/images.make
include make/demo.make
include make/docs.make

#-------------------------------------------------------------------------------
#
# top level targets
#

PHONY += all source demo clean clean-all docs

source: $(SOURCE)
	$(Q) echo "=== Finished making $@ ==="

all: $(KERNEL) $(UBOOT) $(SYSROOT) $(IMAGE)
	$(Q) echo "=== Finished making onie-$(PLATFORM) $(LSB_RELEASE_TAG) ==="

demo: $(KERNEL) $(DEMO_IMAGE)
	$(Q) echo "=== Finished making demo onie-$(PLATFORM) $(LSB_RELEASE_TAG) ==="

docs: html pdf

clean: 	$(CLEAN)
	$(Q) rm -rf $(BUILDDIR)/images/*$(MACHINE_PREFIX)*
	$(Q) rm -rf $(MBUILDDIR)
	$(Q) echo "=== Finished making $@ for $(PLATFORM) ==="

clean-all:
	$(Q) rm -rf $(BUILDDIR)/*
	$(Q) echo "=== Finished making $@ ==="

PHONY += lsb-release-tag
lsb-release-tag:
	$(Q) echo $(LSB_RELEASE_TAG)

PHONY += machine-prefix
machine-prefix:
	$(Q) echo $(MACHINE_PREFIX)

# Install required build packages for a debian based build host
DEBIAN_BUILD_HOST_PACKAGES	= build-essential stgit u-boot-tools python-sphinx rst2pdf
PHONY += debian-prepare-build-host
debian-prepare-build-host:
	$(Q) sudo apt-get update
	$(Q) sudo apt-get install $(DEBIAN_BUILD_HOST_PACKAGES)

.PHONY: $(PHONY)
