#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of dropbear
#

DROPBEAR_VERSION		= 2013.58
DROPBEAR_TARBALL		= dropbear-$(DROPBEAR_VERSION).tar.bz2
DROPBEAR_TARBALL_SHA1		= SHA1SUM.asc
DROPBEAR_TARBALL_URLS		= https://matt.ucc.asn.au/dropbear/releases
DROPBEAR_BUILD_DIR		= $(MBUILDDIR)/dropbear
DROPBEAR_DIR			= $(DROPBEAR_BUILD_DIR)/dropbear-$(DROPBEAR_VERSION)
DROPBEAR_CONFIG_H		= conf/dropbear.config.h

DROPBEAR_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/dropbear-download
DROPBEAR_SOURCE_STAMP		= $(STAMPDIR)/dropbear-source
DROPBEAR_CONFIGURE_STAMP	= $(STAMPDIR)/dropbear-configure
DROPBEAR_BUILD_STAMP		= $(STAMPDIR)/dropbear-build
DROPBEAR_INSTALL_STAMP		= $(STAMPDIR)/dropbear-install
DROPBEAR_STAMP			= $(DROPBEAR_DOWNLOAD_STAMP) \
				  $(DROPBEAR_SOURCE_STAMP) \
				  $(DROPBEAR_CONFIGURE_STAMP) \
				  $(DROPBEAR_BUILD_STAMP) \
				  $(DROPBEAR_INSTALL_STAMP)

DROPBEAR_PROGRAMS		= dropbear dbclient dropbearkey dropbearconvert scp
DROPBEAR_MULTI_BIN		= /usr/bin/dropbearmulti
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
$(DROPBEAR_DOWNLOAD_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream dropbear ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(DROPBEAR_TARBALL) $(DROPBEAR_TARBALL_URLS)
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(DROPBEAR_TARBALL_SHA1) $(DROPBEAR_TARBALL_URLS)
	$(Q) cd $(DOWNLOADDIR) && grep $(DROPBEAR_TARBALL) $(DROPBEAR_TARBALL_SHA1) | sha1sum -c -
	$(Q) touch $@

SOURCE += $(DROPBEAR_SOURCE_STAMP)
dropbear-source: $(DROPBEAR_SOURCE_STAMP)
$(DROPBEAR_SOURCE_STAMP): $(DROPBEAR_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream dropbear ===="
	$(Q) $(SCRIPTDIR)/extract-package $(DROPBEAR_BUILD_DIR) $(DOWNLOADDIR)/$(DROPBEAR_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
DROPBEAR_NEW_FILES = $(shell test -d $(DROPBEAR_DIR) && test -f $(DROPBEAR_BUILD_STAMP) && \
	              find -L $(DROPBEAR_DIR) -newer $(DROPBEAR_BUILD_STAMP) -type f -print -quit)
endif

dropbear-configure: $(DROPBEAR_CONFIGURE_STAMP)
$(DROPBEAR_CONFIGURE_STAMP): $(DROPBEAR_SOURCE_STAMP) $(UCLIBC_INSTALL_STAMP) \
			     $(ZLIB_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure dropbear-$(DROPBEAR_VERSION) ===="
	$(Q) cd $(DROPBEAR_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(DROPBEAR_DIR)/configure			\
		--prefix=$(UCLIBC_DEV_SYSROOT)/usr		\
		--host=$(TARGET)				\
		CFLAGS="-Os -I$(KERNEL_HEADERS) $(UCLIBC_FLAGS)" \
		LDFLAGS="$(UCLIBC_FLAGS)"
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
	$(Q) echo "==== Installing dropbear in $(UCLIBC_DEV_SYSROOT) ===="
	$(Q) sudo PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(DROPBEAR_DIR) \
		PROGRAMS="$(DROPBEAR_PROGRAMS)" MULTI=1 install
	$(Q) sudo cp -av $(UCLIBC_DEV_SYSROOT)/$(DROPBEAR_MULTI_BIN) $(SYSROOTDIR)/$(DROPBEAR_MULTI_BIN)
	$(Q) sudo $(CROSSBIN)/$(CROSSPREFIX)strip $(SYSROOTDIR)/$(DROPBEAR_MULTI_BIN)
	$(Q) for file in $(DROPBEAR_BINS); do \
		cd $(SYSROOTDIR) && sudo ln -svf $(DROPBEAR_MULTI_BIN) $$file ; \
	done
	$(Q) sudo mkdir -p $(SYSROOTDIR)/etc/dropbear
	$(Q) touch $@

CLEAN += dropbear-clean
dropbear-clean:
	$(Q) rm -rf $(DROPBEAR_BUILD_DIR)
	$(Q) rm -f $(DROPBEAR_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += dropbear-download-clean
dropbear-download-clean:
	$(Q) rm -f $(DROPBEAR_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(DROPBEAR_TARBALL) \
		   $(DOWNLOADDIR)/$(DROPBEAR_TARBALL_SHA1)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
