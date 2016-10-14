#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015 Nikolay Shopik <shopik@nvcube.net>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of dropbear
#

DROPBEAR_VERSION		= 2016.74
DROPBEAR_TARBALL		= dropbear-$(DROPBEAR_VERSION).tar.bz2
DROPBEAR_TARBALL_URLS		+= $(ONIE_MIRROR) https://matt.ucc.asn.au/dropbear/releases
DROPBEAR_BUILD_DIR		= $(MBUILDDIR)/dropbear
DROPBEAR_DIR			= $(DROPBEAR_BUILD_DIR)/dropbear-$(DROPBEAR_VERSION)
DROPBEAR_CONFIG_H		= conf/dropbear.config.h

DROPBEAR_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/dropbear-download
DROPBEAR_SOURCE_STAMP		= $(STAMPDIR)/dropbear-source
DROPBEAR_CONFIGURE_STAMP	= $(STAMPDIR)/dropbear-configure
DROPBEAR_BUILD_STAMP		= $(STAMPDIR)/dropbear-build
DROPBEAR_INSTALL_STAMP		= $(STAMPDIR)/dropbear-install
DROPBEAR_STAMP			= $(DROPBEAR_SOURCE_STAMP) \
				  $(DROPBEAR_CONFIGURE_STAMP) \
				  $(DROPBEAR_BUILD_STAMP) \
				  $(DROPBEAR_INSTALL_STAMP)

DROPBEAR_PROGRAMS		= dropbear dbclient dropbearkey dropbearconvert scp
DROPBEAR_MULTI_BIN		= ../bin/dropbearmulti
DROPBEAR_BINS			= usr/sbin/dropbear		\
				  usr/bin/dbclient		\
				  usr/bin/dropbearkey		\
				  usr/bin/dropbearconvert	\
				  usr/bin/scp			\
				  usr/bin/ssh

PHONY += dropbear dropbear-download dropbear-source dropbear-configure \
	dropbear-build dropbear-install dropbear-clean dropbear-download-clean

dropbear: $(DROPBEAR_STAMP)

DOWNLOAD += $(DROPBEAR_DOWNLOAD_STAMP)
dropbear-download: $(DROPBEAR_DOWNLOAD_STAMP)
$(DROPBEAR_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream dropbear ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(DROPBEAR_TARBALL) $(DROPBEAR_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(DROPBEAR_SOURCE_STAMP)
dropbear-source: $(DROPBEAR_SOURCE_STAMP)
$(DROPBEAR_SOURCE_STAMP): $(TREE_STAMP) | $(DROPBEAR_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream dropbear ===="
	$(Q) $(SCRIPTDIR)/extract-package $(DROPBEAR_BUILD_DIR) $(DOWNLOADDIR)/$(DROPBEAR_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
DROPBEAR_NEW_FILES = $(shell test -d $(DROPBEAR_DIR) && test -f $(DROPBEAR_BUILD_STAMP) && \
	              find -L $(DROPBEAR_DIR) -newer $(DROPBEAR_BUILD_STAMP) -type f -print -quit)
endif

dropbear-configure: $(DROPBEAR_CONFIGURE_STAMP)
$(DROPBEAR_CONFIGURE_STAMP): $(DROPBEAR_SOURCE_STAMP) $(ZLIB_INSTALL_STAMP) \
			     | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure dropbear-$(DROPBEAR_VERSION) ===="
	$(Q) cd $(DROPBEAR_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(DROPBEAR_DIR)/configure			\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET)				\
		CFLAGS="$(ONIE_CFLAGS)" 			\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

$(DROPBEAR_DIR)/options.h: $(DROPBEAR_CONFIG_H) $(DROPBEAR_CONFIGURE_STAMP)
	$(Q) echo "==== Copying $(DROPBEAR_CONFIG_H) to $@ ===="
	$(Q) cp -v $< $@

dropbear-build: $(DROPBEAR_BUILD_STAMP)
$(DROPBEAR_BUILD_STAMP): $(DROPBEAR_DIR)/options.h $(DROPBEAR_NEW_FILES)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building dropbear-$(DROPBEAR_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(DROPBEAR_DIR) \
		PROGRAMS="$(DROPBEAR_PROGRAMS)" MULTI=1 SCPPROGRESS=1
	$(Q) touch $@

#
# Installation:
#
#   - install multi-program binary in /usr/bin
#   - strip binary
#   - create symlinks to binary for other progs
#
dropbear-install: $(DROPBEAR_INSTALL_STAMP)
$(DROPBEAR_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(DROPBEAR_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing dropbear in $(DEV_SYSROOT) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(DROPBEAR_DIR) \
		PROGRAMS="$(DROPBEAR_PROGRAMS)" MULTI=1 install
	$(Q) cp -av $(DEV_SYSROOT)/usr/bin/$(DROPBEAR_MULTI_BIN) $(SYSROOTDIR)/usr/bin
	$(Q) for file in $(DROPBEAR_BINS); do \
		cd $(SYSROOTDIR)/$$(dirname $$file) && ln -svf $(DROPBEAR_MULTI_BIN) $$(basename $$file) ; \
	     done
	$(Q) mkdir -p $(SYSROOTDIR)/etc/dropbear
	$(Q) touch $@

USERSPACE_CLEAN += dropbear-clean
dropbear-clean:
	$(Q) rm -rf $(DROPBEAR_BUILD_DIR)
	$(Q) rm -f $(DROPBEAR_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += dropbear-download-clean
dropbear-download-clean:
	$(Q) rm -f $(DROPBEAR_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(DROPBEAR_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
