#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of efibootmgr
#

EFIBOOTMGR_VERSION		= 0.11.0
EFIBOOTMGR_TARBALL		= efibootmgr-$(EFIBOOTMGR_VERSION).tar.bz2
EFIBOOTMGR_TARBALL_URLS		+= $(ONIE_MIRROR) https://github.com/rhinstaller/efibootmgr/releases/download/efibootmgr-0.11.0
EFIBOOTMGR_BUILD_DIR		= $(MBUILDDIR)/efibootmgr
EFIBOOTMGR_DIR			= $(EFIBOOTMGR_BUILD_DIR)/efibootmgr-$(EFIBOOTMGR_VERSION)

EFIBOOTMGR_SRCPATCHDIR		= $(PATCHDIR)/efibootmgr
EFIBOOTMGR_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/efibootmgr-download
EFIBOOTMGR_SOURCE_STAMP		= $(STAMPDIR)/efibootmgr-source
EFIBOOTMGR_PATCH_STAMP		= $(STAMPDIR)/efibootmgr-patch
EFIBOOTMGR_BUILD_STAMP		= $(STAMPDIR)/efibootmgr-build
EFIBOOTMGR_INSTALL_STAMP	= $(STAMPDIR)/efibootmgr-install
EFIBOOTMGR_STAMP		= $(EFIBOOTMGR_SOURCE_STAMP) \
				  $(EFIBOOTMGR_PATCH_STAMP) \
				  $(EFIBOOTMGR_BUILD_STAMP) \
				  $(EFIBOOTMGR_INSTALL_STAMP)

EFIBOOTMGR_PROGRAMS		= efibootmgr

PHONY += efibootmgr efibootmgr-download efibootmgr-source efibootmgr-patch \
	efibootmgr-build efibootmgr-install efibootmgr-clean efibootmgr-download-clean

efibootmgr: $(EFIBOOTMGR_STAMP)

DOWNLOAD += $(EFIBOOTMGR_DOWNLOAD_STAMP)
efibootmgr-download: $(EFIBOOTMGR_DOWNLOAD_STAMP)
$(EFIBOOTMGR_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream efibootmgr ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(EFIBOOTMGR_TARBALL) $(EFIBOOTMGR_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(EFIBOOTMGR_SOURCE_STAMP)
efibootmgr-source: $(EFIBOOTMGR_SOURCE_STAMP)
$(EFIBOOTMGR_SOURCE_STAMP): $(TREE_STAMP) | $(EFIBOOTMGR_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream efibootmgr ===="
	$(Q) $(SCRIPTDIR)/extract-package $(EFIBOOTMGR_BUILD_DIR) $(DOWNLOADDIR)/$(EFIBOOTMGR_TARBALL)
	$(Q) touch $@

efibootmgr-patch: $(EFIBOOTMGR_PATCH_STAMP)
$(EFIBOOTMGR_PATCH_STAMP): $(EFIBOOTMGR_SRCPATCHDIR)/* $(EFIBOOTMGR_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching efibootmgr ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(EFIBOOTMGR_SRCPATCHDIR)/series $(EFIBOOTMGR_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
EFIBOOTMGR_NEW_FILES = $(shell test -d $(EFIBOOTMGR_DIR) && test -f $(EFIBOOTMGR_BUILD_STAMP) && \
	              find -L $(EFIBOOTMGR_DIR) -newer $(EFIBOOTMGR_BUILD_STAMP) -type f \
			\! -name filelist-rpm -print -quit)
endif

efibootmgr-build: $(EFIBOOTMGR_BUILD_STAMP)
$(EFIBOOTMGR_BUILD_STAMP): $(EFIBOOTMGR_PATCH_STAMP) $(EFIBOOTMGR_NEW_FILES) $(EFIVAR_INSTALL_STAMP) \
				$(PCIUTILS_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building efibootmgr-$(EFIBOOTMGR_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	\
		$(MAKE) -C $(EFIBOOTMGR_DIR) CROSS_COMPILE=$(CROSSPREFIX) \
			EXTRA_CFLAGS=-I$(DEV_SYSROOT)/usr/include/efivar
	$(Q) touch $@

efibootmgr-install: $(EFIBOOTMGR_INSTALL_STAMP)
$(EFIBOOTMGR_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(EFIBOOTMGR_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing efibootmgr programs in $(SYSROOTDIR) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(EFIBOOTMGR_DIR) CROSS_COMPILE=$(CROSSPREFIX) \
		BINDIR=$(DEV_SYSROOT)/usr/sbin install
	$(Q) for file in $(EFIBOOTMGR_PROGRAMS); do \
		cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin ; \
	     done
	$(Q) touch $@

USERSPACE_CLEAN += efibootmgr-clean
efibootmgr-clean:
	$(Q) rm -rf $(EFIBOOTMGR_BUILD_DIR)
	$(Q) rm -f $(EFIBOOTMGR_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += efibootmgr-download-clean
efibootmgr-download-clean:
	$(Q) rm -f $(EFIBOOTMGR_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(EFIBOOTMGR_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
