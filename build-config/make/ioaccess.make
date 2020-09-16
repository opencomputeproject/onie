#-------------------------------------------------------------------------------
#
#  Copyright (C) 2019-2099 Jay Lin <jay.tc.lin@ufispace.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of libusb
#

IOACCESS_VERSION	= v1.1-3
IOACCESS_TARBALL	= IoAccess_$(IOACCESS_VERSION).tar.gz
IOACCESS_TARBALL_URLS	+= $(ONIE_MIRROR)
IOACCESS_BUILD_DIR	= $(USER_BUILDDIR)/IoAccess
IOACCESS_DIR		= $(IOACCESS_BUILD_DIR)/IoAccess_$(IOACCESS_VERSION)

IOACCESS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/IoAccess-download
IOACCESS_SOURCE_STAMP	= $(USER_STAMPDIR)/IoAccess-source
IOACCESS_BUILD_STAMP	= $(USER_STAMPDIR)/IoAccess-build
IOACCESS_INSTALL_STAMP	= $(STAMPDIR)/IoAccess-install
IOACCESS_STAMP		= $(IOACCESS_SOURCE_STAMP) \
			  $(IOACCESS_BUILD_STAMP) \
			  $(IOACCESS_INSTALL_STAMP)

IOSET_BIN		= ioset
IOGET_BIN		= ioget

PHONY += IoAccess IoAccess-download IoAccess-source \
	IoAccess-build IoAccess-install IoAccess-clean IoAccess-download-clean

IoAccess: $(IOACCESS_STAMP)

DOWNLOAD += $(IOACCESS_DOWNLOAD_STAMP)
IoAccess-download: $(IOACCESS_DOWNLOAD_STAMP)
$(IOACCESS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	rm -f $@ && eval $(PROFILE_STAMP)
	echo "==== Getting upstream IoAccess ===="
	cp $(UFITOOLDIR)/$(IOACCESS_TARBALL) $(DOWNLOADDIR)/
	touch $@

SOURCE += $(IOACCESS_SOURCE_STAMP)
IoAccess-source: $(IOACCESS_SOURCE_STAMP)
$(IOACCESS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(IOACCESS_DOWNLOAD_STAMP)
	rm -f $@ && eval $(PROFILE_STAMP)
	echo "==== Extracting upstream IoAccess ===="
	$(SCRIPTDIR)/extract-package $(IOACCESS_BUILD_DIR) $(DOWNLOADDIR)/$(IOACCESS_TARBALL)
	touch $@

IoAccess-build: $(IOACCESS_BUILD_STAMP)
$(IOACCESS_BUILD_STAMP): $(IOACCESS_SOURCE_STAMP)
	rm -f $@ && eval $(PROFILE_STAMP)
	echo "====  Building IoAccess-$(IOACCESS_VERSION) ===="
	PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(IOACCESS_DIR)
	touch $@

IoAccess-install: $(IOACCESS_INSTALL_STAMP)
$(IOACCESS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(IOACCESS_BUILD_STAMP)
	rm -f $@ && eval $(PROFILE_STAMP)
	echo "==== Installing IoAccess in $(SYSROOTDIR) ===="
	cp -f $(IOACCESS_DIR)/$(IOSET_BIN) $(SYSROOTDIR)/usr/sbin
	cp -f $(IOACCESS_DIR)/$(IOGET_BIN) $(SYSROOTDIR)/usr/sbin
	touch $@

USER_CLEAN += IoAccess-clean
IoAccess-clean:
	rm -rf $(IOACCESS_BUILD_DIR)
	rm -f $(IOACCESS_STAMP)
	echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += IoAccess-download-clean
IoAccess-download-clean:
	rm -f $(IOACCESS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(IOACCESS_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
