#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of dosfstools
#

DOSFSTOOLS_VERSION		= 3.0.26
DOSFSTOOLS_TARBALL		= dosfstools-$(DOSFSTOOLS_VERSION).tar.xz
DOSFSTOOLS_TARBALL_URLS		+= $(ONIE_MIRROR) http://daniel-baumann.ch/files/software/dosfstools
DOSFSTOOLS_BUILD_DIR		= $(USER_BUILDDIR)/dosfstools
DOSFSTOOLS_DIR			= $(DOSFSTOOLS_BUILD_DIR)/dosfstools-$(DOSFSTOOLS_VERSION)

DOSFSTOOLS_SRCPATCHDIR		= $(PATCHDIR)/dosfstools
DOSFSTOOLS_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/dosfstools-download
DOSFSTOOLS_SOURCE_STAMP		= $(USER_STAMPDIR)/dosfstools-source
DOSFSTOOLS_PATCH_STAMP		= $(USER_STAMPDIR)/dosfstools-patch
DOSFSTOOLS_BUILD_STAMP		= $(USER_STAMPDIR)/dosfstools-build
DOSFSTOOLS_INSTALL_STAMP	= $(STAMPDIR)/dosfstools-install
DOSFSTOOLS_STAMP		= $(DOSFSTOOLS_SOURCE_STAMP) \
				  $(DOSFSTOOLS_PATCH_STAMP) \
				  $(DOSFSTOOLS_BUILD_STAMP) \
				  $(DOSFSTOOLS_INSTALL_STAMP)

DOSFSTOOLS_PROGRAMS	= fsck.fat dosfsck fsck.msdos fsck.vfat \
				mkfs.fat mkdosfs mkfs.msdos mkfs.vfat \
				fatlabel dosfslabel

PHONY += dosfstools dosfstools-download dosfstools-source dosfstools-patch \
	dosfstools-build dosfstools-install dosfstools-clean dosfstools-download-clean

dosfstools: $(DOSFSTOOLS_STAMP)

DOWNLOAD += $(DOSFSTOOLS_DOWNLOAD_STAMP)
dosfstools-download: $(DOSFSTOOLS_DOWNLOAD_STAMP)
$(DOSFSTOOLS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream dosfstools ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(DOSFSTOOLS_TARBALL) $(DOSFSTOOLS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(DOSFSTOOLS_SOURCE_STAMP)
dosfstools-source: $(DOSFSTOOLS_SOURCE_STAMP)
$(DOSFSTOOLS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(DOSFSTOOLS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream dosfstools ===="
	$(Q) $(SCRIPTDIR)/extract-package $(DOSFSTOOLS_BUILD_DIR) $(DOWNLOADDIR)/$(DOSFSTOOLS_TARBALL)
	$(Q) touch $@

dosfstools-patch: $(DOSFSTOOLS_PATCH_STAMP)
$(DOSFSTOOLS_PATCH_STAMP): $(DOSFSTOOLS_SRCPATCHDIR)/* $(DOSFSTOOLS_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching dosfstools ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(DOSFSTOOLS_SRCPATCHDIR)/series $(DOSFSTOOLS_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
DOSFSTOOLS_NEW_FILES = $(shell test -d $(DOSFSTOOLS_DIR) && test -f $(DOSFSTOOLS_BUILD_STAMP) && \
	              find -L $(DOSFSTOOLS_DIR) -newer $(DOSFSTOOLS_BUILD_STAMP) -type f \
			\! -name filelist-rpm -print -quit)
endif

DOSFSTOOLS_MAKE_VARS = \
	CC=$(CROSSPREFIX)gcc LD=$(CROSSPREFIX)ld \
	CFLAGS="$(ONIE_CFLAGS)" LDFLAGS="$(ONIE_LDFLAGS)" \
	DESTDIR=$(DEV_SYSROOT) PREFIX=/usr

dosfstools-build: $(DOSFSTOOLS_BUILD_STAMP)
$(DOSFSTOOLS_BUILD_STAMP): $(DOSFSTOOLS_PATCH_STAMP) $(DOSFSTOOLS_NEW_FILES) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building dosfstools-$(DOSFSTOOLS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(DOSFSTOOLS_DIR) $(DOSFSTOOLS_MAKE_VARS)
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(DOSFSTOOLS_DIR) $(DOSFSTOOLS_MAKE_VARS) \
		install-symlinks
	$(Q) touch $@

dosfstools-install: $(DOSFSTOOLS_INSTALL_STAMP)
$(DOSFSTOOLS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(DOSFSTOOLS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing dosfstools programs in $(SYSROOTDIR) ===="
	$(Q) for file in $(DOSFSTOOLS_PROGRAMS); do \
		cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin ; \
	     done
	$(Q) touch $@

USER_CLEAN += dosfstools-clean
dosfstools-clean:
	$(Q) rm -rf $(DOSFSTOOLS_BUILD_DIR)
	$(Q) rm -f $(DOSFSTOOLS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += dosfstools-download-clean
dosfstools-download-clean:
	$(Q) rm -f $(DOSFSTOOLS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(DOSFSTOOLS_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
