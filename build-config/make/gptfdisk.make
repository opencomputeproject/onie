#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of gptfdisk
#

GPTFDISK_VERSION		= 0.8.8
GPTFDISK_TARBALL		= gptfdisk-$(GPTFDISK_VERSION).tar.gz
GPTFDISK_TARBALL_URLS		+= $(ONIE_MIRROR) http://sourceforge.net/projects/gptfdisk/files/gptfdisk/$(GPTFDISK_VERSION)/
GPTFDISK_BUILD_DIR		= $(USER_BUILDDIR)/gptfdisk
GPTFDISK_DIR			= $(GPTFDISK_BUILD_DIR)/gptfdisk-$(GPTFDISK_VERSION)

GPTFDISK_SRCPATCHDIR		= $(PATCHDIR)/gptfdisk
GPTFDISK_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/gptfdisk-download
GPTFDISK_SOURCE_STAMP		= $(USER_STAMPDIR)/gptfdisk-source
GPTFDISK_PATCH_STAMP		= $(USER_STAMPDIR)/gptfdisk-patch
GPTFDISK_BUILD_STAMP		= $(USER_STAMPDIR)/gptfdisk-build
GPTFDISK_INSTALL_STAMP		= $(STAMPDIR)/gptfdisk-install
GPTFDISK_STAMP			= $(GPTFDISK_SOURCE_STAMP) \
				  $(GPTFDISK_PATCH_STAMP) \
				  $(GPTFDISK_BUILD_STAMP) \
				  $(GPTFDISK_INSTALL_STAMP)

GPTFDISK_PROGRAMS		= gdisk sgdisk

PHONY += gptfdisk gptfdisk-download gptfdisk-source gptfdisk-patch \
	gptfdisk-build gptfdisk-install gptfdisk-clean gptfdisk-download-clean

gptfdisk: $(GPTFDISK_STAMP)

DOWNLOAD += $(GPTFDISK_DOWNLOAD_STAMP)
gptfdisk-download: $(GPTFDISK_DOWNLOAD_STAMP)
$(GPTFDISK_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream gptfdisk ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(GPTFDISK_TARBALL) $(GPTFDISK_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(GPTFDISK_SOURCE_STAMP)
gptfdisk-source: $(GPTFDISK_SOURCE_STAMP)
$(GPTFDISK_SOURCE_STAMP): $(USER_TREE_STAMP) | $(GPTFDISK_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream gptfdisk ===="
	$(Q) $(SCRIPTDIR)/extract-package $(GPTFDISK_BUILD_DIR) $(DOWNLOADDIR)/$(GPTFDISK_TARBALL)
	$(Q) touch $@

gptfdisk-patch: $(GPTFDISK_PATCH_STAMP)
$(GPTFDISK_PATCH_STAMP): $(GPTFDISK_SRCPATCHDIR)/* $(GPTFDISK_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching gptfdisk ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(GPTFDISK_SRCPATCHDIR)/series $(GPTFDISK_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
GPTFDISK_NEW_FILES = $(shell test -d $(GPTFDISK_DIR) && test -f $(GPTFDISK_BUILD_STAMP) && \
	              find -L $(GPTFDISK_DIR) -newer $(GPTFDISK_BUILD_STAMP) -type f -print -quit)
endif

gptfdisk-build: $(GPTFDISK_BUILD_STAMP)
$(GPTFDISK_BUILD_STAMP): $(E2FSPROGS_BUILD_STAMP) $(POPT_BUILD_STAMP) \
				$(GPTFDISK_PATCH_STAMP) $(GPTFDISK_NEW_FILES) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building gptfdisk-$(GPTFDISK_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GPTFDISK_DIR) \
		$(GPTFDISK_PROGRAMS) CROSS_COMPILE=$(CROSSPREFIX)
	$(Q) touch $@

gptfdisk-install: $(GPTFDISK_INSTALL_STAMP)
$(GPTFDISK_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(GPTFDISK_BUILD_STAMP) $(POPT_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing gptfdisk programs in $(SYSROOTDIR) ===="
	$(Q) for file in $(GPTFDISK_PROGRAMS); do \
		cp -av $(GPTFDISK_DIR)/$$file $(SYSROOTDIR)/usr/bin ; \
	     done
	$(Q) touch $@

USER_CLEAN += gptfdisk-clean
gptfdisk-clean:
	$(Q) rm -rf $(GPTFDISK_BUILD_DIR)
	$(Q) rm -f $(GPTFDISK_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += gptfdisk-download-clean
gptfdisk-download-clean:
	$(Q) rm -f $(GPTFDISK_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(GPTFDISK_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
