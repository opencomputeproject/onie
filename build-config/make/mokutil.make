#-------------------------------------------------------------------------------
#
#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of mokutil
#

MOKUTIL_VERSION			= 0.3.0
MOKUTIL_TARBALL			= $(MOKUTIL_VERSION).tar.gz
MOKUTIL_TARBALL_URLS		+= $(ONIE_MIRROR) https://github.com/lcp/mokutil/archive
MOKUTIL_BUILD_DIR		= $(USER_BUILDDIR)/mokutil
MOKUTIL_DIR			= $(MOKUTIL_BUILD_DIR)/mokutil-$(MOKUTIL_VERSION)

MOKUTIL_SRCPATCHDIR		= $(PATCHDIR)/mokutil
MOKUTIL_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/mokutil-$(MOKUTIL_VERSION)-download
MOKUTIL_SOURCE_STAMP		= $(USER_STAMPDIR)/mokutil-source
MOKUTIL_PATCH_STAMP		= $(USER_STAMPDIR)/mokutil-patch
MOKUTIL_CONFIGURE_STAMP		= $(USER_STAMPDIR)/mokutil-configure
MOKUTIL_BUILD_STAMP		= $(USER_STAMPDIR)/mokutil-build
MOKUTIL_INSTALL_STAMP		= $(STAMPDIR)/mokutil-install
MOKUTIL_STAMP			= $(MOKUTIL_SOURCE_STAMP) \
				  $(MOKUTIL_PATCH_STAMP) \
				  $(MOKUTIL_CONFIGURE_STAMP) \
				  $(MOKUTIL_BUILD_STAMP) \
				  $(MOKUTIL_INSTALL_STAMP)

MOKUTIL_PROGRAMS		= mokutil

PHONY += mokutil mokutil-download mokutil-source mokutil-patch \
	mokutil-configure mokutil-build mokutil-install \
	mokutil-clean mokutil-download-clean

MOKUTIL_BINS = mokutil

mokutil: $(MOKUTIL_STAMP)

DOWNLOAD += $(MOKUTIL_DOWNLOAD_STAMP)
mokutil-download: $(MOKUTIL_DOWNLOAD_STAMP)
$(MOKUTIL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream mokutil ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(MOKUTIL_TARBALL) $(MOKUTIL_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(MOKUTIL_SOURCE_STAMP)
mokutil-source: $(MOKUTIL_SOURCE_STAMP)
$(MOKUTIL_SOURCE_STAMP): $(USER_TREE_STAMP) $(MOKUTIL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream mokutil ===="
	$(Q) $(SCRIPTDIR)/extract-package $(MOKUTIL_BUILD_DIR) $(DOWNLOADDIR)/$(MOKUTIL_TARBALL)
	$(Q) touch $@

mokutil-patch: $(MOKUTIL_PATCH_STAMP)
$(MOKUTIL_PATCH_STAMP): $(EFIVAR_BUILD_STAMP) $(OPENSSL_BUILD_STAMP) $(MOKUTIL_SRCPATCHDIR)/* $(MOKUTIL_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching mokutil ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(MOKUTIL_SRCPATCHDIR)/series $(MOKUTIL_DIR)
	$(Q) cd $(MOKUTIL_DIR) && ./autogen.sh
	$(Q) touch $@

ifndef MAKE_CLEAN
MOKUTIL_NEW_FILES = $(shell test -d $(MOKUTIL_DIR) && test -f $(MOKUTIL_BUILD_STAMP) && \
	              find -L $(MOKUTIL_DIR) -newer $(MOKUTIL_BUILD_STAMP) -type f -print -quit)
endif

mokutil-configure: $(MOKUTIL_CONFIGURE_STAMP)
$(MOKUTIL_CONFIGURE_STAMP): $(MOKUTIL_PATCH_STAMP) $(EFIVAR_BUILD_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure mokutil-$(MOKUTIL_VERSION) ===="
	$(Q) cd $(MOKUTIL_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(MOKUTIL_DIR)/configure			\
		--prefix=/usr					\
		--host=$(TARGET)				\
		EFIVAR_CFLAGS=-I$(DEV_SYSROOT)/usr/include/efivar \
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"			\
		$(ONIE_PKG_CONFIG)
	$(Q) touch $@

mokutil-build: $(MOKUTIL_BUILD_STAMP)
$(MOKUTIL_BUILD_STAMP): $(MOKUTIL_CONFIGURE_STAMP) $(MOKUTIL_NEW_FILES) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building mokutil-$(MOKUTIL_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(MOKUTIL_DIR) DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(MOKUTIL_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

mokutil-install: $(MOKUTIL_INSTALL_STAMP)
$(MOKUTIL_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(MOKUTIL_BUILD_STAMP) $(POPT_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing mokutil in $(SYSROOTDIR) ===="
	$(Q) for file in $(MOKUTIL_BINS); do \
		cp -av $(DEV_SYSROOT)/usr/bin/$$file $(SYSROOTDIR)/usr/bin/ || exit 1 ; \
	     done
	$(Q) touch $@

USER_CLEAN += mokutil-clean
mokutil-clean:
	$(Q) rm -rf $(MOKUTIL_BUILD_DIR)
	$(Q) rm -f $(MOKUTIL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += mokutil-download-clean
mokutil-download-clean:
	$(Q) rm -f $(MOKUTIL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(MOKUTIL_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
