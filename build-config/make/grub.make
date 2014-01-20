#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of grub
#

GRUB_VERSION		= 2.00
GRUB_TARBALL		= grub-$(GRUB_VERSION).tar.xz
GRUB_TARBALL_URLS	+= $(ONIE_MIRROR) ftp://ftp.gnu.org/gnu/grub/
GRUB_BUILD_DIR		= $(MBUILDDIR)/grub
GRUB_DIR		= $(GRUB_BUILD_DIR)/grub-$(GRUB_VERSION)

GRUB_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/grub-download
GRUB_SOURCE_STAMP	= $(STAMPDIR)/grub-source
GRUB_CONFIGURE_STAMP	= $(STAMPDIR)/grub-configure
GRUB_BUILD_STAMP	= $(STAMPDIR)/grub-build
GRUB_INSTALL_STAMP	= $(STAMPDIR)/grub-install
GRUB_STAMP		= $(GRUB_SOURCE_STAMP) \
			  $(GRUB_CONFIGURE_STAMP) \
			  $(GRUB_BUILD_STAMP) \
			  $(GRUB_INSTALL_STAMP)

PHONY += grub grub-download grub-source \
	 grub-configure grub-build grub-install grub-clean \
	 grub-download-clean

GRUB_SBIN = grub-install grub-bios-setup grub-probe
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

grub-configure: $(GRUB_CONFIGURE_STAMP)
$(GRUB_CONFIGURE_STAMP): $(GRUB_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-$(GRUB_VERSION) ===="
	$(Q) cd $(GRUB_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_DIR)/configure				\
		--prefix=/usr					\
		--host=$(TARGET)				\
		--disable-nls					\
		--disable-efiemu				\
		CC=$(CROSSPREFIX)gcc				\
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

CLEAN_DOWNLOAD += grub-download-clean
grub-download-clean:
	$(Q) rm -f $(GRUB_DOWNLOAD_STAMP) $(DOWNLOADDIR)/grub*

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
