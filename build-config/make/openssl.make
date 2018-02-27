#-------------------------------------------------------------------------------
#
#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of openssl
#

OPENSSL_VERSION		= 1.0.2l
OPENSSL_TARBALL		= openssl-$(OPENSSL_VERSION).tar.gz
OPENSSL_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://www.openssl.org/source
OPENSSL_BUILD_DIR	= $(USER_BUILDDIR)/openssl
OPENSSL_DIR		= $(OPENSSL_BUILD_DIR)/openssl-$(OPENSSL_VERSION)

OPENSSL_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/openssl-download
OPENSSL_SOURCE_STAMP	= $(USER_STAMPDIR)/openssl-source
OPENSSL_CONFIGURE_STAMP	= $(USER_STAMPDIR)/openssl-configure
OPENSSL_BUILD_STAMP	= $(USER_STAMPDIR)/openssl-build
OPENSSL_INSTALL_STAMP	= $(STAMPDIR)/openssl-install
OPENSSL_STAMP		= $(OPENSSL_SOURCE_STAMP) \
			  $(OPENSSL_CONFIGURE_STAMP) \
			  $(OPENSSL_BUILD_STAMP) \
			  $(OPENSSL_INSTALL_STAMP)

PHONY += openssl openssl-download openssl-source \
	 openssl-configure openssl-build openssl-install openssl-clean \
	 openssl-download-clean

OPENSSL_LIBS	= \
	engines \
	libcrypto.so libcrypto.so.1.0.0 \
	libssl.so libssl.so.1.0.0

OPENSSL_BINS	= openssl

openssl: $(OPENSSL_STAMP)

DOWNLOAD += $(OPENSSL_DOWNLOAD_STAMP)
openssl-download: $(OPENSSL_DOWNLOAD_STAMP)
$(OPENSSL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream openssl ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(OPENSSL_TARBALL) $(OPENSSL_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(OPENSSL_SOURCE_STAMP)
openssl-source: $(OPENSSL_SOURCE_STAMP)
$(OPENSSL_SOURCE_STAMP): $(USER_TREE_STAMP) | $(OPENSSL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream openssl ===="
	$(Q) $(SCRIPTDIR)/extract-package $(OPENSSL_BUILD_DIR) $(DOWNLOADDIR)/$(OPENSSL_TARBALL)
	$(Q) touch $@

openssl-configure: $(OPENSSL_CONFIGURE_STAMP)
$(OPENSSL_CONFIGURE_STAMP): $(OPENSSL_SOURCE_STAMP) $(ZLIB_BUILD_STAMP) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure openssl-$(OPENSSL_VERSION) ===="
	$(Q) cd $(OPENSSL_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(OPENSSL_DIR)/config				\
		--prefix=/usr					\
		--cross-compile-prefix=$(CROSSPREFIX)		\
		shared						\
		enable-ssl-trace				\
		zlib						\
		no-threads					\
		"$(ONIE_CFLAGS)"
	$(Q) touch $@

ifndef MAKE_CLEAN
OPENSSL_NEW_FILES = $(shell test -d $(OPENSSL_DIR) && test -f $(OPENSSL_BUILD_STAMP) && \
	              find -L $(OPENSSL_DIR) -newer $(OPENSSL_BUILD_STAMP) -type f \
			\! -name symlinks \! -name symlinks.o -print -quit)
endif

openssl-build: $(OPENSSL_BUILD_STAMP)
$(OPENSSL_BUILD_STAMP): $(OPENSSL_NEW_FILES) $(OPENSSL_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building openssl-$(OPENSSL_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(OPENSSL_DIR)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(OPENSSL_DIR) \
		INSTALL_PREFIX=$(DEV_SYSROOT) install_sw
	$(Q) for file in $(OPENSSL_LIBS) ; do \
		chmod u+w -R $(DEV_SYSROOT)/usr/lib/$$file ; \
	     done
	$(Q) touch $@

openssl-install: $(OPENSSL_INSTALL_STAMP)
$(OPENSSL_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(OPENSSL_BUILD_STAMP) $(ZLIB_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing openssl in $(SYSROOTDIR) ===="
	$(Q) cp -av $(DEV_SYSROOT)/usr/ssl $(SYSROOTDIR)/usr
	$(Q) for file in $(OPENSSL_LIBS) ; do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	     done
	$(Q) for file in $(OPENSSL_BINS) ; do \
		cp -av $(DEV_SYSROOT)/usr/bin/$$file $(SYSROOTDIR)/usr/bin/ ; \
	     done
	$(Q) touch $@

USER_CLEAN += openssl-clean
openssl-clean:
	$(Q) rm -rf $(OPENSSL_BUILD_DIR)
	$(Q) rm -f $(OPENSSL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += openssl-download-clean
openssl-download-clean:
	$(Q) rm -f $(OPENSSL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/openssl*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
