#-------------------------------------------------------------------------------
#>
#
#  Copyright (C) 2013,2014,2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014,2015 Carlos Cardenas <carlos@cumulusnetworks.com>
#  Copyright (C) 2014,2017 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Mandeep Sandhu <mandeep.sandhu@cyaninc.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
# Builds the Open Network Install Environment install images
#
# The install image contains:
#
#   install scripts
#   Linux kernel
#   initramfs
#   boot loader specific binaries, like GRUB or U-Boot
#
# The configuration for a specific platform is located in
# ../machine/<vendor>/<platform>
#
# The build specification is in this directory.  The results of the
# build process end up in ../build.  The dependencies follow a source,
# patch, build, install sequence and use stamps to track targets.
#
# When building multiple machines, common components are only built
# once per toolchain.
#
# Typical usage is to checkout a tree and type:
#
#    make MACHINEROOT=../machine/<vendor> MACHINE=<platform> all demo
#
# Note: The directory ../machine/<vendor>/<platform> must exist.
#
# The result of the build creates the following directory tree.
# Platform specific components are in build/<platform>, while common
# components are in build/user/<toolchain>.
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
MACHINEDIR   = $(realpath $(MACHINEROOT)/$(MACHINE))

# Do not pass the MACHINE variable to sub-makes or to the environment.
# Various sub-projects also define and use a variable called MACHINE
# for a completely different purpose.
unexport MACHINE
MAKEOVERRIDES := $(filter-out MACHINE=%,$(MAKEOVERRIDES))

#-------------------------------------------------------------------------------
#
#  machine build tree
#

MBUILDDIR	=  $(BUILDDIR)/$(MACHINE_PREFIX)
STAMPDIR	=  $(MBUILDDIR)/stamp
SYSROOTDIR	=  $(MBUILDDIR)/sysroot
INITRAMFSDIR	=  $(MBUILDDIR)/initramfs

# These directories are needed per machine
TREEDIRS     += $(STAMPDIR) $(STAGE_SYSROOT) $(INITRAMFSDIR)

XTOOLS_ENABLE ?= yes

# List of known ASIC vendors -- keep this list in alphabetical order
KNOWN_ASIC_VENDORS = \
  bcm    \
  bft    \
  cavium \
  centec \
  mlnx   \
  mvl    \
  nephos \
  none   \
  qemu

