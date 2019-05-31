#-------------------------------------------------------------------------------
#
#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of gnu-efi
#

GNU_EFI_VERSION			= 3.0.6
GNU_EFI_TARBALL			= gnu-efi-$(GNU_EFI_VERSION).tar.bz2
GNU_EFI_TARBALL_URLS		+= $(ONIE_MIRROR) https://downloads.sourceforge.net/project/gnu-efi
GNU_EFI_BUILD_DIR		= $(USER_BUILDDIR)/gnu-efi
GNU_EFI_DIR			= $(GNU_EFI_BUILD_DIR)/gnu-efi-$(GNU_EFI_VERSION)

GNU_EFI_SRCPATCHDIR		= $(PATCHDIR)/gnu-efi
GNU_EFI_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/gnu-efi-download
GNU_EFI_SOURCE_STAMP		= $(USER_STAMPDIR)/gnu-efi-source
GNU_EFI_PATCH_STAMP		= $(USER_STAMPDIR)/gnu-efi-patch
GNU_EFI_BUILD_STAMP		= $(USER_STAMPDIR)/gnu-efi-build
GNU_EFI_INSTALL_STAMP		= $(STAMPDIR)/gnu-efi-install
GNU_EFI_STAMP			= $(GNU_EFI_SOURCE_STAMP) \
				  $(GNU_EFI_PATCH_STAMP) \
				  $(GNU_EFI_BUILD_STAMP) \
				  $(GNU_EFI_INSTALL_STAMP)

GNU_EFI_LIB_PATH	= $(DEV_SYSROOT)/usr/lib
GNU_EFI_INCLUDE		= $(DEV_SYSROOT)/usr/include/efi


PHONY += gnu-efi gnu-efi-download gnu-efi-source gnu-efi-patch \
	gnu-efi-build gnu-efi-install gnu-efi-clean gnu-efi-download-clean

gnu-efi: $(GNU_EFI_STAMP)

DOWNLOAD += $(GNU_EFI_DOWNLOAD_STAMP)
gnu-efi-download: $(GNU_EFI_DOWNLOAD_STAMP)
$(GNU_EFI_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream gnu-efi ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(GNU_EFI_TARBALL) $(GNU_EFI_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(GNU_EFI_SOURCE_STAMP)
gnu-efi-source: $(GNU_EFI_SOURCE_STAMP)
$(GNU_EFI_SOURCE_STAMP): $(USER_TREE_STAMP) $(GNU_EFI_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream gnu-efi ===="
	$(Q) $(SCRIPTDIR)/extract-package $(GNU_EFI_BUILD_DIR) $(DOWNLOADDIR)/$(GNU_EFI_TARBALL)
	$(Q) touch $@

gnu-efi-patch: $(GNU_EFI_PATCH_STAMP)
$(GNU_EFI_PATCH_STAMP): $(GNU_EFI_SRCPATCHDIR)/* $(GNU_EFI_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching gnu-efi ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(GNU_EFI_SRCPATCHDIR)/series $(GNU_EFI_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
GNU_EFI_NEW_FILES = $(shell test -d $(GNU_EFI_DIR) && test -f $(GNU_EFI_BUILD_STAMP) && \
	              find -L $(GNU_EFI_DIR) -newer $(GNU_EFI_BUILD_STAMP) -type f -print -quit)
endif

gnu-efi-build: $(GNU_EFI_BUILD_STAMP)
$(GNU_EFI_BUILD_STAMP): $(GNU_EFI_PATCH_STAMP) $(GNU_EFI_NEW_FILES) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building gnu-efi-$(GNU_EFI_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	\
		$(MAKE) -j1 -C $(GNU_EFI_DIR) \
			CROSS_COMPILE=$(CROSSPREFIX)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	\
		$(MAKE) -j1 -C $(GNU_EFI_DIR)/apps \
			CROSS_COMPILE=$(CROSSPREFIX)
	$(Q) touch $@

gnu-efi-install: $(GNU_EFI_INSTALL_STAMP)
$(GNU_EFI_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(GNU_EFI_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing gnu-efi in $(DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	\
		$(MAKE) -j1 -C $(GNU_EFI_DIR) \
			CROSS_COMPILE=$(CROSSPREFIX) \
			INSTALLROOT=$(DEV_SYSROOT) PREFIX=/usr \
			install
	$(Q) touch $@

USER_CLEAN += gnu-efi-clean
gnu-efi-clean:
	$(Q) rm -rf $(GNU_EFI_BUILD_DIR)
	$(Q) rm -f $(GNU_EFI_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += gnu-efi-download-clean
gnu-efi-download-clean:
	$(Q) rm -f $(GNU_EFI_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(GNU_EFI_TARBALL)
