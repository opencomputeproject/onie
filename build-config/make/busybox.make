#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Mandeep Sandhu <mandeep.sandhu@cyaninc.com>
#  Copyright (C) 2014 Nikolay Shopik <shopik@inblock.ru>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of busybox
#

BUSYBOX_VERSION		= 1.25.1
BUSYBOX_TARBALL		= busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_TARBALL_URLS	+= $(ONIE_MIRROR) https://www.busybox.net/downloads
BUSYBOX_BUILD_DIR	= $(MBUILDDIR)/busybox
BUSYBOX_DIR		= $(BUSYBOX_BUILD_DIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_CONFIG		?= conf/busybox.config

BUSYBOX_SRCPATCHDIR	= $(PATCHDIR)/busybox
BUSYBOX_PATCHDIR	= $(BUSYBOX_BUILD_DIR)/patch
MACHINE_BUSYBOX_CONFDIR ?= $(MACHINEDIR)/busybox/conf
BUSYBOX_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/busybox-$(BUSYBOX_VERSION)-download
BUSYBOX_SOURCE_STAMP	= $(STAMPDIR)/busybox-source
BUSYBOX_PATCH_STAMP	= $(STAMPDIR)/busybox-patch
BUSYBOX_BUILD_STAMP	= $(STAMPDIR)/busybox-build
BUSYBOX_INSTALL_STAMP	= $(STAMPDIR)/busybox-install
BUSYBOX_STAMP		= $(BUSYBOX_SOURCE_STAMP) \
			  $(BUSYBOX_PATCH_STAMP) \
			  $(BUSYBOX_BUILD_STAMP) \
			  $(BUSYBOX_INSTALL_STAMP)

PHONY += busybox busybox-download busybox-source busybox-config busybox-patch \
	busybox-build busybox-install busybox-clean busybox-download-clean

MACHINE_BUSYBOX_PATCHDIR = $(shell \
			   test -d $(MACHINEDIR)/busybox/patches && \
			   echo "$(MACHINEDIR)/busybox/patches")

ifneq ($(MACHINE_BUSYBOX_PATCHDIR),)
  MACHINE_BUSYBOX_PATCHDIR_FILES = $(MACHINE_BUSYBOX_PATCHDIR)/*
endif

MACHINE_BUSYBOX_CONFIG_FILE = $(shell \
               test -f $(MACHINE_BUSYBOX_CONFDIR)/config && \
               echo "$(MACHINE_BUSYBOX_CONFDIR)/config")

busybox: $(BUSYBOX_STAMP)

DOWNLOAD += $(BUSYBOX_DOWNLOAD_STAMP)
busybox-download: $(BUSYBOX_DOWNLOAD_STAMP)
$(BUSYBOX_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream BusyBox ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(BUSYBOX_TARBALL) $(BUSYBOX_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(BUSYBOX_SOURCE_STAMP)
busybox-source: $(BUSYBOX_SOURCE_STAMP)
$(BUSYBOX_SOURCE_STAMP): $(TREE_STAMP) | $(BUSYBOX_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream BusyBox ===="
	$(Q) $(SCRIPTDIR)/extract-package $(BUSYBOX_BUILD_DIR) $(DOWNLOADDIR)/$(BUSYBOX_TARBALL)
	$(Q) touch $@

busybox-patch: $(BUSYBOX_PATCH_STAMP)
$(BUSYBOX_PATCH_STAMP): $(BUSYBOX_SRCPATCHDIR)/* $(MACHINE_BUSYBOX_PATCHDIR_FILES) $(BUSYBOX_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching Busybox ===="
	$(Q) mkdir -p $(BUSYBOX_PATCHDIR)
	$(Q) cp $(BUSYBOX_SRCPATCHDIR)/* $(BUSYBOX_PATCHDIR)
ifneq ($(MACHINE_BUSYBOX_PATCHDIR),)
	$(Q) [ -r $(MACHINE_BUSYBOX_PATCHDIR)/series ] || \
		(echo "Unable to find machine dependent busybox patch series: $(MACHINE_BUSYBOX_PATCHDIR)/series" && \
		exit 1)
	$(Q) cat $(MACHINE_BUSYBOX_PATCHDIR)/series >> $(BUSYBOX_PATCHDIR)/series
	$(Q) $(SCRIPTDIR)/cp-machine-patches $(BUSYBOX_PATCHDIR) $(MACHINE_BUSYBOX_PATCHDIR)/series	\
		$(MACHINE_BUSYBOX_PATCHDIR) $(MACHINEROOT)/busybox
endif
	$(Q) $(SCRIPTDIR)/apply-patch-series $(BUSYBOX_PATCHDIR)/series $(BUSYBOX_DIR)
	$(Q) touch $@

$(BUSYBOX_DIR)/.config: $(BUSYBOX_CONFIG) $(MACHINE_BUSYBOX_CONFIG_FILE) $(BUSYBOX_PATCH_STAMP)
	$(Q) echo "==== Copying $(BUSYBOX_CONFIG) to $(BUSYBOX_DIR)/.config ===="
	$(Q) cp -v $< $@
ifeq ($(EXT3_4_ENABLE),yes)
	$(Q) sed -i \
		-e '/\bCONFIG_CHATTR\b/c\# CONFIG_CHATTR is not set' \
		-e '/\bCONFIG_LSATTR\b/c\# CONFIG_LSATTR is not set' \
		-e '/\bCONFIG_FSCK\b/c\# CONFIG_FSCK is not set' \
		-e '/\bCONFIG_TUNE2FS\b/c\# CONFIG_TUNE2FS is not set' \
		-e '/\bCONFIG_MKFS_EXT2\b/c\# CONFIG_MKFS_EXT2 is not set' $@
endif
ifeq ($(DOSFSTOOLS_ENABLE),yes)
	$(Q) sed -i \
		-e '/\bCONFIG_MKFS_VFAT\b/c\# CONFIG_MKFS_VFAT is not set' $@
endif
	$(Q) $(SCRIPTDIR)/apply-config-patch $@ $(MACHINE_BUSYBOX_CONFIG_FILE)

busybox-config: $(BUSYBOX_DIR)/.config
	PATH='$(CROSSBIN):$(PATH)' \
		$(MAKE) -C $(BUSYBOX_DIR) CROSS_COMPILE=$(CROSSPREFIX) menuconfig

ifndef MAKE_CLEAN
BUSYBOX_NEW_FILES = $(shell test -d $(BUSYBOX_DIR) && test -f $(BUSYBOX_BUILD_STAMP) && \
	              find -L $(BUSYBOX_DIR) -newer $(BUSYBOX_BUILD_STAMP) \! -name .kernelrelease  \
			\! -name busybox.links -type f -print -quit )
endif

busybox-build: $(BUSYBOX_BUILD_STAMP)
$(BUSYBOX_BUILD_STAMP): $(BUSYBOX_DIR)/.config $(BUSYBOX_NEW_FILES) $(UCLIBC_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building busybox-$(BUSYBOX_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(BUSYBOX_DIR)				\
		CONFIG_SYSROOT=$(DEV_SYSROOT)			\
		CONFIG_EXTRA_CFLAGS="$(ONIE_CFLAGS)"		\
		CONFIG_EXTRA_LDFLAGS="$(ONIE_LDFLAGS)"		\
		CONFIG_PREFIX=$(SYSROOTDIR)			\
		CROSS_COMPILE=$(CROSSPREFIX) V=$(V)
	$(Q) touch $@

busybox-install: $(BUSYBOX_INSTALL_STAMP)
$(BUSYBOX_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(BUSYBOX_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing busybox in $(SYSROOTDIR) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(BUSYBOX_DIR)			\
		CONFIG_SYSROOT=$(DEV_SYSROOT)			\
		CONFIG_EXTRA_CFLAGS="$(ONIE_CFLAGS)"		\
		CONFIG_EXTRA_LDFLAGS="$(ONIE_LDFLAGS)"		\
		CONFIG_PREFIX=$(SYSROOTDIR)			\
		CROSS_COMPILE=$(CROSSPREFIX)			\
		install
	$(Q) chmod 4755 $(SYSROOTDIR)/bin/busybox
	$(Q) touch $@

USERSPACE_CLEAN += busybox-clean
busybox-clean:
	$(Q) rm -rf $(BUSYBOX_BUILD_DIR)
	$(Q) rm -f $(BUSYBOX_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += busybox-download-clean
busybox-download-clean:
	$(Q) rm -f $(BUSYBOX_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(BUSYBOX_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
