#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of lzo
#

LZO_VERSION		= 2.06
LZO_TARBALL		= $(UPSTREAMDIR)/lzo-$(LZO_VERSION).tar.gz
LZO_BUILD_DIR		= $(MBUILDDIR)/lzo
LZO_DIR			= $(LZO_BUILD_DIR)/lzo-$(LZO_VERSION)

LZO_SOURCE_STAMP	= $(STAMPDIR)/lzo-source
LZO_CONFIGURE_STAMP	= $(STAMPDIR)/lzo-configure
LZO_BUILD_STAMP		= $(STAMPDIR)/lzo-build
LZO_INSTALL_STAMP	= $(STAMPDIR)/lzo-install
LZO_STAMP		= $(LZO_SOURCE_STAMP) \
			  $(LZO_CONFIGURE_STAMP) \
			  $(LZO_BUILD_STAMP) \
			  $(LZO_INSTALL_STAMP)

PHONY += lzo lzo-source lzo-configure \
	lzo-build lzo-install lzo-clean

lzo: $(LZO_STAMP)

SOURCE += $(LZO_SOURCE_STAMP)

lzo-source: $(LZO_SOURCE_STAMP)
$(LZO_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting and extracting upstream lzo ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(LZO_TARBALL).sha1
	$(Q) rm -rf $(LZO_BUILD_DIR)
	$(Q) mkdir -p $(LZO_BUILD_DIR)
	$(Q) cd $(LZO_BUILD_DIR) && tar xf $(LZO_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
LZO_NEW_FILES = $(shell test -d $(LZO_DIR) && test -f $(LZO_BUILD_STAMP) && \
	              find -L $(LZO_DIR) -newer $(LZO_BUILD_STAMP) -type f -print -quit)
endif

lzo-configure: $(LZO_CONFIGURE_STAMP)
$(LZO_CONFIGURE_STAMP): $(LZO_SOURCE_STAMP) $(UCLIBC_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure lzo-$(LZO_VERSION) ===="
	$(Q) cd $(LZO_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(LZO_DIR)/configure				\
		--prefix=$(UCLIBC_DEV_SYSROOT)/usr		\
		--host=$(TARGET)				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="-Os -I$(KERNEL_HEADERS) $(UCLIBC_FLAGS)"
	$(Q) touch $@

lzo-build: $(LZO_BUILD_STAMP)
$(LZO_BUILD_STAMP): $(LZO_CONFIGURE_STAMP) $(LZO_NEW_FILES)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building lzo-$(LZO_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(LZO_DIR)
	$(Q) touch $@

lzo-install: $(LZO_INSTALL_STAMP)
$(LZO_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LZO_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing lzo in $(UCLIBC_DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(LZO_DIR) install
	$(Q) touch $@

CLEAN += lzo-clean
lzo-clean:
	$(Q) rm -rf $(LZO_BUILD_DIR)
	$(Q) rm -f $(LZO_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