ifneq (,$(MAKECMDGOALS))
  ifeq (,$(filter onie-release-tag help distclean %build-host, $(MAKECMDGOALS)))
    ifeq ($(wildcard $(MACHINEDIR)/*),)
      $(warning Unable to find machine directory '$(MACHINEDIR)')
      $(warning You must set the MACHINE= variable when invoking make.)
      $(warning You can also set the machine root directory with MACHINEROOT= .)
      $(error Unable to find valid machine configuration directory.)
    endif
    include $(MACHINEDIR)/machine.make

    # Switch ASIC vendor, should be set in machine.make
    SWITCH_ASIC_VENDOR ?= unknown
    ifneq ($(filter-out $(KNOWN_ASIC_VENDORS), $(SWITCH_ASIC_VENDOR)),)
      $(warning Unsupported switch ASIC vendor: $(SWITCH_ASIC_VENDOR))
      $(warning Check the setting of SWITCH_ASIC_VENDOR in machine.make)
      $(error Supported switch ASIC vendors: $(KNOWN_ASIC_VENDORS))
    endif

    ARCHDIR ?= $(realpath ./arch)
    include $(ARCHDIR)/$(ONIE_ARCH).make
  endif
endif

PLATFORM  = $(ARCH)-$(MACHINE_PREFIX)

ifeq ($(UBOOT_ENABLE),yes)
	ROOTFS_ARCH = u-boot-arch
else ifeq ($(GRUB_ENABLE),yes)
	ROOTFS_ARCH = grub-arch
else
	ROOTFS_ARCH = $(ONIE_ARCH)
endif

# Verify partition type
ifneq ($(filter-out gpt msdos, $(PARTITION_TYPE)),)
  $(warning Unsupported partition type: $(PARTITION_TYPE))
  $(error Supported partition types: gpt, msdos)
endif

# Should ONIE skip programming the Ethernet management interface MAC
# addresses?  Can be set to "yes" in machine.make.
SKIP_ETHMGMT_MACS ?= no

ONIE_BUILD_DATE := $(shell LC_ALL=C date -Imin)

TREE_STAMP  = $(STAMPDIR)/tree
tree-stamp: $(TREE_STAMP)
$(TREE_STAMP): $(PROJECT_STAMP)
	$(Q) mkdir -pv $(TREEDIRS)
	$(Q) touch $@

#-------------------------------------------------------------------------------
#
# Determine the final ONIE version string, stored in the variable
# $(LSB_RELEASE_TAG).
#
# This string is constructed from two parts:
#
# Part 1 -- This is the "core ONIE" version string, identifying the
# particular ONIE release.  This string is stored in
# $(ONIE_RELEASE_TAG).
#
# Part 2 -- This optional string contains additional information a
# hardware vendor wants to append to the $(ONIE_RELEASE_TAG) variable.
#
# The $(ONIE_RELEASE_TAG) string is built as follows, in priority
# order:
#
# 1. When running 'make' you can specify the $(ONIE_RELEASE_TAG)
#    variable on the command line.
#
# 2. If the file onie/build-config/local.make exists it can optionally
#    contain a definition of $(ONIE_RELEASE_TAG).  See the comments in
#    that file for more details on how to use local.make.
#
# 3. If the file onie/build-config/conf/onie-release exists then use
#    the contents of that file.  The quarterly release branches of
#    ONIE use this method, i.e. the branch contains the file
#    onie/build-config/conf/onie-release.
#
#    Note: The development master branch does not contain this file.
#
# 4. During development $(ONIE_RELEASE_TAG) is constructed from the
#    current branch name and the current build date.
#
# To form the final version string, $(LSB_RELEASE_TAG), the following
# strings are appended to $(ONIE_RELEASE_TAG).
#
# 1. The value of $(VENDOR_VERSION) is appended to
#    $(ONIE_RELEASE_TAG).  This allows hardware vendors to apply their
#    own versioning information to each machine.
#
# 2. If the current branch has uncommitted files then the string
#    "-dirty" is appended to the final string.

ONIE_RELEASE_TAG	?= $(shell [ -r ./conf/onie-release ] && cat ./conf/onie-release)
ifeq ($(ONIE_RELEASE_TAG),)
  GIT_BRANCH = $(shell cd $(MACHINEDIR) && git rev-parse --abbrev-ref HEAD)
  BUILD_DATE = $(shell date +%Y%m%d%H%M)
  ifneq ($(RELEASE),)
    # Optional: If RELEASE specified on the command line insert the
    # string after the branch name.
    ONIE_RELEASE_TAG = $(GIT_BRANCH)-$(RELEASE)-$(BUILD_DATE)
  else
    ONIE_RELEASE_TAG = $(GIT_BRANCH)-$(BUILD_DATE)
  endif
endif
DIRTY  = $(shell cd $(MACHINEDIR) && git status | \
		egrep -q '(Your branch is ahead|modified:|Untracked files:)' && echo -dirty)
LSB_RELEASE_TAG := $(ONIE_RELEASE_TAG)$(VENDOR_VERSION)$(DIRTY)
export LSB_RELEASE_TAG

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

# By default do not enable secure boot
SECURE_BOOT_ENABLE ?= no
ifeq ($(SECURE_BOOT_ENABLE),yes)
  PESIGN_ENABLE = yes
  GNU_EFI_ENABLE = yes
  OPENSSL_ENABLE = yes
  MOKUTIL_ENABLE = yes
  SHIM_ENABLE = yes
  KEYUTILS_ENABLE = yes
endif

include make/kernel-download.make
ifeq ($(XTOOLS_ENABLE),yes)
  include make/crosstool-ng.make
  ifneq ($(XTOOLS_LIBC),glibc)
    include make/uclibc-download.make
  endif
  include make/xtools.make
endif
include make/sysroot.make
ifeq ($(GNU_EFI_ENABLE),yes)
  include make/gnu-efi.make
endif
include make/kernel.make
ifeq ($(UBOOT_ENABLE),yes)
  include make/u-boot.make
endif
include make/compiler.make
include make/busybox.make
include make/zlib.make
include make/lzo.make
include make/util-linux.make
ifeq ($(MTDUTILS_ENABLE),yes)
  include make/mtdutils.make
endif
include make/dropbear.make
ifeq ($(EXT3_4_ENABLE),yes)
  include make/e2fsprogs.make
endif
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
ifeq ($(BTRFS_PROGS_ENABLE),yes)
  include make/btrfs-progs.make
endif
ifeq ($(UEFI_ENABLE),yes)
  include make/efivar.make
  include make/efibootmgr.make
endif
ifeq ($(I2CTOOLS_SYSEEPROM),yes)
  include make/i2ctools.make
endif
ifeq ($(DMIDECODE_ENABLE),yes)
  include make/dmidecode.make
endif
ifeq ($(ETHTOOL_ENABLE),yes)
  include make/ethtool.make
endif
ifeq ($(MTREE_ENABLE),yes)
  include make/mtree.make
endif
ifeq ($(ACPI_ENABLE),yes)
  include make/acpica-tools.make
endif
ifeq ($(DOSFSTOOLS_ENABLE),yes)
  include make/dosfstools.make
endif
ifeq ($(KEXEC_ENABLE),yes)
  include make/kexec-tools.make
endif
ifeq ($(FLASHROM_ENABLE),yes)
  include make/pciutils.make
  include make/flashrom.make
endif
ifeq ($(IPMITOOL_ENABLE),yes)
  include make/ipmitool.make
endif
ifeq ($(PESIGN_ENABLE),yes)
  include make/pesign.make
endif
ifeq ($(OPENSSL_ENABLE),yes)
  include make/openssl.make
endif
ifeq ($(MOKUTIL_ENABLE),yes)
  include make/mokutil.make
endif
ifeq ($(SHIM_ENABLE),yes)
  include make/shim.make
endif
ifeq ($(KEYUTILS_ENABLE),yes)
  include make/keyutils.make
endif
include make/images.make
include make/demo.make

# By default do not enable building firmware updates
FIRMWARE_UPDATE_ENABLE ?= no
ifeq ($(FIRMWARE_UPDATE_ENABLE),yes)
  include make/firmware-update.make
endif


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

PHONY += all
all: $(KERNEL) $(UBOOT) $(SYSROOT) $(IMAGE)
	$(Q) echo "=== Finished making onie-$(PLATFORM) $(LSB_RELEASE_TAG) ==="

PHONY += demo
demo: $(KERNEL) $(DEMO_IMAGE)
	$(Q) echo "=== Finished making demo onie-$(PLATFORM) $(LSB_RELEASE_TAG) ==="

PHONY += machine-clean
machine-clean: $(MACHINE_CLEAN)
	$(Q) rm -rf $(BUILDDIR)/images/*$(MACHINE_PREFIX)*
	$(Q) rm -rf $(MBUILDDIR)
	$(Q) echo "=== Finished making $@ ==="

PHONY += clean
clean: 	machine-clean
	$(Q) echo "=== Finished making $@ for $(PLATFORM) ==="

PHONY += user-clean
user-clean: machine-clean $(USER_CLEAN)
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

PHONY += onie-release-tag
onie-release-tag:
	$(Q) echo $(ONIE_RELEASE_TAG)

PHONY += lsb-release-tag
lsb-release-tag:
	$(Q) echo $(LSB_RELEASE_TAG)

PHONY += machine-prefix
machine-prefix:
	$(Q) echo $(MACHINE_PREFIX)

# Install required build packages for a x86_64 debian based build host
DEBIAN_BUILD_HOST_PACKAGES	= build-essential stgit u-boot-tools util-linux \
				  gperf device-tree-compiler python-all-dev xorriso \
				  autoconf automake bison flex texinfo libtool libtool-bin \
				  realpath gawk libncurses5 libncurses5-dev bc \
				  dosfstools mtools pkg-config git wget help2man libexpat1 \
				  libexpat1-dev fakeroot python-sphinx rst2pdf \
				  libefivar-dev libnss3-tools libnss3-dev libpopt-dev \
				  libssl-dev sbsigntool uuid-runtime uuid-dev cpio \
				  bsdmainutils

PHONY += debian-prepare-build-host
debian-prepare-build-host:
	$(Q) sudo apt-get update
	$(Q) sudo apt-get install -y $(DEBIAN_BUILD_HOST_PACKAGES)

PHONY += ldd

# Run the cross ldd for the target platform
ifeq ($(word 1, $(MAKECMDGOALS)),ldd)
  ifeq ($(LDD_TARGET),)
    $(error "When using the `ldd' target you must also set the LDD_TARGET variable")
  endif
  LDD_FILE := $(SYSROOTDIR)/$(LDD_TARGET)
endif

ldd:
	$(Q) [ -e $(LDD_FILE) ]
	$(Q) echo "Running cross-ldd on file: $(LDD_FILE)"
	$(Q) echo "Using SYSROOT directory  : $(SYSROOT)"
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(CROSSBIN)/$(CROSSPREFIX)ldd --root $(SYSROOTDIR) $(LDD_FILE)

.PHONY: $(PHONY)
