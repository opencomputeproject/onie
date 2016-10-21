#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of some libraries
# from the util-linux package.
#

UTILLINUX_VERSION		= 2.27
UTILLINUX_TARBALL		= util-linux-$(UTILLINUX_VERSION).tar.xz
UTILLINUX_TARBALL_URLS		+= $(ONIE_MIRROR) \
					https://www.kernel.org/pub/linux/utils/util-linux/v$(UTILLINUX_VERSION)/
UTILLINUX_BUILD_DIR		= $(MBUILDDIR)/util-linux
UTILLINUX_DIR			= $(UTILLINUX_BUILD_DIR)/util-linux-$(UTILLINUX_VERSION)

UTILLINUX_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/util-linux-download
UTILLINUX_SOURCE_STAMP		= $(STAMPDIR)/util-linux-source
UTILLINUX_CONFIGURE_STAMP	= $(STAMPDIR)/util-linux-configure
UTILLINUX_BUILD_STAMP		= $(STAMPDIR)/util-linux-build
UTILLINUX_INSTALL_STAMP		= $(STAMPDIR)/util-linux-install
UTILLINUX_STAMP			= $(UTILLINUX_SOURCE_STAMP) \
					$(UTILLINUX_CONFIGURE_STAMP) \
					$(UTILLINUX_BUILD_STAMP) \
					$(UTILLINUX_INSTALL_STAMP)

PHONY += util-linux util-linux-download util-linux-source util-linux-configure \
	util-linux-build util-linux-install util-linux-clean util-linux-download-clean

UTILLINUX_CONFIG	= --enable-libuuid
UTILLINUX_LIBS		= \
	libuuid.so    libuuid.so.1    libuuid.so.1.3.0

ifneq ($(filter yes, $(EXT3_4_ENABLE) $(LVM2_ENABLE)),)
UTILLINUX_CONFIG	+= --enable-libblkid
UTILLINUX_LIBS		+= \
	libblkid.so   libblkid.so.1   libblkid.so.1.1.0
endif

util-linux: $(UTILLINUX_STAMP)

DOWNLOAD += $(UTILLINUX_DOWNLOAD_STAMP)
util-linux-download: $(UTILLINUX_DOWNLOAD_STAMP)
$(UTILLINUX_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream util-linux ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(UTILLINUX_TARBALL) $(UTILLINUX_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(UTILLINUX_SOURCE_STAMP)
util-linux-source: $(UTILLINUX_SOURCE_STAMP)
$(UTILLINUX_SOURCE_STAMP): $(TREE_STAMP) | $(UTILLINUX_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream util-linux ===="
	$(Q) $(SCRIPTDIR)/extract-package $(UTILLINUX_BUILD_DIR) $(DOWNLOADDIR)/$(UTILLINUX_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
UTILLINUX_NEW_FILES = $(shell test -d $(UTILLINUX_DIR) && test -f $(UTILLINUX_BUILD_STAMP) && \
	              find -L $(UTILLINUX_DIR) -newer $(UTILLINUX_BUILD_STAMP) -type f \
			\! -name libblkid.so.1.1.0T -print -quit)
endif

util-linux-configure: $(UTILLINUX_CONFIGURE_STAMP)
$(UTILLINUX_CONFIGURE_STAMP): $(UTILLINUX_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure util-linux-$(UTILLINUX_VERSION) ===="
	$(Q) cd $(UTILLINUX_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(UTILLINUX_DIR)/configure			\
		--enable-shared					\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET)				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"				\
		--disable-tls					\
		--disable-all-programs				\
		--without-python				\
		$(UTILLINUX_CONFIG)				\
		$(ONIE_PKG_CONFIG)
	$(Q) touch $@

util-linux-build: $(UTILLINUX_BUILD_STAMP)
$(UTILLINUX_BUILD_STAMP): $(UTILLINUX_CONFIGURE_STAMP) $(UTILLINUX_NEW_FILES)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building util-linux-$(UTILLINUX_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(UTILLINUX_DIR)
	$(Q) touch $@

util-linux-install: $(UTILLINUX_INSTALL_STAMP)
$(UTILLINUX_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(UTILLINUX_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing util-linux in $(DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(UTILLINUX_DIR) install
	$(Q) for file in $(UTILLINUX_LIBS) ; do \
		cp -av $(DEV_SYSROOT)/usr/lib/$$file $(SYSROOTDIR)/usr/lib/ ; \
	     done
	$(Q) touch $@

USERSPACE_CLEAN += util-linux-clean
util-linux-clean:
	$(Q) rm -rf $(UTILLINUX_BUILD_DIR)
	$(Q) rm -f $(UTILLINUX_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += util-linux-download-clean
util-linux-download-clean:
	$(Q) rm -f $(UTILLINUX_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(UTILLINUX_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
