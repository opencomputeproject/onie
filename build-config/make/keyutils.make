#-------------------------------------------------------------------------------
#
#  Copyright (C) 2018 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of keyutils
#

KEYUTILS_VERSION	= 1.5.10
KEYUTILS_TARBALL	= keyutils-$(KEYUTILS_VERSION).tar.bz2
KEYUTILS_TARBALL_URLS	+= $(ONIE_MIRROR) \
			   https://people.redhat.com/~dhowells/keyutils
KEYUTILS_BUILD_DIR	= $(USER_BUILDDIR)/keyutils
KEYUTILS_DIR		= $(KEYUTILS_BUILD_DIR)/keyutils-$(KEYUTILS_VERSION)

KEYUTILS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/keyutils-download
KEYUTILS_SOURCE_STAMP	= $(USER_STAMPDIR)/keyutils-source
KEYUTILS_BUILD_STAMP	= $(USER_STAMPDIR)/keyutils-build
KEYUTILS_INSTALL_STAMP	= $(STAMPDIR)/keyutils-install
KEYUTILS_STAMP		= $(KEYUTILS_SOURCE_STAMP) \
			  $(KEYUTILS_BUILD_STAMP) \
			  $(KEYUTILS_INSTALL_STAMP)

PHONY += keyutils keyutils-download keyutils-source \
	 keyutils-build keyutils-install keyutils-clean \
	 keyutils-download-clean

KEYUTILS_BIN = keyctl
KEYUTILS_LIB = libkeyutils.so libkeyutils.so.1 libkeyutils.so.1.6

keyutils: $(KEYUTILS_STAMP)

DOWNLOAD += $(KEYUTILS_DOWNLOAD_STAMP)
keyutils-download: $(KEYUTILS_DOWNLOAD_STAMP)
$(KEYUTILS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream keyutils ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(KEYUTILS_TARBALL) $(KEYUTILS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(KEYUTILS_SOURCE_STAMP)
keyutils-source: $(KEYUTILS_SOURCE_STAMP)
$(KEYUTILS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(KEYUTILS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream keyutils ===="
	$(Q) $(SCRIPTDIR)/extract-package $(KEYUTILS_BUILD_DIR) $(DOWNLOADDIR)/$(KEYUTILS_TARBALL)
	$(Q) touch $@

KEYUTILS_BUILD_OPTS	= \
	DESTDIR=$(DEV_SYSROOT)    \
	CC=$(CROSSPREFIX)gcc      \
	CFLAGS="$(ONIE_CFLAGS)"   \
	LDFLAGS="$(ONIE_LDFLAGS)" \
	LIBDIR=/usr/lib           \
	USRLIBDIR=/usr/lib

keyutils-build: $(KEYUTILS_BUILD_STAMP)
$(KEYUTILS_BUILD_STAMP): $(KEYUTILS_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building keyutils-$(KEYUTILS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(KEYUTILS_DIR) $(KEYUTILS_BUILD_OPTS)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(KEYUTILS_DIR) $(KEYUTILS_BUILD_OPTS) install
	$(Q) touch $@

keyutils-install: $(KEYUTILS_INSTALL_STAMP)
$(KEYUTILS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(KEYUTILS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing keyutils in $(SYSROOTDIR) ===="
	$(Q) for f in $(KEYUTILS_BIN) ; do \
		cp -a $(DEV_SYSROOT)/bin/$$f $(SYSROOTDIR)/usr/bin ; \
	done
	$(Q) for f in $(KEYUTILS_LIB) ; do \
		cp -a $(DEV_SYSROOT)/usr/lib/$$f $(SYSROOTDIR)/usr/lib ; \
	done
	$(Q) touch $@

USER_CLEAN += keyutils-clean
keyutils-clean:
	$(Q) rm -rf $(KEYUTILS_BUILD_DIR)
	$(Q) rm -f $(KEYUTILS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += keyutils-download-clean
keyutils-download-clean:
	$(Q) rm -f $(KEYUTILS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/keyutils*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
