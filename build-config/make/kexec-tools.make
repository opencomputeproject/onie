#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of kexec-tools
#

KEXEC_VERSION		= 2.0.9
KEXEC_TARBALL		= kexec-tools-$(KEXEC_VERSION).tar.xz
KEXEC_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://www.kernel.org/pub/linux/utils/kernel/kexec
KEXEC_BUILD_DIR		= $(USER_BUILDDIR)/kexec-tools
KEXEC_DIR		= $(KEXEC_BUILD_DIR)/kexec-tools-$(KEXEC_VERSION)

KEXEC_SRCPATCHDIR	= $(PATCHDIR)/kexec-tools
KEXEC_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/kexec-tools-download
KEXEC_SOURCE_STAMP	= $(USER_STAMPDIR)/kexec-tools-source
KEXEC_PATCH_STAMP	= $(USER_STAMPDIR)/kexec-tools-patch
KEXEC_CONFIGURE_STAMP	= $(USER_STAMPDIR)/kexec-tools-configure
KEXEC_BUILD_STAMP	= $(USER_STAMPDIR)/kexec-tools-build
KEXEC_INSTALL_STAMP	= $(STAMPDIR)/kexec-tools-install
KEXEC_STAMP		= $(KEXEC_SOURCE_STAMP) \
			  $(KEXEC_PATCH_STAMP) \
			  $(KEXEC_CONFIGURE_STAMP) \
			  $(KEXEC_BUILD_STAMP) \
			  $(KEXEC_INSTALL_STAMP)

PHONY += kexec-tools kexec-tools-download kexec-tools-source kexec-tools-patch \
	 kexec-tools-configure kexec-tools-build kexec-tools-install kexec-tools-clean \
	 kexec-tools-download-clean

KEXEC_SBIN = kexec kdump

kexec-tools: $(KEXEC_STAMP)

DOWNLOAD += $(KEXEC_DOWNLOAD_STAMP)
kexec-tools-download: $(KEXEC_DOWNLOAD_STAMP)
$(KEXEC_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream kexec-tools ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(KEXEC_TARBALL) $(KEXEC_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(KEXEC_SOURCE_STAMP)
kexec-tools-source: $(KEXEC_SOURCE_STAMP)
$(KEXEC_SOURCE_STAMP): $(USER_TREE_STAMP) | $(KEXEC_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream kexec-tools ===="
	$(Q) $(SCRIPTDIR)/extract-package $(KEXEC_BUILD_DIR) $(DOWNLOADDIR)/$(KEXEC_TARBALL)
	$(Q) touch $@

kexec-tools-patch: $(KEXEC_PATCH_STAMP)
$(KEXEC_PATCH_STAMP): $(KEXEC_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching kexec-tools-$(KEXEC_VERSION) ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(KEXEC_SRCPATCHDIR)/series $(KEXEC_DIR)
	$(Q) touch $@

# For PowerPC add booke support
powerpc_KEXEC_CONFIG_OPTS = --with-booke

kexec-tools-configure: $(KEXEC_CONFIGURE_STAMP)
$(KEXEC_CONFIGURE_STAMP): $(ZLIB_BUILD_STAMP) \
				$(KEXEC_PATCH_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure kexec-tools-$(KEXEC_VERSION) ===="
	$(Q) cd $(KEXEC_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(KEXEC_DIR)/configure				\
		--prefix=/usr					\
		--host=$(TARGET)				\
		$($(ARCH)_KEXEC_CONFIG_OPTS)			\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"
	$(Q) touch $@

ifndef MAKE_CLEAN
KEXEC_NEW_FILES = $(shell test -d $(KEXEC_DIR) && test -f $(KEXEC_BUILD_STAMP) && \
	              find -L $(KEXEC_DIR) -newer $(KEXEC_BUILD_STAMP) -type f \
			\! -name symlinks \! -name symlinks.o -print -quit)
endif

kexec-tools-build: $(KEXEC_BUILD_STAMP)
$(KEXEC_BUILD_STAMP): $(KEXEC_NEW_FILES) $(KEXEC_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building kexec-tools-$(KEXEC_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(KEXEC_DIR) DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(KEXEC_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

kexec-tools-install: $(KEXEC_INSTALL_STAMP)
$(KEXEC_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(KEXEC_BUILD_STAMP)  $(ZLIB_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing kexec-tools in $(SYSROOTDIR) ===="
	$(Q) for f in $(KEXEC_SBIN) ; do \
		cp -a $(DEV_SYSROOT)/usr/sbin/$$f $(SYSROOTDIR)/usr/sbin ; \
	done
	$(Q) touch $@

USER_CLEAN += kexec-tools-clean
kexec-tools-clean:
	$(Q) rm -rf $(KEXEC_BUILD_DIR)
	$(Q) rm -f $(KEXEC_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += kexec-tools-download-clean
kexec-tools-download-clean:
	$(Q) rm -f $(KEXEC_DOWNLOAD_STAMP) $(DOWNLOADDIR)/kexec-tools*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
