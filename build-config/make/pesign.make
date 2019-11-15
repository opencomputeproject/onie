#-------------------------------------------------------------------------------
#
#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of pesign
#

PESIGN_VERSION			= 0.112
PESIGN_TARBALL			= pesign-$(PESIGN_VERSION).tar.bz2
PESIGN_TARBALL_URLS		+= $(ONIE_MIRROR) https://github.com/rhinstaller/pesign/releases/download/$(PESIGN_VERSION)
PESIGN_BUILD_DIR		= $(USER_BUILDDIR)/pesign
PESIGN_DIR			= $(PESIGN_BUILD_DIR)/pesign-$(PESIGN_VERSION)

PESIGN_SRCPATCHDIR		= $(PATCHDIR)/pesign
PESIGN_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/pesign-download
PESIGN_SOURCE_STAMP		= $(USER_STAMPDIR)/pesign-source
PESIGN_PATCH_STAMP		= $(USER_STAMPDIR)/pesign-patch
PESIGN_BUILD_STAMP		= $(USER_STAMPDIR)/pesign-build
PESIGN_INSTALL_STAMP		= $(STAMPDIR)/pesign-install
PESIGN_STAMP			= $(PESIGN_SOURCE_STAMP) \
				  $(PESIGN_PATCH_STAMP) \
				  $(PESIGN_BUILD_STAMP) \
				  $(PESIGN_INSTALL_STAMP)

PESIGN_INSTALL_DIR		= $(PESIGN_BUILD_DIR)/install
PESIGN_BIN_DIR			= $(PESIGN_INSTALL_DIR)/usr/bin

PHONY += pesign pesign-download pesign-source pesign-patch \
	pesign-build pesign-install pesign-clean pesign-download-clean

pesign: $(PESIGN_STAMP)

DOWNLOAD += $(PESIGN_DOWNLOAD_STAMP)
pesign-download: $(PESIGN_DOWNLOAD_STAMP)
$(PESIGN_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream pesign ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(PESIGN_TARBALL) $(PESIGN_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(PESIGN_SOURCE_STAMP)
pesign-source: $(PESIGN_SOURCE_STAMP)
$(PESIGN_SOURCE_STAMP): $(USER_TREE_STAMP) $(PESIGN_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream pesign ===="
	$(Q) $(SCRIPTDIR)/extract-package $(PESIGN_BUILD_DIR) $(DOWNLOADDIR)/$(PESIGN_TARBALL)
	$(Q) touch $@

pesign-patch: $(PESIGN_PATCH_STAMP)
$(PESIGN_PATCH_STAMP): $(PESIGN_SRCPATCHDIR)/* $(PESIGN_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching pesign ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(PESIGN_SRCPATCHDIR)/series $(PESIGN_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
PESIGN_NEW_FILES = $(shell test -d $(PESIGN_DIR) && test -f $(PESIGN_BUILD_STAMP) && \
	              find -L $(PESIGN_DIR) -newer $(PESIGN_BUILD_STAMP) -type f -print -quit)
endif

pesign-build: $(PESIGN_BUILD_STAMP)
$(PESIGN_BUILD_STAMP): $(PESIGN_PATCH_STAMP) $(PESIGN_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building pesign-$(PESIGN_VERSION) ===="
	$(Q) $(MAKE) -C $(PESIGN_DIR) all
	$(Q) touch $@

pesign-install: $(PESIGN_INSTALL_STAMP)
$(PESIGN_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(PESIGN_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing pesign in $(DEV_SYSROOT) ===="
	$(Q) rm -rf $(PESIGN_INSTALL_DIR)
	$(Q) $(MAKE) -C $(PESIGN_DIR) install DESTDIR=$(PESIGN_INSTALL_DIR)
	$(Q) touch $@

USER_CLEAN += pesign-clean
pesign-clean:
	$(Q) rm -rf $(PESIGN_BUILD_DIR)
	$(Q) rm -f $(PESIGN_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += pesign-download-clean
pesign-download-clean:
	$(Q) rm -f $(PESIGN_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(PESIGN_TARBALL)
