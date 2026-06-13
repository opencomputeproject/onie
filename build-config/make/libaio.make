#-------------------------------------------------------------------------------
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of libaio
#
# libaio provides the Linux asynchronous I/O interface.  It is required
# by lvm2 (>= 2.03, which uses it for its bcache I/O engine).

LIBAIO_VERSION		= 0.3.113
LIBAIO_TARBALL		= libaio-$(LIBAIO_VERSION).tar.gz
LIBAIO_TARBALL_URLS	+= $(ONIE_MIRROR) https://releases.pagure.org/libaio
LIBAIO_BUILD_DIR	= $(USER_BUILDDIR)/libaio
LIBAIO_DIR		= $(LIBAIO_BUILD_DIR)/libaio-$(LIBAIO_VERSION)

LIBAIO_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/libaio-$(LIBAIO_VERSION)-download
LIBAIO_SOURCE_STAMP	= $(USER_STAMPDIR)/libaio-source
LIBAIO_BUILD_STAMP	= $(USER_STAMPDIR)/libaio-build
LIBAIO_INSTALL_STAMP	= $(STAMPDIR)/libaio-install
LIBAIO_STAMP		= $(LIBAIO_SOURCE_STAMP) \
			  $(LIBAIO_BUILD_STAMP) \
			  $(LIBAIO_INSTALL_STAMP)

PHONY += libaio libaio-download libaio-source \
	 libaio-build libaio-install libaio-clean libaio-download-clean

# libaio builds via a plain Makefile (no ./configure); soname is
# libaio.so.1, real lib libaio.so.1.$(minor).$(micro) = libaio.so.1.0.2.
LIBAIO_LIBS = libaio.so libaio.so.1 libaio.so.1.0.2

libaio: $(LIBAIO_STAMP)

DOWNLOAD += $(LIBAIO_DOWNLOAD_STAMP)
libaio-download: $(LIBAIO_DOWNLOAD_STAMP)
$(LIBAIO_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream libaio ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LIBAIO_TARBALL) $(LIBAIO_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LIBAIO_SOURCE_STAMP)
libaio-source: $(LIBAIO_SOURCE_STAMP)
$(LIBAIO_SOURCE_STAMP): $(USER_TREE_STAMP) | $(LIBAIO_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream libaio ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LIBAIO_BUILD_DIR) $(DOWNLOADDIR)/$(LIBAIO_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
LIBAIO_NEW_FILES = $(shell test -d $(LIBAIO_DIR) && test -f $(LIBAIO_BUILD_STAMP) && \
		      find -L $(LIBAIO_DIR) -newer $(LIBAIO_BUILD_STAMP) -type f -print -quit)
endif

libaio-build: $(LIBAIO_BUILD_STAMP)
$(LIBAIO_BUILD_STAMP): $(LIBAIO_SOURCE_STAMP) $(LIBAIO_NEW_FILES) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building libaio-$(LIBAIO_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(LIBAIO_DIR) \
		CC=$(CROSSPREFIX)gcc prefix=/usr
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(LIBAIO_DIR) \
		CC=$(CROSSPREFIX)gcc prefix=/usr DESTDIR=$(DEV_SYSROOT) install
	$(Q) touch $@

libaio-install: $(LIBAIO_INSTALL_STAMP)
$(LIBAIO_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LIBAIO_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing libaio in $(SYSROOTDIR) ===="
	$(Q) for file in $(LIBAIO_LIBS) ; do \
		cp -a $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	done
	$(Q) touch $@

USER_CLEAN += libaio-clean
libaio-clean:
	$(Q) rm -rf $(LIBAIO_BUILD_DIR)
	$(Q) rm -f $(LIBAIO_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += libaio-download-clean
libaio-download-clean:
	$(Q) rm -f $(LIBAIO_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LIBAIO_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
