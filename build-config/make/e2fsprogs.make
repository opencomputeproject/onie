#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of e2fsprogs
#

E2FSPROGS_VERSION		= 1.42.8
E2FSPROGS_TARBALL		= e2fsprogs-$(E2FSPROGS_VERSION).tar.xz
E2FSPROGS_TARBALL_URLS		+= $(ONIE_MIRROR) \
				   https://www.kernel.org/pub/linux/kernel/people/tytso/e2fsprogs/v1.42.8
E2FSPROGS_BUILD_DIR		= $(MBUILDDIR)/e2fsprogs
E2FSPROGS_DIR			= $(E2FSPROGS_BUILD_DIR)/e2fsprogs-$(E2FSPROGS_VERSION)

E2FSPROGS_SRCPATCHDIR		= $(PATCHDIR)/e2fsprogs
E2FSPROGS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/e2fsprogs-download
E2FSPROGS_SOURCE_STAMP		= $(STAMPDIR)/e2fsprogs-source
E2FSPROGS_PATCH_STAMP		= $(STAMPDIR)/e2fsprogs-patch
E2FSPROGS_CONFIGURE_STAMP	= $(STAMPDIR)/e2fsprogs-configure
E2FSPROGS_BUILD_STAMP		= $(STAMPDIR)/e2fsprogs-build
E2FSPROGS_INSTALL_STAMP		= $(STAMPDIR)/e2fsprogs-install
E2FSPROGS_STAMP			= $(E2FSPROGS_SOURCE_STAMP) \
				  $(E2FSPROGS_PATCH_STAMP) \
				  $(E2FSPROGS_CONFIGURE_STAMP) \
				  $(E2FSPROGS_BUILD_STAMP) \
				  $(E2FSPROGS_INSTALL_STAMP)

PHONY += e2fsprogs e2fsprogs-download e2fsprogs-source e2fsprogs-patch \
	 e2fsprogs-configure e2fsprogs-build e2fsprogs-install e2fsprogs-clean \
	 e2fsprogs-download-clean

E2FSPROGS_LIBS = libuuid.so.1 libuuid.so.1.2

e2fsprogs: $(E2FSPROGS_STAMP)

DOWNLOAD += $(E2FSPROGS_DOWNLOAD_STAMP)
e2fsprogs-download: $(E2FSPROGS_DOWNLOAD_STAMP)
$(E2FSPROGS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream e2fsprogs ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(E2FSPROGS_TARBALL) $(E2FSPROGS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(E2FSPROGS_SOURCE_STAMP)
e2fsprogs-source: $(E2FSPROGS_SOURCE_STAMP)
$(E2FSPROGS_SOURCE_STAMP): $(TREE_STAMP) | $(E2FSPROGS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream e2fsprogs ===="
	$(Q) $(SCRIPTDIR)/extract-package $(E2FSPROGS_BUILD_DIR) $(DOWNLOADDIR)/$(E2FSPROGS_TARBALL)
	$(Q) touch $@

e2fsprogs-patch: $(E2FSPROGS_PATCH_STAMP)
$(E2FSPROGS_PATCH_STAMP): $(E2FSPROGS_SRCPATCHDIR)/* $(E2FSPROGS_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching e2fsprogs ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(E2FSPROGS_SRCPATCHDIR)/series $(E2FSPROGS_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
E2FSPROGS_NEW_FILES = $(shell test -d $(E2FSPROGS_DIR) && test -f $(E2FSPROGS_BUILD_STAMP) && \
	              find -L $(E2FSPROGS_DIR) -newer $(E2FSPROGS_BUILD_STAMP) -type f -print -quit)
endif

e2fsprogs-configure: $(E2FSPROGS_CONFIGURE_STAMP)
$(E2FSPROGS_CONFIGURE_STAMP): $(ZLIB_INSTALL_STAMP) $(LZO_INSTALL_STAMP) \
			      $(E2FSPROGS_PATCH_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure e2fsprogs-$(E2FSPROGS_VERSION) ===="
	$(Q) cd $(E2FSPROGS_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(E2FSPROGS_DIR)/configure			\
		--enable-elf-shlibs				\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET)				\
		--disable-tls					\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"
	$(Q) touch $@

e2fsprogs-build: $(E2FSPROGS_BUILD_STAMP)
$(E2FSPROGS_BUILD_STAMP): $(E2FSPROGS_NEW_FILES) $(E2FSPROGS_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building e2fsprogs-$(E2FSPROGS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(E2FSPROGS_DIR)/lib/uuid
	$(Q) touch $@

e2fsprogs-install: $(E2FSPROGS_INSTALL_STAMP)
$(E2FSPROGS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(E2FSPROGS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing e2fsprogs in $(DEV_SYSROOT) ===="
	$(Q) sudo PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(E2FSPROGS_DIR)/lib/uuid install
	$(Q) for file in $(E2FSPROGS_LIBS) ; do \
		sudo cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	done
	$(Q) touch $@

USERSPACE_CLEAN += e2fsprogs-clean
e2fsprogs-clean:
	$(Q) rm -rf $(E2FSPROGS_BUILD_DIR)
	$(Q) rm -f $(E2FSPROGS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

CLEAN_DOWNLOAD += e2fsprogs-download-clean
e2fsprogs-download-clean:
	$(Q) rm -f $(E2FSPROGS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/e2fsprogs*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
