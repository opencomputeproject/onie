#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of tcpdump
#

TCPDUMP_VERSION		= 4.99.4
TCPDUMP_TARBALL		= tcpdump-$(TCPDUMP_VERSION).tar.gz
TCPDUMP_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://www.tcpdump.org/release
TCPDUMP_BUILD_DIR	= $(USER_BUILDDIR)/tcpdump
TCPDUMP_DIR		= $(TCPDUMP_BUILD_DIR)/tcpdump-$(TCPDUMP_VERSION)

TCPDUMP_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/tcpdump-download
TCPDUMP_SOURCE_STAMP	= $(USER_STAMPDIR)/tcpdump-source
TCPDUMP_CONFIGURE_STAMP	= $(USER_STAMPDIR)/tcpdump-configure
TCPDUMP_BUILD_STAMP	= $(USER_STAMPDIR)/tcpdump-build
TCPDUMP_INSTALL_STAMP	= $(STAMPDIR)/tcpdump-install
TCPDUMP_STAMP		= $(TCPDUMP_DOWNLOAD_STAMP) \
			  $(TCPDUMP_SOURCE_STAMP) \
			  $(TCPDUMP_CONFIGURE_STAMP) \
			  $(TCPDUMP_BUILD_STAMP) \
			  $(TCPDUMP_INSTALL_STAMP)

PHONY += tcpdump \
	 tcpdump-download \
	 tcpdump-source \
	 tcpdump-configure \
	 tcpdump-build \
	 tcpdump-install \
	 tcpdump-clean \
	 tcpdump-download-clean

tcpdump: $(TCPDUMP_STAMP)

DOWNLOAD += $(TCPDUMP_DOWNLOAD_STAMP)

tcpdump-download: $(TCPDUMP_DOWNLOAD_STAMP)
$(TCPDUMP_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream tcpdump ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(TCPDUMP_TARBALL) $(TCPDUMP_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(TCPDUMP_SOURCE_STAMP)

tcpdump-source: $(TCPDUMP_SOURCE_STAMP)
$(TCPDUMP_SOURCE_STAMP): $(USER_TREE_STAMP) | $(TCPDUMP_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream tcpdump ===="
	$(Q) $(SCRIPTDIR)/extract-package $(TCPDUMP_BUILD_DIR) $(DOWNLOADDIR)/$(TCPDUMP_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
TCPDUMP_NEW_FILES = $( \
			shell test -d $(TCPDUMP_DIR) && \
			test -f $(TCPDUMP_BUILD_STAMP) && \
			find -L $(TCPDUMP_DIR) -newer $(TCPDUMP_BUILD_STAMP) -type f -print -quit \
		)
endif

tcpdump-configure: $(TCPDUMP_CONFIGURE_STAMP)
$(TCPDUMP_CONFIGURE_STAMP): $(TCPDUMP_SOURCE_STAMP) $(LIBPCAP_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure tcpdump-$(TCPDUMP_VERSION) ===="
	$(Q) cd $(TCPDUMP_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(TCPDUMP_DIR)/configure			\
		--host=$(TARGET)				\
		--prefix=/usr					\
		CC=$(CROSSPREFIX)gcc				\
		LDFLAGS=$(ONIE_LDFLAGS)
	$(Q) touch $@

tcpdump-build: $(TCPDUMP_BUILD_STAMP)
$(TCPDUMP_BUILD_STAMP): $(TCPDUMP_CONFIGURE_STAMP) $(TCPDUMP_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building tcpdump-$(TCPDUMP_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'						\
		$(MAKE) -C $(TCPDUMP_DIR)					\
		CC=$(CROSSPREFIX)gcc						\
		CFLAGS="$(ONIE_CFLAGS) -I $(DEV_SYSROOT)/usr/include"
	$(Q) PATH='$(CROSSBIN):$(PATH)'
		$(MAKE) -C $(TCPDUMP_DIR) install DESTDIR=$(DEV_SYSROOT)	\
		CC=$(CROSSPREFIX)gcc
	$(Q) touch $@

tcpdump-install: $(TCPDUMP_INSTALL_STAMP)
$(TCPDUMP_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(TCPDUMP_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing tcpdump in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROOTDIR)/usr/bin/
	$(Q) cp -av $(DEV_SYSROOT)/usr/bin/tcpdump $(SYSROOTDIR)/usr/bin/
	$(Q) touch $@

USER_CLEAN += tcpdump-clean
tcpdump-clean:
	$(Q) rm -rf $(TCPDUMP_BUILD_DIR)
	$(Q) rm -f $(TCPDUMP_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += tcpdump-download-clean
tcpdump-download-clean:
	$(Q) rm -f $(TCPDUMP_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(TCPDUMP_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
