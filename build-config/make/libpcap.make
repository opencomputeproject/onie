#-------------------------------------------------------------------------------
#
#  Copyright (C) 2024 Abhisit Sangjan <abhisit.sangjan@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of libpcap
#

LIBPCAP_VERSION			= 1.10.4
LIBPCAP_TARBALL			= libpcap-$(LIBPCAP_VERSION).tar.gz
LIBPCAP_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://www.tcpdump.org/release
LIBPCAP_BUILD_DIR	=  $(USER_BUILDDIR)/libpcap
LIBPCAP_DIR		=  $(LIBPCAP_BUILD_DIR)/libpcap-$(LIBPCAP_VERSION)

LIBPCAP_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/libpcap-download
LIBPCAP_SOURCE_STAMP	= $(USER_STAMPDIR)/libpcap-source
LIBPCAP_CONFIGURE_STAMP	= $(USER_STAMPDIR)/libpcap-configure
LIBPCAP_BUILD_STAMP	= $(USER_STAMPDIR)/libpcap-build
LIBPCAP_INSTALL_STAMP	= $(STAMPDIR)/libpcap-install
LIBPCAP_STAMP		= $(LIBPCAP_DOWNLOAD_STAMP)	\
			  $(LIBPCAP_SOURCE_STAMP)	\
			  $(LIBPCAP_CONFIGURE_STAMP)	\
			  $(LIBPCAP_BUILD_STAMP)	\
			  $(LIBPCAP_INSTALL_STAMP)

PHONY += libpcap \
	 libpcap-download \
	 libpcap-source \
	 libpcap-configure \
	 libpcap-build \
	 libpcap-install \
	 libpcap-clean \
	 libpcap-download-clean

libpcap: $(LIBPCAP_STAMP)

DOWNLOAD += $(LIBPCAP_DOWNLOAD_STAMP)

libpcap-download: $(LIBPCAP_DOWNLOAD_STAMP)
$(LIBPCAP_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream libpcap ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LIBPCAP_TARBALL) $(LIBPCAP_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LIBPCAP_SOURCE_STAMP)

libpcap-source: $(LIBPCAP_SOURCE_STAMP)
$(LIBPCAP_SOURCE_STAMP): $(USER_TREE_STAMP) | $(LIBPCAP_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream libpcap ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LIBPCAP_BUILD_DIR) $(DOWNLOADDIR)/$(LIBPCAP_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
LIBPCAP_NEW_FILES = $( \
			shell test -d $(LIBPCAP_DIR) && \
			test -f $(LIBPCAP_BUILD_STAMP) && \
			find -L $(LIBPCAP_DIR) -newer $(LIBPCAP_BUILD_STAMP) -type f -print -quit \
		)
endif

libpcap-configure: $(LIBPCAP_CONFIGURE_STAMP)
$(LIBPCAP_CONFIGURE_STAMP): $(LIBPCAP_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure libpcap-$(LIBPCAP_VERSION) ===="
	$(Q) cd $(LIBPCAP_DIR) &&		\
		$(LIBPCAP_DIR)/configure	\
		--host=$(TARGET)		\
		--prefix=/usr
	$(Q) touch $@

libpcap-build: $(LIBPCAP_BUILD_STAMP)
$(LIBPCAP_BUILD_STAMP): $(LIBPCAP_CONFIGURE_STAMP) $(LIBPCAP_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building libpcap-$(LIBPCAP_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'						\
		$(MAKE) -C $(LIBPCAP_DIR)					\
		CC=$(CROSSPREFIX)gcc
	$(Q) PATH='$(CROSSBIN):$(PATH)'						\
		$(MAKE) -C $(LIBPCAP_DIR) install DESTDIR=$(DEV_SYSROOT)	\
		CC=$(CROSSPREFIX)gcc
	$(Q) touch $@

libpcap-install: $(LIBPCAP_INSTALL_STAMP)
$(LIBPCAP_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LIBPCAP_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing libpcap in $(SYSROOTDIR) ===="
	$(Q) mkdir -p $(SYSROSYSROOTDIROT)/usr/lib/
	$(Q) cp -av $(DEV_SYSROOT)/usr/lib/libpcap.so $(SYSROOTDIR)/usr/lib/
	$(Q) cp -av $(DEV_SYSROOT)/usr/lib/libpcap.so.1 $(SYSROOTDIR)/usr/lib/
	$(Q) cp -av $(DEV_SYSROOT)/usr/lib/libpcap.so.$(LIBPCAP_VERSION) $(SYSROOTDIR)/usr/lib/
	$(Q) touch $@

USER_CLEAN += libpcap-clean
libpcap-clean:
	$(Q) rm -rf $(LIBPCAP_BUILD_DIR)
	$(Q) rm -f $(LIBPCAP_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += libpcap-download-clean
libpcap-download-clean:
	$(Q) rm -f $(LIBPCAP_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LIBPCAP_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
