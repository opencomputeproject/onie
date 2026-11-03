#-------------------------------------------------------------------------------
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of libmnl
#
# libmnl is a minimal netlink library (netfilter.org).  It is required
# by ethtool's netlink interface (the default since ethtool moved most
# functionality to netlink).

LIBMNL_VERSION		= 1.0.5
LIBMNL_TARBALL		= libmnl-$(LIBMNL_VERSION).tar.bz2
LIBMNL_TARBALL_URLS	+= $(ONIE_MIRROR) https://www.netfilter.org/projects/libmnl/files
LIBMNL_BUILD_DIR	= $(USER_BUILDDIR)/libmnl
LIBMNL_DIR		= $(LIBMNL_BUILD_DIR)/libmnl-$(LIBMNL_VERSION)

LIBMNL_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/libmnl-$(LIBMNL_VERSION)-download
LIBMNL_SOURCE_STAMP	= $(USER_STAMPDIR)/libmnl-source
LIBMNL_CONFIGURE_STAMP	= $(USER_STAMPDIR)/libmnl-configure
LIBMNL_BUILD_STAMP	= $(USER_STAMPDIR)/libmnl-build
LIBMNL_INSTALL_STAMP	= $(STAMPDIR)/libmnl-install
LIBMNL_STAMP		= $(LIBMNL_SOURCE_STAMP) \
			  $(LIBMNL_CONFIGURE_STAMP) \
			  $(LIBMNL_BUILD_STAMP) \
			  $(LIBMNL_INSTALL_STAMP)

PHONY += libmnl libmnl-download libmnl-source libmnl-configure \
	 libmnl-build libmnl-install libmnl-clean libmnl-download-clean

LIBMNL_LIBS = libmnl.so libmnl.so.0 libmnl.so.0.2.0

libmnl: $(LIBMNL_STAMP)

DOWNLOAD += $(LIBMNL_DOWNLOAD_STAMP)
libmnl-download: $(LIBMNL_DOWNLOAD_STAMP)
$(LIBMNL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream libmnl ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LIBMNL_TARBALL) $(LIBMNL_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LIBMNL_SOURCE_STAMP)
libmnl-source: $(LIBMNL_SOURCE_STAMP)
$(LIBMNL_SOURCE_STAMP): $(USER_TREE_STAMP) | $(LIBMNL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream libmnl ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LIBMNL_BUILD_DIR) $(DOWNLOADDIR)/$(LIBMNL_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
LIBMNL_NEW_FILES = $(shell test -d $(LIBMNL_DIR) && test -f $(LIBMNL_BUILD_STAMP) && \
		      find -L $(LIBMNL_DIR) -newer $(LIBMNL_BUILD_STAMP) -type f -print -quit)
endif

libmnl-configure: $(LIBMNL_CONFIGURE_STAMP)
$(LIBMNL_CONFIGURE_STAMP): $(LIBMNL_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure libmnl-$(LIBMNL_VERSION) ===="
	$(Q) cd $(LIBMNL_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(LIBMNL_DIR)/configure				\
		--enable-shared					\
		--prefix=/usr					\
		--host=$(TARGET)				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"
	$(Q) touch $@

libmnl-build: $(LIBMNL_BUILD_STAMP)
$(LIBMNL_BUILD_STAMP): $(LIBMNL_CONFIGURE_STAMP) $(LIBMNL_NEW_FILES)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building libmnl-$(LIBMNL_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(LIBMNL_DIR) DESTDIR=$(DEV_SYSROOT)
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(LIBMNL_DIR) DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

libmnl-install: $(LIBMNL_INSTALL_STAMP)
$(LIBMNL_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LIBMNL_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing libmnl in $(SYSROOTDIR) ===="
	$(Q) for file in $(LIBMNL_LIBS) ; do \
		cp -a $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	done
	$(Q) touch $@

USER_CLEAN += libmnl-clean
libmnl-clean:
	$(Q) rm -rf $(LIBMNL_BUILD_DIR)
	$(Q) rm -f $(LIBMNL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += libmnl-download-clean
libmnl-download-clean:
	$(Q) rm -f $(LIBMNL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LIBMNL_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
