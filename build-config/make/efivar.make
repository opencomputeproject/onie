#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of efivar
#

EFIVAR_VERSION			= 0.20
EFIVAR_TARBALL			= efivar-$(EFIVAR_VERSION).tar.bz2
EFIVAR_TARBALL_URLS		+= $(ONIE_MIRROR) https://github.com/rhinstaller/efivar/releases/download/$(EFIVAR_VERSION)
EFIVAR_BUILD_DIR		= $(USER_BUILDDIR)/efivar
EFIVAR_DIR			= $(EFIVAR_BUILD_DIR)/efivar-$(EFIVAR_VERSION)

EFIVAR_SRCPATCHDIR		= $(PATCHDIR)/efivar
EFIVAR_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/efivar-$(EFIVAR_VERSION)-download
EFIVAR_SOURCE_STAMP		= $(USER_STAMPDIR)/efivar-source
EFIVAR_PATCH_STAMP		= $(USER_STAMPDIR)/efivar-patch
EFIVAR_BUILD_STAMP		= $(USER_STAMPDIR)/efivar-build
EFIVAR_INSTALL_STAMP		= $(STAMPDIR)/efivar-install
EFIVAR_STAMP			= $(EFIVAR_SOURCE_STAMP) \
				  $(EFIVAR_PATCH_STAMP) \
				  $(EFIVAR_BUILD_STAMP) \
				  $(EFIVAR_INSTALL_STAMP)

EFIVAR_PROGRAMS		= efivar

PHONY += efivar efivar-download efivar-source efivar-patch \
	efivar-build efivar-install efivar-clean efivar-download-clean

EFIVAR_BINS = efivar
EFIVAR_LIBS = libefivar.so.0 libefivar.so libefiboot.so.0 libefiboot.so

efivar: $(EFIVAR_STAMP)

DOWNLOAD += $(EFIVAR_DOWNLOAD_STAMP)
efivar-download: $(EFIVAR_DOWNLOAD_STAMP)
$(EFIVAR_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream efivar ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(EFIVAR_TARBALL) $(EFIVAR_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(EFIVAR_SOURCE_STAMP)
efivar-source: $(EFIVAR_SOURCE_STAMP)
$(EFIVAR_SOURCE_STAMP): $(USER_TREE_STAMP) $(EFIVAR_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream efivar ===="
	$(Q) $(SCRIPTDIR)/extract-package $(EFIVAR_BUILD_DIR) $(DOWNLOADDIR)/$(EFIVAR_TARBALL)
	$(Q) touch $@

efivar-patch: $(EFIVAR_PATCH_STAMP)
$(EFIVAR_PATCH_STAMP): $(EFIVAR_SRCPATCHDIR)/* $(EFIVAR_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching efivar ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(EFIVAR_SRCPATCHDIR)/series $(EFIVAR_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
EFIVAR_NEW_FILES = $(shell test -d $(EFIVAR_DIR) && test -f $(EFIVAR_BUILD_STAMP) && \
	              find -L $(EFIVAR_DIR) -newer $(EFIVAR_BUILD_STAMP) -type f -print -quit)
endif

efivar-build: $(EFIVAR_BUILD_STAMP)
$(EFIVAR_BUILD_STAMP): $(EFIVAR_PATCH_STAMP) $(EFIVAR_NEW_FILES) $(POPT_BUILD_STAMP) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building efivar-$(EFIVAR_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(EFIVAR_DIR) CROSS_COMPILE=$(CROSSPREFIX)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(EFIVAR_DIR) CROSS_COMPILE=$(CROSSPREFIX) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

efivar-install: $(EFIVAR_INSTALL_STAMP)
$(EFIVAR_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(EFIVAR_BUILD_STAMP) $(POPT_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing efivar in $(SYSROOTDIR) ===="
	$(Q) for file in $(EFIVAR_BINS); do \
		cp -av $(DEV_SYSROOT)/usr/bin/$$file $(SYSROOTDIR)/usr/bin/ ; \
	     done
	$(Q) for file in $(EFIVAR_LIBS); do \
		if [ "$(ARCH)" == "arm64" ] || [ "$(ARCH)" == "x86_64" ]; then \
		    cp -av $(DEV_SYSROOT)/usr/lib64/$$file $(SYSROOTDIR)/usr/lib/ ; \
		else \
		    cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
		fi \
	     done
	$(Q) touch $@

USER_CLEAN += efivar-clean
efivar-clean:
	$(Q) rm -rf $(EFIVAR_BUILD_DIR)
	$(Q) rm -f $(EFIVAR_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += efivar-download-clean
efivar-download-clean:
	$(Q) rm -f $(EFIVAR_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(EFIVAR_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
