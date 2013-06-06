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
  GIT_HEAD = $(shell git show --abbrev-commit HEAD | sed -ne "/^commit [0-9a-f]*/s/^commit //p")
  ifeq (1, $(RELEASE))
    LSB_RELEASE_TAG = $(RELEASE_VERSION)
  else ifneq ($(RELEASE),NB)
    LSB_RELEASE_TAG = $(RELEASE_VERSION)-$(GIT_HEAD)-$(RELEASE)
  else
    BUILD_DATE = $(shell date +%Y%m%d%H%M)
    LSB_RELEASE_TAG = $(RELEASE_VERSION)-$(GIT_HEAD)-$(BUILD_DATE)-$(RELEASE)
  endif
  DIRTY  = $(shell git status | egrep -q '(Your branch is ahead|modified:|Untracked files:)' && echo dirty)
  ifneq ($(DIRTY),)
    LSB_RELEASE_TAG := $(LSB_RELEASE_TAG)-$(DIRTY)
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

ifneq (,$(MAKECMDGOALS))
  ifeq (,$(filter help clean-all dist %build-host doc% %html %pdf, $(MAKECMDGOALS)))
    ifeq ($(wildcard $(MACHINEDIR)/*),)
      $(warning Unable to find machine directory '$(MACHINE)' in $(MACHINEROOT))
      $(warning You must set the MACHINE= variable when invoking make.)
      $(warning You can also set the machine root directory with MACHINEROOT= .)
      $(error Unable to find valid machine configuration directory.)
    endif
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
	$(Q) sudo rm -rf $(BUILDDIR)/images/*$(MACHINE)*
	$(Q) sudo rm -rf $(MBUILDDIR)
	$(Q) echo "=== Finished making $@ for $(PLATFORM) ==="

clean-all:
	$(Q) sudo rm -rf $(BUILDDIR)/*
	$(Q) echo "=== Finished making $@ ==="

PHONY += dist
DIST_DIR		= $(BUILDDIR)/dist
DIST_MACHINE_DIR	= $(DIST_DIR)/machine
DIST_DOCS_DIR		= $(DIST_DIR)/docs
DIST_CORE_RELEASE	= onie-core-$(LSB_RELEASE_TAG)
DIST_CORE_STAGE_DIR	= $(DIST_DIR)/$(DIST_CORE_RELEASE)
DIST_CORE_TARBALL	= $(DIST_CORE_STAGE_DIR).tar.xz
DIST_TAR_OPTIONS	= --exclude-backups --exclude=*~
DIST_CORE_DIRS = 	\
	build-config 	\
	demo		\
	installer	\
	patches 	\
	rootconf 	\
	upstream

source_is_clean:
	$(Q) [ "$(RELEASE)" != "NB" ] || ( echo "Error: Lame distribution RELEASE tag: $(RELEASE)" && false )
	$(Q) [ "$(DIRTY)" = "" ] || ( echo "Error: Dirty Source -- uncommited files" && git status && false )

dist: source_is_clean html pdf
	$(Q) echo "=== Making $(LSB_RELEASE_TAG) source distriution ==="
	$(Q) rm -rf $(DIST_DIR)
	$(Q) mkdir -p $(DIST_DIR) $(DIST_MACHINE_DIR) $(DIST_CORE_STAGE_DIR) $(DIST_DOCS_DIR)
	$(Q) cd $(PROJECTDIR); cp -a $(DIST_CORE_DIRS) $(DIST_CORE_STAGE_DIR)
	$(Q) echo $(LSB_RELEASE_TAG) > $(DIST_CORE_STAGE_DIR)/build-config/conf/lsb-release
	$(Q) tar $(DIST_TAR_OPTIONS) -C $(DIST_DIR) -cJf $(DIST_CORE_TARBALL) $(DIST_CORE_RELEASE)
	$(Q) rm -rf $(DIST_CORE_STAGE_DIR)
	$(Q) cd $(PROJECTDIR)/machine; for m in $$(ls) ; do \
		echo "   === Adding machine: $$m ==="; \
		tar $(DIST_TAR_OPTIONS) -C $(PROJECTDIR) -cJf $(DIST_MACHINE_DIR)/onie-$${m}-$(LSB_RELEASE_TAG).tar.xz machine/$${m} ; \
	done
	$(Q) echo $(LSB_RELEASE_TAG) > $(DIST_DIR)/VERSION
	$(Q) cp -a $(DOCBUILDDIR)/{html,pdf} $(DIST_DOCS_DIR)
	$(Q) echo "=== Finished making distribution $(DIST_CORE_TARBALL)"

# Install required build packages for a debian based build host
DEBIAN_BUILD_HOST_PACKAGES	= build-essential stgit u-boot-tools python-sphinx rst2pdf
PHONY += debian-prepare-build-host
debian-prepare-build-host:
	$(Q) sudo apt-get update
	$(Q) sudo apt-get install $(DEBIAN_BUILD_HOST_PACKAGES)

.PHONY: $(PHONY)
