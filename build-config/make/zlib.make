#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of zlib
#

ZLIB_VERSION		= 1.2.8
ZLIB_TARBALL		= $(UPSTREAMDIR)/zlib-$(ZLIB_VERSION).tar.gz
ZLIB_BUILD_DIR		= $(MBUILDDIR)/zlib
ZLIB_DIR		= $(ZLIB_BUILD_DIR)/zlib-$(ZLIB_VERSION)

ZLIB_SOURCE_STAMP	= $(STAMPDIR)/zlib-source
ZLIB_CONFIGURE_STAMP	= $(STAMPDIR)/zlib-configure
ZLIB_BUILD_STAMP	= $(STAMPDIR)/zlib-build
ZLIB_INSTALL_STAMP	= $(STAMPDIR)/zlib-install
ZLIB_STAMP		= $(ZLIB_SOURCE_STAMP) \
			  $(ZLIB_CONFIGURE_STAMP) \
			  $(ZLIB_BUILD_STAMP) \
			  $(ZLIB_INSTALL_STAMP)

PHONY += zlib zlib-source zlib-configure \
	zlib-build zlib-install zlib-clean

ZLIBLIBS = libz.so libz.so.1 libz.so.1.2.8

zlib: $(ZLIB_STAMP)

SOURCE += $(ZLIB_SOURCE_STAMP)

zlib-source: $(ZLIB_SOURCE_STAMP)
$(ZLIB_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting and extracting upstream zlib ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(ZLIB_TARBALL).sha1
	$(Q) rm -rf $(ZLIB_BUILD_DIR)
	$(Q) mkdir -p $(ZLIB_BUILD_DIR)
	$(Q) cd $(ZLIB_BUILD_DIR) && tar xf $(ZLIB_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
ZLIB_NEW_FILES = $(shell test -d $(ZLIB_DIR) && test -f $(ZLIB_BUILD_STAMP) && \
	              find -L $(ZLIB_DIR) -newer $(ZLIB_BUILD_STAMP) -type f -print -quit)
endif

zlib-configure: $(ZLIB_CONFIGURE_STAMP)
$(ZLIB_CONFIGURE_STAMP): $(ZLIB_SOURCE_STAMP) $(UCLIBC_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure zlib-$(ZLIB_VERSION) ===="
	$(Q) cd $(ZLIB_DIR) &&					\
	    $(ZLIB_DIR)/configure				\
		--prefix=$(UCLIBC_DEV_SYSROOT)/usr
	$(Q) touch $@

zlib-build: $(ZLIB_BUILD_STAMP)
$(ZLIB_BUILD_STAMP): $(ZLIB_CONFIGURE_STAMP) $(ZLIB_NEW_FILES) $(UCLIBC_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building zlib-$(ZLIB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(ZLIB_DIR)				\
		CC=$(CROSSPREFIX)gcc				\
		AR=$(CROSSPREFIX)ar				\
		RANLIB=$(CROSSPREFIX)ranlib			\
		CPP=$(CROSSPREFIX)cpp				\
		LDSHARED="$(CROSSPREFIX)gcc -shared -Wl,-soname,libz.so.1,--version-script,zlib.map -I$(KERNEL_HEADERS) $(UCLIBC_FLAGS)" \
		CFLAGS="-Os -D_LARGEFILE64_SOURCE=1 -DHAVE_HIDDEN -I$(KERNEL_HEADERS) $(UCLIBC_FLAGS)"
	$(Q) touch $@

zlib-install: $(ZLIB_INSTALL_STAMP)
$(ZLIB_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(ZLIB_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing zlib in $(UCLIBC_DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(ZLIB_DIR) install
	$(Q) for file in $(ZLIBLIBS) ; do \
		cp -av $(UCLIBC_DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
		$(CROSSBIN)/$(CROSSPREFIX)strip $(SYSROOTDIR)/usr/lib/$$file ; \
	done
	$(Q) touch $@

CLEAN += zlib-clean
zlib-clean:
	$(Q) rm -rf $(ZLIB_BUILD_DIR)
	$(Q) rm -f $(ZLIB_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
