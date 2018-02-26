#-------------------------------------------------------------------------------
#
#  Copyright (C) 2018 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of sbsigntool
#

SBSIGNTOOL_VERSION		= 0.6
SBSIGNTOOL_TARBALL		= sbsigntool_$(SBSIGNTOOL_VERSION).orig.tar.gz
SBSIGNTOOL_TARBALL_URLS		+= $(ONIE_MIRROR) http://http.debian.net/debian/pool/main/s/sbsigntool
SBSIGNTOOL_BUILD_DIR		= $(USER_BUILDDIR)/sbsigntool
SBSIGNTOOL_DIR			= $(SBSIGNTOOL_BUILD_DIR)/sbsigntool-$(SBSIGNTOOL_VERSION)

SBSIGNTOOL_SRCPATCHDIR		= $(PATCHDIR)/sbsigntool
SBSIGNTOOL_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/sbsigntool-download
SBSIGNTOOL_SOURCE_STAMP		= $(USER_STAMPDIR)/sbsigntool-source
SBSIGNTOOL_CONFIGURE_STAMP	= $(USER_STAMPDIR)/sbsigntool-configure
SBSIGNTOOL_BUILD_STAMP		= $(USER_STAMPDIR)/sbsigntool-build
SBSIGNTOOL_INSTALL_STAMP	= $(STAMPDIR)/sbsigntool-install
SBSIGNTOOL_STAMP		= $(SBSIGNTOOL_SOURCE_STAMP) \
				  $(SBSIGNTOOL_CONFIGURE_STAMP) \
				  $(SBSIGNTOOL_BUILD_STAMP) \
				  $(SBSIGNTOOL_INSTALL_STAMP)

SBSIGNTOOL_INSTALL_DIR		= $(SBSIGNTOOL_BUILD_DIR)/install
SBSIGNTOOL_BIN_DIR		= $(SBSIGNTOOL_INSTALL_DIR)/bin
SBSIGN_EXE			?= $(SBSIGNTOOL_BIN_DIR)/sbsign

PHONY += sbsigntool sbsigntool-download sbsigntool-source sbsigntool-configure \
	sbsigntool-build sbsigntool-install sbsigntool-clean sbsigntool-download-clean

sbsigntool: $(SBSIGNTOOL_STAMP)

DOWNLOAD += $(SBSIGNTOOL_DOWNLOAD_STAMP)
sbsigntool-download: $(SBSIGNTOOL_DOWNLOAD_STAMP)
$(SBSIGNTOOL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream sbsigntool ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(SBSIGNTOOL_TARBALL) $(SBSIGNTOOL_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(SBSIGNTOOL_SOURCE_STAMP)
sbsigntool-source: $(SBSIGNTOOL_SOURCE_STAMP)
$(SBSIGNTOOL_SOURCE_STAMP): $(USER_TREE_STAMP) $(SBSIGNTOOL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream sbsigntool ===="
	$(Q) $(SCRIPTDIR)/extract-package $(SBSIGNTOOL_BUILD_DIR) $(DOWNLOADDIR)/$(SBSIGNTOOL_TARBALL)
	$(Q) touch $@

sbsigntool-configure: $(SBSIGNTOOL_CONFIGURE_STAMP)
$(SBSIGNTOOL_CONFIGURE_STAMP): $(SBSIGNTOOL_SOURCE_STAMP) $(GNU_EFI_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Configuring sbsigntool ===="
	$(Q) cd $(SBSIGNTOOL_DIR) && $(SBSIGNTOOL_DIR)/configure \
		--prefix=$(SBSIGNTOOL_INSTALL_DIR) \
		CFLAGS="-I$(DEV_SYSROOT)/usr/include -I$(DEV_SYSROOT)/usr/include/efi -I$(DEV_SYSROOT)/usr/include/efi/x86_64"
	$(Q) touch $@

sbsigntool-build: $(SBSIGNTOOL_BUILD_STAMP)
$(SBSIGNTOOL_BUILD_STAMP): $(SBSIGNTOOL_CONFIGURE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building sbsigntool-$(SBSIGNTOOL_VERSION) ===="
	$(Q) $(MAKE) -C $(SBSIGNTOOL_DIR) all
	$(Q) touch $@

sbsigntool-install: $(SBSIGNTOOL_INSTALL_STAMP)
$(SBSIGNTOOL_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(SBSIGNTOOL_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing sbsigntool in $(DEV_SYSROOT) ===="
	$(Q) rm -rf $(SBSIGNTOOL_INSTALL_DIR)
	$(Q) $(MAKE) -C $(SBSIGNTOOL_DIR) install
	$(Q) touch $@

USERSPACE_CLEAN += sbsigntool-clean
sbsigntool-clean:
	$(Q) rm -rf $(SBSIGNTOOL_BUILD_DIR)
	$(Q) rm -f $(SBSIGNTOOL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += sbsigntool-download-clean
sbsigntool-download-clean:
	$(Q) rm -f $(SBSIGNTOOL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(SBSIGNTOOL_TARBALL)
