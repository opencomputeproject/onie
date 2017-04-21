#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of parted
#

PARTED_VERSION		= 3.1
PARTED_TARBALL		= parted-$(PARTED_VERSION).tar.xz
PARTED_TARBALL_URLS	+= $(ONIE_MIRROR) http://ftp.gnu.org/gnu/parted/
PARTED_BUILD_DIR	= $(USER_BUILDDIR)/parted
PARTED_DIR		= $(PARTED_BUILD_DIR)/parted-$(PARTED_VERSION)

PARTED_SRCPATCHDIR	= $(PATCHDIR)/parted
PARTED_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/parted-download
PARTED_SOURCE_STAMP	= $(USER_STAMPDIR)/parted-source
PARTED_CONFIGURE_STAMP	= $(USER_STAMPDIR)/parted-configure
PARTED_BUILD_STAMP	= $(USER_STAMPDIR)/parted-build
PARTED_INSTALL_STAMP	= $(STAMPDIR)/parted-install

PARTED_STAMP		= $(PARTED_SOURCE_STAMP) \
			  $(PARTED_CONFIGURE_STAMP) \
			  $(PARTED_BUILD_STAMP) \
			  $(PARTED_INSTALL_STAMP)

PHONY += parted parted-download parted-source \
	 parted-configure parted-build parted-install parted-clean \
	 parted-download-clean

PARTED_SBIN = parted partprobe

parted: $(PARTED_STAMP)

DOWNLOAD += $(PARTED_DOWNLOAD_STAMP)
parted-download: $(PARTED_DOWNLOAD_STAMP)
$(PARTED_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream parted ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(PARTED_TARBALL) $(PARTED_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(PARTED_SOURCE_STAMP)
parted-source: $(PARTED_SOURCE_STAMP)
$(PARTED_SOURCE_STAMP): $(USER_TREE_STAMP) | $(PARTED_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream parted ===="
	$(Q) $(SCRIPTDIR)/extract-package $(PARTED_BUILD_DIR) $(DOWNLOADDIR)/$(PARTED_TARBALL)
	$(Q) touch $@

parted-configure: $(PARTED_CONFIGURE_STAMP)
$(PARTED_CONFIGURE_STAMP): $(PARTED_SOURCE_STAMP) $(E2FSPROGS_BUILD_STAMP) $(LVM2_BUILD_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure parted-$(PARTED_VERSION) ===="
	$(Q) cd $(PARTED_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(PARTED_DIR)/configure				\
		--prefix=/usr					\
		--host=$(TARGET)				\
		--enable-device-mapper				\
		--disable-mtrace				\
		--disable-selinux				\
		--disable-nls					\
		--disable-shared				\
		--disable-dynamic-loading			\
		--without-readline				\
		CC=$(CROSSPREFIX)gcc				\
		CPPFLAGS="$(ONIE_CPPFLAGS)"			\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

parted-build: $(PARTED_BUILD_STAMP)
$(PARTED_BUILD_STAMP): $(PARTED_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building parted-$(PARTED_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(PARTED_DIR)
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(PARTED_DIR) install DESTDIR=$(DEV_SYSROOT)
	$(Q) touch $@

parted-install: $(PARTED_INSTALL_STAMP)
$(PARTED_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(PARTED_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing parted in $(SYSROOTDIR) ===="
	$(Q) for f in $(PARTED_SBIN) ; do \
		cp -a $(DEV_SYSROOT)/usr/sbin/$$f $(SYSROOTDIR)/usr/sbin ; \
	done
	$(Q) touch $@

USER_CLEAN += parted-clean
parted-clean:
	$(Q) rm -rf $(PARTED_BUILD_DIR)
	$(Q) rm -f $(PARTED_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += parted-download-clean
parted-download-clean:
	$(Q) rm -f $(PARTED_DOWNLOAD_STAMP) $(DOWNLOADDIR)/parted*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
