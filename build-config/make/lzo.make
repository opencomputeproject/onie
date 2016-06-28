#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of lzo
#

LZO_VERSION		= 2.09
LZO_TARBALL		= lzo-$(LZO_VERSION).tar.gz
LZO_TARBALL_URLS	+= $(ONIE_MIRROR) http://www.oberhumer.com/opensource/lzo/download
LZO_BUILD_DIR		= $(MBUILDDIR)/lzo
LZO_DIR			= $(LZO_BUILD_DIR)/lzo-$(LZO_VERSION)

LZO_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/lzo-$(LZO_VERSION)-download
LZO_SOURCE_STAMP	= $(STAMPDIR)/lzo-source
LZO_CONFIGURE_STAMP	= $(STAMPDIR)/lzo-configure
LZO_BUILD_STAMP		= $(STAMPDIR)/lzo-build
LZO_INSTALL_STAMP	= $(STAMPDIR)/lzo-install
LZO_STAMP		= $(LZO_SOURCE_STAMP) \
			  $(LZO_CONFIGURE_STAMP) \
			  $(LZO_BUILD_STAMP) \
			  $(LZO_INSTALL_STAMP)

PHONY += lzo lzo-download lzo-source lzo-configure \
	lzo-build lzo-install lzo-clean lzo-download-clean

LZO_LIBS = liblzo2.so.2 liblzo2.so.2.0.0

lzo: $(LZO_STAMP)

DOWNLOAD += $(LZO_DOWNLOAD_STAMP)
lzo-download: $(LZO_DOWNLOAD_STAMP)
$(LZO_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream lzo ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LZO_TARBALL) $(LZO_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LZO_SOURCE_STAMP)
lzo-source: $(LZO_SOURCE_STAMP)
$(LZO_SOURCE_STAMP): $(TREE_STAMP) | $(LZO_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream lzo ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LZO_BUILD_DIR) $(DOWNLOADDIR)/$(LZO_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
LZO_NEW_FILES = $(shell test -d $(LZO_DIR) && test -f $(LZO_BUILD_STAMP) && \
	              find -L $(LZO_DIR) -newer $(LZO_BUILD_STAMP) -type f -print -quit)
endif

lzo-configure: $(LZO_CONFIGURE_STAMP)
$(LZO_CONFIGURE_STAMP): $(LZO_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure lzo-$(LZO_VERSION) ===="
	$(Q) cd $(LZO_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(LZO_DIR)/configure				\
		--enable-shared					\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET)				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"
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
	$(Q) echo "==== Installing lzo in $(DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(LZO_DIR) install
	$(Q) for file in $(LZO_LIBS) ; do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	done
	$(Q) touch $@

USERSPACE_CLEAN += lzo-clean
lzo-clean:
	$(Q) rm -rf $(LZO_BUILD_DIR)
	$(Q) rm -f $(LZO_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += lzo-download-clean
lzo-download-clean:
	$(Q) rm -f $(LZO_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LZO_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
