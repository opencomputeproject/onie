#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of ipmitool
#

IPMITOOL_VERSION		= 1.8.18
IPMITOOL_TARBALL		= ipmitool-$(IPMITOOL_VERSION).tar.bz2
IPMITOOL_TARBALL_URLS	+= $(ONIE_MIRROR) https://github.com/ipmitool/ipmitool/releases/download/IPMITOOL_$(subst .,_,$(IPMITOOL_VERSION))/
IPMITOOL_BUILD_DIR	= $(USER_BUILDDIR)/ipmitool
IPMITOOL_DIR		= $(IPMITOOL_BUILD_DIR)/ipmitool-$(IPMITOOL_VERSION)

IPMITOOL_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/ipmitool-download
IPMITOOL_SOURCE_STAMP	= $(USER_STAMPDIR)/ipmitool-source
IPMITOOL_CONFIGURE_STAMP	= $(USER_STAMPDIR)/ipmitool-configure
IPMITOOL_BUILD_STAMP	= $(USER_STAMPDIR)/ipmitool-build
IPMITOOL_INSTALL_STAMP	= $(STAMPDIR)/ipmitool-install
IPMITOOL_STAMP		= $(IPMITOOL_SOURCE_STAMP) \
			  $(IPMITOOL_CONFIGURE_STAMP) \
			  $(IPMITOOL_BUILD_STAMP) \
			  $(IPMITOOL_INSTALL_STAMP)

IPMITOOL_BIN		= ipmitool

PHONY += ipmitool ipmitool-download ipmitool-source ipmitool-configure \
	ipmitool-build ipmitool-install ipmitool-clean ipmitool-download-clean

ipmitool: $(IPMITOOL_STAMP)

DOWNLOAD += $(IPMITOOL_DOWNLOAD_STAMP)
ipmitool-download: $(IPMITOOL_DOWNLOAD_STAMP)
$(IPMITOOL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream ipmitool ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(IPMITOOL_TARBALL) $(IPMITOOL_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(IPMITOOL_SOURCE_STAMP)
ipmitool-source: $(IPMITOOL_SOURCE_STAMP)
$(IPMITOOL_SOURCE_STAMP): $(USER_TREE_STAMP) | $(IPMITOOL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream ipmitool ===="
	$(Q) $(SCRIPTDIR)/extract-package $(IPMITOOL_BUILD_DIR) $(DOWNLOADDIR)/$(IPMITOOL_TARBALL)
	$(Q) touch $@

ipmitool-configure: $(IPMITOOL_CONFIGURE_STAMP)
$(IPMITOOL_CONFIGURE_STAMP): $(IPMITOOL_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure ipmitool-$(IPMITOOL_VERSION) ===="
	$(Q) cd $(IPMITOOL_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(IPMITOOL_DIR)/configure			\
		--prefix=/usr					\
		--host=$(TARGET)				\
		CFLAGS="$(ONIE_CFLAGS)" 			\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) echo "#undef malloc" >> $(IPMITOOL_DIR)/config.h
	$(Q) touch $@

ipmitool-build: $(IPMITOOL_BUILD_STAMP)
$(IPMITOOL_BUILD_STAMP): $(IPMITOOL_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building ipmitool-$(IPMITOOL_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(IPMITOOL_DIR) DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(IPMITOOL_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

ipmitool-install: $(IPMITOOL_INSTALL_STAMP)
$(IPMITOOL_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(IPMITOOL_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing ipmitool in $(SYSROOTDIR) ===="
	$(Q) cp -f $(IPMITOOL_DIR)/src/$(IPMITOOL_BIN) $(SYSROOTDIR)/usr/sbin
	$(Q) touch $@

USER_CLEAN += ipmitool-clean
ipmitool-clean:
	$(Q) rm -rf $(IPMITOOL_BUILD_DIR)
	$(Q) rm -f $(IPMITOOL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += ipmitool-download-clean
ipmitool-download-clean:
	$(Q) rm -f $(IPMITOOL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(IPMITOOL_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
