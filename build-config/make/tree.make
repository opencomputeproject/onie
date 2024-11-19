#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of tree
#

TREE_VERSION		= 2.1.3
TREE_TARBALL		= tree-$(TREE_VERSION).tar.gz
TREE_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://gitlab.com/OldManProgrammer/unix-tree/-/archive/$(TREE_VERSION)
TREE_BUILD_DIR		= $(USER_BUILDDIR)/tree
TREE_DIR		= $(TREE_BUILD_DIR)/unix-tree-$(TREE_VERSION)-4fcfd4f68606be979ebb0ae4d3cc422a9e900ef9

TREE_SRCPATCHDIR	= $(PATCHDIR)/tree
TREE_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/tree-download
TREE_SOURCE_STAMP	= $(USER_STAMPDIR)/tree-source
TREE_PATCH_STAMP	= $(USER_STAMPDIR)/tree-patch
TREE_BUILD_STAMP	= $(USER_STAMPDIR)/tree-build
TREE_INSTALL_STAMP	= $(STAMPDIR)/tree-install
TREE_STAMP		= $(TREE_DOWNLOAD_STAMP) \
			  $(TREE_SOURCE_STAMP) \
			  $(TREE_PATCH_STAMP) \
			  $(TREE_BUILD_STAMP) \
			  $(TREE_INSTALL_STAMP)

PHONY += tree \
	 tree-download \
	 tree-source \
	 tree-patch \
	 tree-build \
	 tree-install \
	 tree-clean \
	 tree-download-clean

tree: $(TREE_STAMP)

DOWNLOAD += $(TREE_DOWNLOAD_STAMP)

tree-download: $(TREE_DOWNLOAD_STAMP)
$(TREE_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream tree ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(TREE_TARBALL) $(TREE_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(TREE_SOURCE_STAMP)

tree-source: $(TREE_SOURCE_STAMP)
$(TREE_SOURCE_STAMP): $(USER_TREE_STAMP) | $(TREE_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream tree ===="
	$(Q) $(SCRIPTDIR)/extract-package $(TREE_BUILD_DIR) $(DOWNLOADDIR)/$(TREE_TARBALL)
	$(Q) touch $@

tree-patch: $(TREE_PATCH_STAMP)
$(TREE_PATCH_STAMP): $(TREE_SRCPATCHDIR)/* $(TREE_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching tree ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(TREE_SRCPATCHDIR)/series $(TREE_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
TREE_NEW_FILES = $( \
			shell test -d $(TREE_DIR) && \
			test -f $(TREE_BUILD_STAMP) && \
			find -L $(TREE_DIR) -newer $(TREE_BUILD_STAMP) -type f -print -quit \
		)
endif

tree-build: $(TREE_BUILD_STAMP)
$(TREE_BUILD_STAMP): $(TREE_PATCH_STAMP) $(TREE_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building tree-$(TREE_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(TREE_DIR) CROSS_COMPILE=$(CROSSPREFIX)
	$(Q) touch $@

tree-install: $(TREE_INSTALL_STAMP)
$(TREE_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(TREE_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing tree in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av $(TREE_DIR)/tree $(SYSROOTDIR)/usr/bin/
	$(Q) touch $@

USER_CLEAN += tree-clean
tree-clean:
	$(Q) rm -rf $(TREE_BUILD_DIR)
	$(Q) rm -f $(TREE_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += tree-download-clean
tree-download-clean:
	$(Q) rm -f $(TREE_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(TREE_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
