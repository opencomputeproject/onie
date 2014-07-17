#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of grub
#

GRUB_VERSION		= e4a1fe391
GRUB_TARBALL		= grub-$(GRUB_VERSION).tar.xz
GRUB_TARBALL_URLS	+= $(ONIE_MIRROR) http://git.savannah.gnu.org/cgit/grub.git/snapshot/
GRUB_BUILD_DIR		= $(MBUILDDIR)/grub
GRUB_DIR		= $(GRUB_BUILD_DIR)/grub-$(GRUB_VERSION)

GRUB_SRCPATCHDIR	= $(PATCHDIR)/grub
GRUB_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/grub-download
GRUB_SOURCE_STAMP	= $(STAMPDIR)/grub-source
GRUB_PATCH_STAMP	= $(STAMPDIR)/grub-patch
GRUB_CONFIGURE_STAMP	= $(STAMPDIR)/grub-configure
GRUB_BUILD_STAMP	= $(STAMPDIR)/grub-build
GRUB_INSTALL_STAMP	= $(STAMPDIR)/grub-install

GRUB_STAMP		= $(GRUB_SOURCE_STAMP) \
			  $(GRUB_PATCH_STAMP) \
			  $(GRUB_CONFIGURE_STAMP) \
			  $(GRUB_BUILD_STAMP) \
			  $(GRUB_INSTALL_STAMP)

PHONY += grub grub-download grub-source grub-patch \
	 grub-configure grub-build grub-install grub-clean \
	 grub-download-clean

GRUB_SBIN = grub-install grub-bios-setup grub-probe grub-reboot grub-set-default
GRUB_BIN = grub-mkrelpath grub-mkimage grub-editenv

grub: $(GRUB_STAMP)

