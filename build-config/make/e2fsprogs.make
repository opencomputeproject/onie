#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of e2fsprogs
#

E2FSPROGS_VERSION		= 1.42.8
E2FSPROGS_TARBALL		= e2fsprogs-$(E2FSPROGS_VERSION).tar.xz
E2FSPROGS_TARBALL_URLS		+= $(ONIE_MIRROR) \
				   https://www.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.42.8
E2FSPROGS_BUILD_DIR		= $(MBUILDDIR)/e2fsprogs
E2FSPROGS_DIR			= $(E2FSPROGS_BUILD_DIR)/e2fsprogs-$(E2FSPROGS_VERSION)

E2FSPROGS_SRCPATCHDIR		= $(PATCHDIR)/e2fsprogs
E2FSPROGS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/e2fsprogs-download
E2FSPROGS_SOURCE_STAMP		= $(STAMPDIR)/e2fsprogs-source
E2FSPROGS_PATCH_STAMP		= $(STAMPDIR)/e2fsprogs-patch
E2FSPROGS_CONFIGURE_STAMP	= $(STAMPDIR)/e2fsprogs-configure
E2FSPROGS_BUILD_STAMP		= $(STAMPDIR)/e2fsprogs-build
E2FSPROGS_INSTALL_STAMP		= $(STAMPDIR)/e2fsprogs-install
E2FSPROGS_STAMP			= $(E2FSPROGS_SOURCE_STAMP) \
				  $(E2FSPROGS_PATCH_STAMP) \
				  $(E2FSPROGS_CONFIGURE_STAMP) \
				  $(E2FSPROGS_BUILD_STAMP) \
				  $(E2FSPROGS_INSTALL_STAMP)

PHONY += e2fsprogs e2fsprogs-download e2fsprogs-source e2fsprogs-patch \
	 e2fsprogs-configure e2fsprogs-build e2fsprogs-install e2fsprogs-clean \
	 e2fsprogs-download-clean

E2FSPROGS_LIB_DIRS	= uuid
E2FSPROGS_LIBS	= \
	libuuid.so    libuuid.so.1    libuuid.so.1.2

ifeq ($(EXT3_4_ENABLE),yes)
E2FSPROGS_LIB_DIRS	+= et e2p blkid ext2fs blkid
E2FSPROGS_LIBS += \
	libcom_err.so libcom_err.so.2 libcom_err.so.2.1 \
	libe2p.so     libe2p.so.2     libe2p.so.2.3     \
	libblkid.so   libblkid.so.1   libblkid.so.1.0   \
	libext2fs.so  libext2fs.so.2  libext2fs.so.2.4
endif

e2fsprogs: $(E2FSPROGS_STAMP)

DOWNLOAD += $(E2FSPROGS_DOWNLOAD_STAMP)
e2fsprogs-download: $(E2FSPROGS_DOWNLOAD_STAMP)
$(E2FSPROGS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream e2fsprogs ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(E2FSPROGS_TARBALL) $(E2FSPROGS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(E2FSPROGS_SOURCE_STAMP)
e2fsprogs-source: $(E2FSPROGS_SOURCE_STAMP)
$(E2FSPROGS_SOURCE_STAMP): $(TREE_STAMP) | $(E2FSPROGS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream e2fsprogs ===="
	$(Q) $(SCRIPTDIR)/extract-package $(E2FSPROGS_BUILD_DIR) $(DOWNLOADDIR)/$(E2FSPROGS_TARBALL)
	$(Q) touch $@

e2fsprogs-patch: $(E2FSPROGS_PATCH_STAMP)
$(E2FSPROGS_PATCH_STAMP): $(E2FSPROGS_SRCPATCHDIR)/* $(E2FSPROGS_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching e2fsprogs ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(E2FSPROGS_SRCPATCHDIR)/series $(E2FSPROGS_DIR)
	$(Q) touch $@

e2fsprogs-configure: $(E2FSPROGS_CONFIGURE_STAMP)
$(E2FSPROGS_CONFIGURE_STAMP): $(ZLIB_INSTALL_STAMP) $(LZO_INSTALL_STAMP) \
			      $(E2FSPROGS_PATCH_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure e2fsprogs-$(E2FSPROGS_VERSION) ===="
	$(Q) cd $(E2FSPROGS_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(E2FSPROGS_DIR)/configure			\
		--enable-elf-shlibs				\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET)				\
		--disable-tls					\
		--disable-defrag				\
		--enable-symlink-build				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"
	$(Q) touch $@

ifndef MAKE_CLEAN
E2FSPROGS_NEW_FILES = $(shell test -d $(E2FSPROGS_DIR) && test -f $(E2FSPROGS_BUILD_STAMP) && \
	              find -L $(E2FSPROGS_DIR) -newer $(E2FSPROGS_BUILD_STAMP) -type f \
			\! -name symlinks \! -name symlinks.o -print -quit)
endif

e2fsprogs-build: $(E2FSPROGS_BUILD_STAMP)
$(E2FSPROGS_BUILD_STAMP): $(E2FSPROGS_NEW_FILES) $(E2FSPROGS_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building e2fsprogs-$(E2FSPROGS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(E2FSPROGS_DIR)
	$(Q) touch $@

e2fsprogs-install: $(E2FSPROGS_INSTALL_STAMP)
$(E2FSPROGS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(E2FSPROGS_BUILD_STAMP) $(BUSYBOX_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing e2fsprogs in $(DEV_SYSROOT) ===="
	$(Q) for dir in $(E2FSPROGS_LIB_DIRS) ; do \
		PATH='$(CROSSBIN):$(PATH)' \
			$(MAKE) -C $(E2FSPROGS_DIR)/lib/$$dir install ; \
	     done
	$(Q) for file in $(E2FSPROGS_LIBS) ; do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	     done
ifeq ($(EXT3_4_ENABLE),yes)
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(E2FSPROGS_DIR)/misc install
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(E2FSPROGS_DIR)/e2fsck install
	$(Q) cp -av $(DEV_SYSROOT)/usr/sbin/{mke2fs,tune2fs} $(SYSROOTDIR)/usr/sbin/
	$(Q) cp -av $(DEV_SYSROOT)/usr/bin/{chattr,lsattr} $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av $(DEV_SYSROOT)/usr/sbin/{e2fsck,fsck} $(SYSROOTDIR)/usr/sbin/
	$(Q) ln -sf mke2fs $(SYSROOTDIR)/usr/sbin/mkfs.ext2
	$(Q) ln -sf mke2fs $(SYSROOTDIR)/usr/sbin/mkfs.ext3
	$(Q) ln -sf mke2fs $(SYSROOTDIR)/usr/sbin/mkfs.ext4
	$(Q) ln -sf e2fsck $(SYSROOTDIR)/usr/sbin/fsck.ext2
	$(Q) ln -sf e2fsck $(SYSROOTDIR)/usr/sbin/fsck.ext3
	$(Q) ln -sf e2fsck $(SYSROOTDIR)/usr/sbin/fsck.ext4
endif
	$(Q) touch $@

USERSPACE_CLEAN += e2fsprogs-clean
e2fsprogs-clean:
	$(Q) rm -rf $(E2FSPROGS_BUILD_DIR)
	$(Q) rm -f $(E2FSPROGS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += e2fsprogs-download-clean
e2fsprogs-download-clean:
	$(Q) rm -f $(E2FSPROGS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/e2fsprogs*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
