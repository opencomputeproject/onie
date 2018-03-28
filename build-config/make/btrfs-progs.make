#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of btrfs-progs
#

BTRFSPROGS_VERSION		= v4.3.1
BTRFSPROGS_TARBALL		= btrfs-progs-$(BTRFSPROGS_VERSION).tar.xz
BTRFSPROGS_TARBALL_URLS		+= $(ONIE_MIRROR) \
				   https://www.kernel.org/pub/linux/kernel/people/kdave/btrfs-progs
BTRFSPROGS_BUILD_DIR		= $(USER_BUILDDIR)/btrfs-progs
BTRFSPROGS_DIR			= $(BTRFSPROGS_BUILD_DIR)/btrfs-progs-$(BTRFSPROGS_VERSION)

BTRFSPROGS_SRCPATCHDIR		= $(PATCHDIR)/btrfs-progs
BTRFSPROGS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/btrfs-progs-download
BTRFSPROGS_SOURCE_STAMP		= $(USER_STAMPDIR)/btrfs-progs-source
BTRFSPROGS_PATCH_STAMP		= $(USER_STAMPDIR)/btrfs-progs-patch
BTRFSPROGS_CONFIGURE_STAMP	= $(USER_STAMPDIR)/btrfs-progs-configure
BTRFSPROGS_BUILD_STAMP		= $(USER_STAMPDIR)/btrfs-progs-build
BTRFSPROGS_INSTALL_STAMP	= $(STAMPDIR)/btrfs-progs-install
BTRFSPROGS_STAMP		= $(BTRFSPROGS_SOURCE_STAMP) \
				  $(BTRFSPROGS_PATCH_STAMP) \
				  $(BTRFSPROGS_CONFIGURE_STAMP) \
				  $(BTRFSPROGS_BUILD_STAMP) \
				  $(BTRFSPROGS_INSTALL_STAMP)

ifneq ($(EXT3_4_ENABLE),yes)
  $(error BTRFS tools requires EXT3/4 support, but $$(EXT3_4_ENABLE) is not set)
endif

PHONY += btrfs-progs btrfs-progs-download btrfs-progs-source \
	 btrfs-progs-configure btrfs-progs-build btrfs-progs-install \
	 btrfs-progs-clean btrfs-progs-download-clean

BTRFSPROGS_LIBS = libbtrfs.so libbtrfs.so.0 libbtrfs.so.0.1
BTRFSPROGS_SBIN = btrfs mkfs.btrfs btrfs-debug-tree btrfs-map-logical \
		  btrfs-image btrfs-zero-log btrfs-find-root btrfstune \
		  btrfs-show-super btrfs-select-super btrfs-convert \
		  btrfsck

btrfs-progs: $(BTRFSPROGS_STAMP)

DOWNLOAD += $(BTRFSPROGS_DOWNLOAD_STAMP)
btrfs-progs-download: $(BTRFSPROGS_DOWNLOAD_STAMP)
$(BTRFSPROGS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream btrfs-progs ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(BTRFSPROGS_TARBALL) $(BTRFSPROGS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(BTRFSPROGS_SOURCE_STAMP)
btrfs-progs-source: $(BTRFSPROGS_SOURCE_STAMP)
$(BTRFSPROGS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(BTRFSPROGS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream btrfs-progs ===="
	$(Q) $(SCRIPTDIR)/extract-package $(BTRFSPROGS_BUILD_DIR) $(DOWNLOADDIR)/$(BTRFSPROGS_TARBALL)
	$(Q) touch $@

btrfs-progs-patch: $(BTRFSPROGS_PATCH_STAMP)
$(BTRFSPROGS_PATCH_STAMP): $(BTRFSPROGS_SRCPATCHDIR)/* $(BTRFSPROGS_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching btrfs-progs ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(BTRFSPROGS_SRCPATCHDIR)/series $(BTRFSPROGS_DIR)
	$(Q) touch $@

btrfs-progs-configure: $(BTRFSPROGS_CONFIGURE_STAMP)
$(BTRFSPROGS_CONFIGURE_STAMP): $(E2FSPROGS_BUILD_STAMP) \
			      $(BTRFSPROGS_PATCH_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure btrfs-progs-$(BTRFSPROGS_VERSION) ===="
	$(Q) cd $(BTRFSPROGS_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(BTRFSPROGS_DIR)/configure			\
		--prefix=/usr					\
		--host=$(TARGET)				\
		--disable-documentation				\
		--disable-backtrace				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"				\
		$(ONIE_PKG_CONFIG)
	$(Q) touch $@

ifndef MAKE_CLEAN
BTRFSPROGS_NEW_FILES = $(shell test -d $(BTRFSPROGS_DIR) && test -f $(BTRFSPROGS_BUILD_STAMP) && \
	              find -L $(BTRFSPROGS_DIR) -newer $(BTRFSPROGS_BUILD_STAMP) -type f \
			-print -quit)
endif

btrfs-progs-build: $(BTRFSPROGS_BUILD_STAMP)
$(BTRFSPROGS_BUILD_STAMP): $(BTRFSPROGS_NEW_FILES) $(BTRFSPROGS_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building btrfs-progs-$(BTRFSPROGS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(BTRFSPROGS_DIR) DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(BTRFSPROGS_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

btrfs-progs-install: $(BTRFSPROGS_INSTALL_STAMP)
$(BTRFSPROGS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(BTRFSPROGS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing btrfs-progs in $(SYSROOTDIR) ===="
	$(Q) for file in $(BTRFSPROGS_LIBS) ; do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	     done
	$(Q) for file in $(BTRFSPROGS_SBIN) ; do \
		cp -av $(DEV_SYSROOT)/usr/bin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
	     done
	$(Q) touch $@

USER_CLEAN += btrfs-progs-clean
btrfs-progs-clean:
	$(Q) rm -rf $(BTRFSPROGS_BUILD_DIR)
	$(Q) rm -f $(BTRFSPROGS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += btrfs-progs-download-clean
btrfs-progs-download-clean:
	$(Q) rm -f $(BTRFSPROGS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/btrfs-progs*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
