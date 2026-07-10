#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of mtdutils
#

MTDUTILS_VERSION	= 2.3.1
MTDUTILS_TARBALL	= mtd-utils-$(MTDUTILS_VERSION).tar.bz2
MTDUTILS_TARBALL_URLS	+= $(ONIE_MIRROR) https://infraroot.at/pub/mtd
MTDUTILS_BUILD_DIR	= $(USER_BUILDDIR)/mtd-utils
MTDUTILS_DIR		= $(MTDUTILS_BUILD_DIR)/mtd-utils-$(MTDUTILS_VERSION)

MTDUTILS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/mtdutils-$(MTDUTILS_VERSION)-download
MTDUTILS_SOURCE_STAMP	= $(USER_STAMPDIR)/mtdutils-source
MTDUTILS_CONFIGURE_STAMP	= $(USER_STAMPDIR)/mtdutils-configure
MTDUTILS_BUILD_STAMP	= $(USER_STAMPDIR)/mtdutils-build
MTDUTILS_INSTALL_STAMP	= $(STAMPDIR)/mtdutils-install
MTDUTILS_STAMP		= $(MTDUTILS_SOURCE_STAMP) \
			  $(MTDUTILS_CONFIGURE_STAMP) \
			  $(MTDUTILS_BUILD_STAMP) \
			  $(MTDUTILS_INSTALL_STAMP)

MTDBINS = mkfs.jffs2 mkfs.ubifs ubinize ubiformat ubinfo mtdinfo
UBIBINS = ubiattach ubimkvol ubidetach ubirmvol

PHONY += mtdutils mtdutils-download mtdutils-source mtdutils-configure \
	 mtdutils-build mtdutils-install mtdutils-clean mtdutils-download-clean \
	 mtdutils-configure-help

mtdutils: $(MTDUTILS_STAMP)

DOWNLOAD += $(MTDUTILS_DOWNLOAD_STAMP)
mtdutils-download: $(MTDUTILS_DOWNLOAD_STAMP)
$(MTDUTILS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream mtdutils ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(MTDUTILS_TARBALL) $(MTDUTILS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(MTDUTILS_SOURCE_STAMP)
mtdutils-source: $(MTDUTILS_SOURCE_STAMP)
$(MTDUTILS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(MTDUTILS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream mtdutils ===="
	$(Q) $(SCRIPTDIR)/extract-package $(MTDUTILS_BUILD_DIR) $(DOWNLOADDIR)/$(MTDUTILS_TARBALL)
	$(Q) touch $@

mtdutils-configure-help: $(UTILLINUX_BUILD_STAMP) $(LZO_BUILD_STAMP) \
				$(ZLIB_BUILD_STAMP) \
				$(MTDUTILS_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) echo "====  Configure help for mtd-utils-$(MTDUTILS_VERSION) ===="
	$(Q) cd $(MTDUTILS_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(MTDUTILS_DIR)/configure --help

# mtd-utils 2.x uses an autotools (./configure) build.
#
# Optional dependencies:
#   - zlib, lzo, libuuid (util-linux) are provided by ONIE and enabled
#     (UBIFS/JFFS2 support).
#   - crypto (UBIFS authentication) is disabled: ONIE does not need it and
#     the prior 1.5.2 build did not use it.
#   - zstd is NOT provided by ONIE, so ZSTD compression is disabled.
#   - selinux is NOT provided by ONIE, so SELinux support is disabled.
#   - xattr is disabled to match the prior 1.5.2 build (WITHOUT_XATTR=1).
#   - The unit/test programs are disabled (--without-tests); they are not
#     installed and pull in extra dependencies (pthread, clock_gettime).
mtdutils-configure: $(MTDUTILS_CONFIGURE_STAMP)
$(MTDUTILS_CONFIGURE_STAMP): $(UTILLINUX_BUILD_STAMP) $(LZO_BUILD_STAMP) \
				$(ZLIB_BUILD_STAMP) \
				$(MTDUTILS_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure mtd-utils-$(MTDUTILS_VERSION) ===="
	$(Q) cd $(MTDUTILS_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(MTDUTILS_DIR)/configure			\
		--prefix=/usr					\
		--host=$(TARGET)				\
		--with-zlib					\
		--with-lzo					\
		--with-ubifs					\
		--with-jffs					\
		--without-crypto				\
		--without-zstd					\
		--without-xattr					\
		--without-selinux				\
		--without-tests					\
		--without-lsmtd					\
		--disable-unit-tests				\
		--disable-ubihealthd				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"			\
		$(ONIE_PKG_CONFIG)
	$(Q) touch $@

ifndef MAKE_CLEAN
MTDUTILS_NEW_FILES = $(shell test -d $(MTDUTILS_DIR) && test -f $(MTDUTILS_BUILD_STAMP) && \
		      find -L $(MTDUTILS_DIR) -newer $(MTDUTILS_BUILD_STAMP) -type f -print -quit)
endif

mtdutils-build: $(MTDUTILS_BUILD_STAMP)
$(MTDUTILS_BUILD_STAMP): $(MTDUTILS_NEW_FILES) $(MTDUTILS_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building mtd-utils-$(MTDUTILS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(MTDUTILS_DIR) DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(MTDUTILS_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

mtdutils-install: $(MTDUTILS_INSTALL_STAMP)
$(MTDUTILS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(MTDUTILS_BUILD_STAMP) $(UTILLINUX_INSTALL_STAMP) \
				$(LZO_INSTALL_STAMP) $(ZLIB_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing mtdutils in $(SYSROOTDIR) ===="
	$(Q) for file in $(MTDBINS) ; do \
		cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
	done
        #if UBI utils from busybox are not installed, use the mtdtools versions
	$(Q) for file in $(UBIBINS) ; do \
		if [ ! -f $(SYSROOTDIR)/usr/sbin/$$file ] ; \
		then \
			cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
		fi; \
	done
	$(Q) touch $@

USER_CLEAN += mtdutils-clean
mtdutils-clean:
	$(Q) rm -rf $(MTDUTILS_BUILD_DIR)
	$(Q) rm -f $(MTDUTILS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += mtdutils-download-clean
mtdutils-download-clean:
	$(Q) rm -f $(MTDUTILS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(MTDUTILS_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