DOWNLOAD += $(GRUB_DOWNLOAD_STAMP)
grub-download: $(GRUB_DOWNLOAD_STAMP)
$(GRUB_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream grub ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(GRUB_TARBALL) $(GRUB_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(GRUB_SOURCE_STAMP)
grub-source: $(GRUB_SOURCE_STAMP)
$(GRUB_SOURCE_STAMP): $(TREE_STAMP) | $(GRUB_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream grub ===="
	$(Q) $(SCRIPTDIR)/extract-package $(GRUB_BUILD_DIR) $(DOWNLOADDIR)/$(GRUB_TARBALL)
	$(Q) touch $@

grub-patch: $(GRUB_PATCH_STAMP)
$(GRUB_PATCH_STAMP): $(GRUB_SOURCE_STAMP) $(LVM2_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching grub-$(GRUB_VERSION) ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(GRUB_SRCPATCHDIR)/series $(GRUB_DIR)
	$(Q) touch $@

grub-configure: $(GRUB_CONFIGURE_STAMP)
$(GRUB_CONFIGURE_STAMP): $(GRUB_PATCH_STAMP) $(LVM2_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-$(GRUB_VERSION) ===="
	$(Q) cd $(GRUB_DIR) && ./autogen.sh
	$(Q) cd $(GRUB_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_DIR)/configure				\
		--prefix=/usr					\
		--host=$(TARGET)				\
		--enable-device-mapper				\
		--disable-nls					\
		--disable-efiemu				\
		--disable-grub-mkfont				\
		--disable-grub-themes				\
		CC=$(CROSSPREFIX)gcc				\
		CPPFLAGS="$(ONIE_CPPFLAGS)"			\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

grub-build: $(GRUB_BUILD_STAMP)
$(GRUB_BUILD_STAMP): $(GRUB_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_DIR)
	$(Q) touch $@

grub-install: $(GRUB_INSTALL_STAMP)
$(GRUB_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(GRUB_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing grub in $(DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(GRUB_DIR) install DESTDIR=$(DEV_SYSROOT)
	$(Q) cp -a $(DEV_SYSROOT)/usr/lib/grub $(SYSROOTDIR)/usr/lib
	$(Q) cp -a $(DEV_SYSROOT)/usr/share/grub $(SYSROOTDIR)/usr/share
	$(Q) for f in $(GRUB_SBIN) ; do \
		cp -a $(DEV_SYSROOT)/usr/sbin/$$f $(SYSROOTDIR)/usr/sbin ; \
	done
	$(Q) for f in $(GRUB_BIN) ; do \
		cp -a $(DEV_SYSROOT)/usr/bin/$$f $(SYSROOTDIR)/usr/bin ; \
	done
	$(Q) touch $@

USERSPACE_CLEAN += grub-clean
grub-clean:
	$(Q) rm -rf $(GRUB_BUILD_DIR)
	$(Q) rm -f $(GRUB_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += grub-download-clean
grub-download-clean:
	$(Q) rm -f $(GRUB_DOWNLOAD_STAMP) $(DOWNLOADDIR)/grub*

# ---------------------------------------------------------------------------
# grub-host build rules

ifeq ($(PXE_EFI64_ENABLE),yes)

# PXE_EFI64 requires a host build of GRUB also
GRUB_HOST_BUILD_DIR		= $(MBUILDDIR)/grub-host
GRUB_HOST_DIR			= $(GRUB_HOST_BUILD_DIR)/grub-$(GRUB_VERSION)
GRUB_HOST_INSTALL_DIR		= $(GRUB_HOST_BUILD_DIR)/install
GRUB_HOST_SOURCE_STAMP		= $(STAMPDIR)/grub-host-source
GRUB_HOST_PATCH_STAMP		= $(STAMPDIR)/grub-host-patch
GRUB_HOST_CONFIGURE_STAMP	= $(STAMPDIR)/grub-host-configure
GRUB_HOST_BUILD_STAMP		= $(STAMPDIR)/grub-host-build
GRUB_HOST_INSTALL_STAMP		= $(STAMPDIR)/grub-host-install

PHONY += grub-host-source grub-host-patch \
  grub-host-configure grub-host-build grub-host-install grub-host-clean

GRUB_HOST_STAMP = $(GRUB_HOST_SOURCE_STAMP) \
	    $(GRUB_HOST_PATCH_STAMP) \
	    $(GRUB_HOST_CONFIGURE_STAMP) \
	    $(GRUB_HOST_BUILD_STAMP) \
	    $(GRUB_HOST_INSTALL_STAMP)

grub-host: $(GRUB_HOST_STAMP)

grub-host-source: $(GRUB_HOST_SOURCE_STAMP)
$(GRUB_HOST_SOURCE_STAMP): $(TREE_STAMP) | $(GRUB_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream grub ===="
	$(Q) $(SCRIPTDIR)/extract-package $(GRUB_HOST_BUILD_DIR) $(DOWNLOADDIR)/$(GRUB_TARBALL)
	$(Q) touch $@

grub-host-patch: $(GRUB_HOST_PATCH_STAMP)
$(GRUB_HOST_PATCH_STAMP): $(GRUB_HOST_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching grub-host-$(GRUB_VERSION) ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(GRUB_SRCPATCHDIR)/series $(GRUB_HOST_DIR)
	$(Q) touch $@

grub-host-configure: $(GRUB_HOST_CONFIGURE_STAMP)
$(GRUB_HOST_CONFIGURE_STAMP): $(GRUB_HOST_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-host-$(GRUB_VERSION) ===="
	$(Q) cd $(GRUB_HOST_DIR) && ./autogen.sh
	$(Q) cd $(GRUB_HOST_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_HOST_DIR)/configure			\
		--prefix=/usr					\
		--disable-nls					\
		--disable-efiemu				\
		--with-platform=efi
	$(Q) touch $@

grub-host-build: $(GRUB_HOST_BUILD_STAMP)
$(GRUB_HOST_BUILD_STAMP): $(GRUB_HOST_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-host-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_HOST_DIR)
	$(Q) touch $@

grub-host-install: $(GRUB_HOST_INSTALL_STAMP)
$(GRUB_HOST_INSTALL_STAMP): $(GRUB_HOST_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing grub-host in $(GRUB_HOST_INSTALL_DIR) ===="
	$(Q) $(MAKE) -C $(GRUB_HOST_DIR) install DESTDIR=$(GRUB_HOST_INSTALL_DIR)
	$(Q) touch $@

USERSPACE_CLEAN += grub-host-clean
grub-host-clean:
	$(Q) rm -rf $(GRUB_HOST_BUILD_DIR)
	$(Q) rm -f $(GRUB_HOST_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

endif # ifeq ($(PXE_EFI64_ENABLE),yes)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
