#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of rsync
#

include make/openssl.make
include make/popt.make

RSYNC_VERSION		= 3.3.0
RSYNC_TARBALL		= rsync-$(RSYNC_VERSION).tar.gz
RSYNC_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://download.samba.org/pub/rsync/src
RSYNC_BUILD_DIR		=  $(USER_BUILDDIR)/rsync
RSYNC_DIR		=  $(RSYNC_BUILD_DIR)/rsync-$(RSYNC_VERSION)

RSYNC_SRCPATCHDIR	= $(PATCHDIR)/rsync
RSYNC_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/rsync-download
RSYNC_SOURCE_STAMP	= $(USER_STAMPDIR)/rsync-source
RSYNC_PATCH_STAMP	= $(USER_STAMPDIR)/rsync-patch
RSYNC_CONFIGURE_STAMP	= $(USER_STAMPDIR)/rsync-configure
RSYNC_BUILD_STAMP	= $(USER_STAMPDIR)/rsync-build
RSYNC_INSTALL_STAMP	= $(STAMPDIR)/rsync-install
RSYNC_STAMP		= $(RSYNC_DOWNLOAD_STAMP) \
			  $(RSYNC_SOURCE_STAMP) \
			  $(RSYNC_PATCH_STAMP) \
			  $(RSYNC_CONFIGURE_STAMP) \
			  $(RSYNC_BUILD_STAMP) \
			  $(RSYNC_INSTALL_STAMP)

PHONY += rsync \
	 rsync-download \
	 rsync-source \
	 rsync-patch \
	 rsync-configure \
	 rsync-build \
	 rsync-install \
	 rsync-clean \
	 rsync-download-clean

rsync: $(RSYNC_STAMP)

DOWNLOAD += $(RSYNC_DOWNLOAD_STAMP)

rsync-download: $(RSYNC_DOWNLOAD_STAMP)
$(RSYNC_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream rsync ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(RSYNC_TARBALL) $(RSYNC_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(RSYNC_SOURCE_STAMP)

rsync-source: $(RSYNC_SOURCE_STAMP)
$(RSYNC_SOURCE_STAMP): $(USER_TREE_STAMP) | $(RSYNC_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream rsync ===="
	$(Q) $(SCRIPTDIR)/extract-package $(RSYNC_BUILD_DIR) $(DOWNLOADDIR)/$(RSYNC_TARBALL)
	$(Q) touch $@

rsync-patch: $(RSYNC_PATCH_STAMP)
$(RSYNC_PATCH_STAMP): $(RSYNC_SRCPATCHDIR)/* $(RSYNC_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching rsync ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(RSYNC_SRCPATCHDIR)/series $(RSYNC_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
RSYNC_NEW_FILES = $( \
			shell test -d $(RSYNC_DIR) && \
			test -f $(RSYNC_BUILD_STAMP) && \
			find -L $(RSYNC_DIR) -newer $(RSYNC_BUILD_STAMP) -type f -print -quit \
		)
endif

rsync-configure: $(RSYNC_CONFIGURE_STAMP)
$(RSYNC_CONFIGURE_STAMP): $(RSYNC_PATCH_STAMP) $(OPENSSL_INSTALL_STAMP) $(POPT_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure rsync-$(RSYNC_VERSION) ===="
	$(Q) cd $(RSYNC_DIR) &&		\
		$(RSYNC_DIR)/configure	\
		--host=$(TARGET)	\
		--prefix=/usr		\
		--disable-xxhash	\
		--disable-zstd		\
		--disable-lz4
	$(Q) touch $@

rsync-build: $(RSYNC_BUILD_STAMP)
$(RSYNC_BUILD_STAMP): $(RSYNC_CONFIGURE_STAMP) $(RSYNC_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building rsync-$(RSYNC_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'					\
		$(MAKE) -C $(RSYNC_DIR)					\
		CC=$(CROSSPREFIX)gcc					\
		CFLAGS="$(ONIE_CFLAGS) -I $(DEV_SYSROOT)/usr/include"
	$(Q) PATH='$(CROSSBIN):$(PATH)'					\
		$(MAKE) -C $(RSYNC_DIR) install DESTDIR=$(DEV_SYSROOT)	\
		CC=$(CROSSPREFIX)gcc
	$(Q) touch $@

rsync-install: $(RSYNC_INSTALL_STAMP)
$(RSYNC_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(RSYNC_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing rsync in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av $(DEV_SYSROOT)/usr/bin/rsync $(SYSROOTDIR)/usr/bin/
	$(Q) touch $@

USER_CLEAN += rsync-clean
rsync-clean:
	$(Q) rm -rf $(RSYNC_BUILD_DIR)
	$(Q) rm -f $(RSYNC_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += rsync-download-clean
rsync-download-clean:
	$(Q) rm -f $(RSYNC_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(RSYNC_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
