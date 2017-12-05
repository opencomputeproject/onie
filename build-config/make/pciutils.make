#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of pciutils
#

PCIUTILS_VERSION		= 3.2.1
PCIUTILS_TARBALL		= pciutils-$(PCIUTILS_VERSION).tar.xz
PCIUTILS_TARBALL_URLS		+= $(ONIE_MIRROR) https://www.kernel.org/pub/software/utils/pciutils
PCIUTILS_BUILD_DIR		= $(USER_BUILDDIR)/pciutils
PCIUTILS_DIR			= $(PCIUTILS_BUILD_DIR)/pciutils-$(PCIUTILS_VERSION)

PCIUTILS_SRCPATCHDIR		= $(PATCHDIR)/pciutils
PCIUTILS_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/pciutils-download
PCIUTILS_SOURCE_STAMP		= $(USER_STAMPDIR)/pciutils-source
PCIUTILS_PATCH_STAMP		= $(USER_STAMPDIR)/pciutils-patch
PCIUTILS_BUILD_STAMP		= $(USER_STAMPDIR)/pciutils-build
PCIUTILS_INSTALL_STAMP		= $(STAMPDIR)/pciutils-install
PCIUTILS_STAMP			= $(PCIUTILS_SOURCE_STAMP) \
				  $(PCIUTILS_PATCH_STAMP) \
				  $(PCIUTILS_BUILD_STAMP) \
				  $(PCIUTILS_INSTALL_STAMP)

PCIUTILS_PROGRAMS		= pciutils

PHONY += pciutils pciutils-download pciutils-source pciutils-patch \
	pciutils-build pciutils-install pciutils-clean pciutils-download-clean

PCIUTILS_LIBS = libpci.so libpci.so.3 libpci.so.$(PCIUTILS_VERSION)

pciutils: $(PCIUTILS_STAMP)

DOWNLOAD += $(PCIUTILS_DOWNLOAD_STAMP)
pciutils-download: $(PCIUTILS_DOWNLOAD_STAMP)
$(PCIUTILS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream pciutils ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(PCIUTILS_TARBALL) $(PCIUTILS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(PCIUTILS_SOURCE_STAMP)
pciutils-source: $(PCIUTILS_SOURCE_STAMP)
$(PCIUTILS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(PCIUTILS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream pciutils ===="
	$(Q) $(SCRIPTDIR)/extract-package $(PCIUTILS_BUILD_DIR) $(DOWNLOADDIR)/$(PCIUTILS_TARBALL)
	$(Q) touch $@

pciutils-patch: $(PCIUTILS_PATCH_STAMP)
$(PCIUTILS_PATCH_STAMP): $(PCIUTILS_SRCPATCHDIR)/* $(PCIUTILS_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching pciutils ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(PCIUTILS_SRCPATCHDIR)/series $(PCIUTILS_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
PCIUTILS_NEW_FILES = $(shell test -d $(PCIUTILS_DIR) && test -f $(PCIUTILS_BUILD_STAMP) && \
	              find -L $(PCIUTILS_DIR) -newer $(PCIUTILS_BUILD_STAMP) -type f -print -quit)
endif

pciutils-build: $(PCIUTILS_BUILD_STAMP)
$(PCIUTILS_BUILD_STAMP): $(PCIUTILS_PATCH_STAMP) $(PCIUTILS_NEW_FILES) $(ZLIB_BUILD_STAMP) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building pciutils-$(PCIUTILS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(PCIUTILS_DIR) lib/libpci.so.$(PCIUTILS_VERSION) CROSS_COMPILE=$(CROSSPREFIX) \
		HOST=onie-$(ARCH)-linux ZLIB=yes DNS=no SHARED=yes LIBKMOD=no PREFIX=/usr DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(PCIUTILS_DIR) install-lib CROSS_COMPILE=$(CROSSPREFIX) \
		HOST=onie-$(ARCH)-linux ZLIB=yes DNS=no SHARED=yes LIBKMOD=no PREFIX=/usr DESTDIR=$(DEV_SYSROOT)
	$(Q) touch $@

pciutils-install: $(PCIUTILS_INSTALL_STAMP)
$(PCIUTILS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(PCIUTILS_BUILD_STAMP) $(ZLIB_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing pciutils in $(SYSROOTDIR) ===="
	$(Q) for file in $(PCIUTILS_LIBS); do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	     done
	$(Q) touch $@

USER_CLEAN += pciutils-clean
pciutils-clean:
	$(Q) rm -rf $(PCIUTILS_BUILD_DIR)
	$(Q) rm -f $(PCIUTILS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += pciutils-download-clean
pciutils-download-clean:
	$(Q) rm -f $(PCIUTILS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(PCIUTILS_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
