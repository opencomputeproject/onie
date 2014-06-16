#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of e2fsprogs
#

E2FSPROGS_VERSION		= 1.42.8
E2FSPROGS_TARBALL		= $(UPSTREAMDIR)/e2fsprogs-$(E2FSPROGS_VERSION).tar.xz
E2FSPROGS_BUILD_DIR		= $(MBUILDDIR)/e2fsprogs
E2FSPROGS_DIR			= $(E2FSPROGS_BUILD_DIR)/e2fsprogs-$(E2FSPROGS_VERSION)

E2FSPROGS_SRCPATCHDIR		=	 $(PATCHDIR)/e2fsprogs
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

PHONY += e2fsprogs e2fsprogs-source e2fsprogs-patch e2fsprogs-configure\
	e2fsprogs-build e2fsprogs-install e2fsprogs-clean

e2fsprogs: $(E2FSPROGS_STAMP)

SOURCE += $(E2FSPROGS_SOURCE_STAMP)

e2fsprogs-source: $(E2FSPROGS_SOURCE_STAMP)
$(E2FSPROGS_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting and extracting upstream e2fsprogs ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(E2FSPROGS_TARBALL).sha1
	$(Q) rm -rf $(E2FSPROGS_BUILD_DIR)
	$(Q) mkdir -p $(E2FSPROGS_BUILD_DIR)
	$(Q) cd $(E2FSPROGS_BUILD_DIR) && tar xf $(E2FSPROGS_TARBALL)
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
$(E2FSPROGS_CONFIGURE_STAMP): $(UCLIBC_INSTALL_STAMP) $(ZLIB_INSTALL_STAMP) \
			      $(LZO_INSTALL_STAMP) $(E2FSPROGS_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure e2fsprogs-$(E2FSPROGS_VERSION) ===="
	$(Q) cd $(E2FSPROGS_DIR) && PATH='$(CROSSBIN):$(PATH)'   \
		$(E2FSPROGS_DIR)/configure			 \
		--prefix=$(UCLIBC_DEV_SYSROOT)/usr     		 \
		--host=$(TARGET)				 \
		--disable-tls					 \
		CC=$(CROSSPREFIX)gcc				 \
		CFLAGS="-Os -I$(KERNEL_HEADERS) $(UCLIBC_FLAGS)" \
		LDFLAGS="$(UCLIBC_FLAGS)"
	$(Q) touch $@

e2fsprogs-build: $(E2FSPROGS_BUILD_STAMP)
$(E2FSPROGS_BUILD_STAMP): $(E2FSPROGS_NEW_FILES) $(E2FSPROGS_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building e2fsprogs-$(E2FSPROGS_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(E2FSPROGS_DIR)
	$(Q) touch $@

e2fsprogs-install: $(E2FSPROGS_INSTALL_STAMP)
$(E2FSPROGS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(E2FSPROGS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing e2fsprogs in $(UCLIBC_DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(E2FSPROGS_DIR) install
	$(Q) cp $(UCLIBC_DEV_SYSROOT)/usr/sbin/mke2fs $(SYSROOTDIR)/sbin
	$(Q) $(CROSSBIN)/$(CROSSPREFIX)strip $(SYSROOTDIR)/sbin/mke2fs
	$(Q) cd $(SYSROOTDIR)/sbin && ln -fs mke2fs mkfs.ext2
	$(Q) cd $(SYSROOTDIR)/sbin && ln -fs mke2fs mkfs.ext3
	$(Q) touch $@

CLEAN += e2fsprogs-clean
e2fsprogs-clean:
	$(Q) rm -rf $(E2FSPROGS_BUILD_DIR)
	$(Q) rm -f $(E2FSPROGS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
