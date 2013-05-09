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
#   │   └── uclibc
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
# Determine build id tag
#
# - default release is nightly build. 
# - change it to RC1, RC2 etc. for Release Candidate releases
# - or override this with a definition from the command line
#
VERSION_FILE	= $(abspath ./conf/version)
RELEASE_VERSION = $(shell cat $(VERSION_FILE) | grep VERSION | sed -e 's/.*=//')
RELEASE ?= "NB"
LSB_RELEASE_TAG	?= $(shell [ -r ./conf/lsb-release ] && cat ./conf/lsb-release)
ifeq ($(LSB_RELEASE_TAG),)
  ifeq (1, $(RELEASE))
    LSB_RELEASE_TAG = $(RELEASE_VERSION)
  else ifeq ($(findstring RC,$(RELEASE)),RC)
    LSB_RELEASE_TAG = $(RELEASE_VERSION)-$(RELEASE)
  else
    GIT_HEAD = $(shell git show --abbrev-commit HEAD | sed -ne "/^commit [0-9a-f]*/s/^commit //p")
    BUILD_DATE = $(shell date +%Y%m%d)
    LSB_RELEASE_TAG = $(RELEASE_VERSION)-$(GIT_HEAD)-$(BUILD_DATE)-$(RELEASE)
  endif
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
TARGET      ?= $(ARCH)-linux-gnuspe
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= /opt/eldk-5.3/powerpc-e500v2/sysroots/i686-eldk-linux/usr/bin/ppce500v2-linux-gnuspe

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

#-------------------------------------------------------------------------------
#
#  Target Platform -- Usually specified on command line
#
MACHINE  ?= unknown
PLATFORM  = $(ARCH)-$(MACHINE)

#-------------------------------------------------------------------------------
#
#  build tree
#

PROJECTDIR  =  $(abspath ..)
BUILDDIR    =  $(abspath ../build)
MBUILDDIR   =  $(BUILDDIR)/$(MACHINE)
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
#  local source trees
#

PATCHDIR     = $(realpath ../patches)
UPSTREAMDIR  = $(realpath ../upstream)
CONFDIR	     = $(realpath ../rootconf)
SCRIPTDIR    = $(realpath ./scripts)
PLATFORMDIR  = $(realpath ./platform)
MACHINEROOT ?= $(realpath ../machine)
MACHINEDIR   = $(MACHINEROOT)/$(MACHINE)

ifeq (,$(filter help clean-all dist, $(MAKECMDGOALS)))
  ifeq ($(shell ls $(MACHINEDIR)),)
    $(warning Unable to find machine directory '$(MACHINE)' in $(realpath ../machine))
    $(error You must set the MACHINE= variable when invoking make.)
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
include make/images.make

#-------------------------------------------------------------------------------
#
# top level targets
#

PHONY += all source clean clean-all

source: $(SOURCE)
	$(Q) echo "=== Finished making $@ ==="

all: $(KERNEL) $(UBOOT) $(SYSROOT) $(IMAGE)
	$(Q) echo "=== Finished making onie-$(PLATFORM) $(LSB_RELEASE_TAG) ==="

clean: 	$(CLEAN)
	$(Q) sudo rm -rf $(BUILDDIR)/images/*$(MACHINE)*
	$(Q) sudo rm -rf $(MBUILDDIR)
	$(Q) echo "=== Finished making $@ for $(PLATFORM) ==="

clean-all:
	$(Q) sudo rm -rf $(BUILDDIR)/*
	$(Q) echo "=== Finished making $@ ==="

PHONY += dist
DIST_DIR = $(BUILDDIR)/dist
DIST_MACHINE_DIR = $(BUILDDIR)/dist/machine
DIST_CORE_RELEASE = onie-core-$(LSB_RELEASE_TAG)
DIST_CORE_STAGE_DIR = $(DIST_DIR)/$(DIST_CORE_RELEASE)
DIST_CORE_TARBALL = $(DIST_CORE_STAGE_DIR).tar.xz
DIST_CORE_DIRS = 	\
	build-config 	\
	docs	 	\
	patches 	\
	rootconf 	\
	upstream

dist:
	$(Q) echo "=== Making source distriution ==="
	$(Q) mkdir -p $(DIST_DIR) $(DIST_MACHINE_DIR) $(DIST_CORE_STAGE_DIR)
	$(Q) cd $(PROJECTDIR); cp -a $(DIST_CORE_DIRS) $(DIST_CORE_STAGE_DIR)
	$(Q) echo $(LSB_RELEASE_TAG) > $(DIST_CORE_STAGE_DIR)/build-config/conf/lsb-release
	$(Q) tar -C $(DIST_DIR) -cJf $(DIST_CORE_TARBALL) $(DIST_CORE_RELEASE)
	$(Q) rm -rf $(DIST_CORE_STAGE_DIR)
	$(Q) cd $(PROJECTDIR)/machine; for m in $$(ls) ; do \
		echo "   === Adding machine: $$m ==="; \
		tar -C $(PROJECTDIR) -cJf $(DIST_MACHINE_DIR)/onie-$${m}.tar.xz machine/$${m} ; \
	done
	$(Q) echo "=== Finished making distribution $(DIST_CORE_TARBALL)"

.PHONY: $(PHONY)

