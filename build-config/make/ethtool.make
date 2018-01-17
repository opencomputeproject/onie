#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of ethtool
#

ETHTOOL_VERSION		= 3.14
ETHTOOL_TARBALL		= ethtool-$(ETHTOOL_VERSION).tar.xz
ETHTOOL_TARBALL_URLS	+= $(ONIE_MIRROR) https://www.kernel.org/pub/software/network/ethtool
ETHTOOL_BUILD_DIR	= $(USER_BUILDDIR)/ethtool
ETHTOOL_DIR		= $(ETHTOOL_BUILD_DIR)/ethtool-$(ETHTOOL_VERSION)

ETHTOOL_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/ethtool-download
ETHTOOL_SOURCE_STAMP	= $(USER_STAMPDIR)/ethtool-source
ETHTOOL_CONFIGURE_STAMP	= $(USER_STAMPDIR)/ethtool-configure
ETHTOOL_BUILD_STAMP	= $(USER_STAMPDIR)/ethtool-build
ETHTOOL_INSTALL_STAMP	= $(STAMPDIR)/ethtool-install
ETHTOOL_STAMP		= $(ETHTOOL_SOURCE_STAMP) \
			  $(ETHTOOL_CONFIGURE_STAMP) \
			  $(ETHTOOL_BUILD_STAMP) \
			  $(ETHTOOL_INSTALL_STAMP)

ETHTOOL_BIN		= ethtool

PHONY += ethtool ethtool-download ethtool-source ethtool-configure \
	ethtool-build ethtool-install ethtool-clean ethtool-download-clean

ethtool: $(ETHTOOL_STAMP)

DOWNLOAD += $(ETHTOOL_DOWNLOAD_STAMP)
ethtool-download: $(ETHTOOL_DOWNLOAD_STAMP)
$(ETHTOOL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream ethtool ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(ETHTOOL_TARBALL) $(ETHTOOL_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(ETHTOOL_SOURCE_STAMP)
ethtool-source: $(ETHTOOL_SOURCE_STAMP)
$(ETHTOOL_SOURCE_STAMP): $(USER_TREE_STAMP) | $(ETHTOOL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream ethtool ===="
	$(Q) $(SCRIPTDIR)/extract-package $(ETHTOOL_BUILD_DIR) $(DOWNLOADDIR)/$(ETHTOOL_TARBALL)
	$(Q) touch $@

ethtool-configure: $(ETHTOOL_CONFIGURE_STAMP)
$(ETHTOOL_CONFIGURE_STAMP): $(ETHTOOL_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure ethtool-$(ETHTOOL_VERSION) ===="
	$(Q) cd $(ETHTOOL_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(ETHTOOL_DIR)/configure			\
		--prefix=/usr					\
		--host=$(TARGET)				\
		CFLAGS="$(ONIE_CFLAGS)" 			\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

ethtool-build: $(ETHTOOL_BUILD_STAMP)
$(ETHTOOL_BUILD_STAMP): $(ETHTOOL_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building ethtool-$(ETHTOOL_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(ETHTOOL_DIR) DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(ETHTOOL_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

ethtool-install: $(ETHTOOL_INSTALL_STAMP)
$(ETHTOOL_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(ETHTOOL_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing ethtool in $(SYSROOTDIR) ===="
	$(Q) cp -av $(DEV_SYSROOT)/usr/sbin/$(ETHTOOL_BIN) $(SYSROOTDIR)/usr/sbin
	$(Q) touch $@

USER_CLEAN += ethtool-clean
ethtool-clean:
	$(Q) rm -rf $(ETHTOOL_BUILD_DIR)
	$(Q) rm -f $(ETHTOOL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += ethtool-download-clean
ethtool-download-clean:
	$(Q) rm -f $(ETHTOOL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(ETHTOOL_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
