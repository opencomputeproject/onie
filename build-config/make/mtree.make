#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015 Carlos Cardenas <carlos@cumulusnetworks.com>
#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of mtree
#

MTREE_VERSION		= 1.0.3
MTREE_TARBALL		= mtree-$(MTREE_VERSION).tar.gz
MTREE_TARBALL_URLS	+= $(ONIE_MIRROR)
MTREE_BUILD_DIR	= $(USER_BUILDDIR)/mtree
MTREE_DIR		= $(MTREE_BUILD_DIR)/mtree-$(MTREE_VERSION)

MTREE_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/mtree-download
MTREE_SOURCE_STAMP	= $(USER_STAMPDIR)/mtree-source
MTREE_CONFIGURE_STAMP	= $(USER_STAMPDIR)/mtree-configure
MTREE_BUILD_STAMP	= $(USER_STAMPDIR)/mtree-build
MTREE_INSTALL_STAMP	= $(STAMPDIR)/mtree-install
MTREE_STAMP		= $(MTREE_SOURCE_STAMP) \
			  $(MTREE_CONFIGURE_STAMP) \
			  $(MTREE_BUILD_STAMP) \
			  $(MTREE_INSTALL_STAMP)

MTREE_BIN		= mtree

PHONY += mtree mtree-download mtree-source mtree-configure \
	mtree-build mtree-install mtree-clean mtree-download-clean

mtree: $(MTREE_STAMP)

DOWNLOAD += $(MTREE_DOWNLOAD_STAMP)
mtree-download: $(MTREE_DOWNLOAD_STAMP)
$(MTREE_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream mtree ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(MTREE_TARBALL) $(MTREE_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(MTREE_SOURCE_STAMP)
mtree-source: $(MTREE_SOURCE_STAMP)
$(MTREE_SOURCE_STAMP): $(USER_TREE_STAMP) | $(MTREE_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream mtree ===="
	$(Q) $(SCRIPTDIR)/extract-package $(MTREE_BUILD_DIR) $(DOWNLOADDIR)/$(MTREE_TARBALL)
	$(Q) touch $@

mtree-configure: $(MTREE_CONFIGURE_STAMP)
$(MTREE_CONFIGURE_STAMP): $(MTREE_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure mtree-$(MTREE_VERSION) ===="
	$(Q) cd $(MTREE_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(MTREE_DIR)/configure			\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET)				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)" 			\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

mtree-build: $(MTREE_BUILD_STAMP)
$(MTREE_BUILD_STAMP): $(MTREE_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building mtree-$(MTREE_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(MTREE_DIR)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(MTREE_DIR) install
	$(Q) touch $@

mtree-install: $(MTREE_INSTALL_STAMP)
$(MTREE_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(MTREE_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing mtree in $(SYSROOTDIR) ===="
	$(Q) cp -av $(DEV_SYSROOT)/usr/bin/$(MTREE_BIN) $(SYSROOTDIR)/usr/bin
	$(Q) touch $@

USER_CLEAN += mtree-clean
mtree-clean:
	$(Q) rm -rf $(MTREE_BUILD_DIR)
	$(Q) rm -f $(MTREE_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += mtree-download-clean
mtree-download-clean:
	$(Q) rm -f $(MTREE_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(MTREE_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
