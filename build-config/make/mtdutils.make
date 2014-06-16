#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of mtdutils
#

MTDUTILS_VERSION		= 1.5.0
MTDUTILS_TARBALL		= $(UPSTREAMDIR)/mtd-utils-$(MTDUTILS_VERSION).tar.bz2
MTDUTILS_BUILD_DIR		= $(MBUILDDIR)/mtd-utils
MTDUTILS_DIR			= $(MTDUTILS_BUILD_DIR)/mtd-utils-$(MTDUTILS_VERSION)

MTDUTILS_SOURCE_STAMP	= $(STAMPDIR)/mtdutils-source
MTDUTILS_BUILD_STAMP	= $(STAMPDIR)/mtdutils-build
MTDUTILS_INSTALL_STAMP	= $(STAMPDIR)/mtdutils-install
MTDUTILS_STAMP		= $(MTDUTILS_SOURCE_STAMP) \
			  $(MTDUTILS_BUILD_STAMP) \
			  $(MTDUTILS_INSTALL_STAMP)

MTDBINS = mkfs.jffs2 mkfs.ubifs ubinize ubiformat ubinfo mtdinfo

PHONY += mtdutils mtdutils-source mtdutils-build \
	 mtdutils-install mtdutils-clean

mtdutils: $(MTDUTILS_STAMP)

SOURCE += $(MTDUTILS_SOURCE_STAMP)

mtdutils-source: $(MTDUTILS_SOURCE_STAMP)
$(MTDUTILS_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting and extracting upstream mtdutils ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(MTDUTILS_TARBALL).sha1
	$(Q) rm -rf $(MTDUTILS_BUILD_DIR)
	$(Q) mkdir -p $(MTDUTILS_BUILD_DIR)
	$(Q) cd $(MTDUTILS_BUILD_DIR) && tar xf $(MTDUTILS_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
MTDUTILS_NEW_FILES = $(shell test -d $(MTDUTILS_DIR) && test -f $(MTDUTILS_BUILD_STAMP) && \
	              find -L $(MTDUTILS_DIR) -newer $(MTDUTILS_BUILD_STAMP) -type f -print -quit)
endif

mtdutils-build: $(MTDUTILS_BUILD_STAMP)
$(MTDUTILS_BUILD_STAMP): $(MTDUTILS_NEW_FILES) $(UCLIBC_INSTALL_STAMP) \
			 $(E2FSPROGS_INSTALL_STAMP) $(LZO_INSTALL_STAMP) \
			 $(ZLIB_INSTALL_STAMP) $(MTDUTILS_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(MTDUTILS_DIR)				\
		PREFIX=$(UCLIBC_DEV_SYSROOT)/usr		\
		CROSS=$(CROSSPREFIX)				\
		CFLAGS="-Os -g -I$(KERNEL_HEADERS) -I$(UCLIBC_DEV_SYSROOT)/usr/include $(UCLIBC_FLAGS)" \
                WITHOUT_XATTR=1
	$(Q) touch $@

mtdutils-install: $(MTDUTILS_INSTALL_STAMP)
$(MTDUTILS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(MTDUTILS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing mtdutils in $(UCLIBC_DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(MTDUTILS_DIR)				\
		PREFIX=$(UCLIBC_DEV_SYSROOT)/usr		\
		CROSS=$(CROSSPREFIX)				\
		CFLAGS="-Os -g -I$(KERNEL_HEADERS) -I$(UCLIBC_DEV_SYSROOT)/usr/include $(UCLIBC_FLAGS)" \
                WITHOUT_XATTR=1                                 \
                install
	$(Q) for file in $(MTDBINS) ; do \
		cp -av $(UCLIBC_DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin/ ; \
		$(CROSSBIN)/$(CROSSPREFIX)strip $(SYSROOTDIR)/usr/sbin/$$file ; \
	done
	$(Q) touch $@

CLEAN += mtdutils-clean
mtdutils-clean:
	$(Q) rm -rf $(MTDUTILS_BUILD_DIR)
	$(Q) rm -f $(MTDUTILS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
