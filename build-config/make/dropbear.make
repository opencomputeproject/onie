#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of dropbear
#

DROPBEAR_VERSION		= 2013.58
DROPBEAR_TARBALL		= $(UPSTREAMDIR)/dropbear-$(DROPBEAR_VERSION).tar.bz2
DROPBEAR_BUILD_DIR		= $(MBUILDDIR)/dropbear
DROPBEAR_DIR			= $(DROPBEAR_BUILD_DIR)/dropbear-$(DROPBEAR_VERSION)
DROPBEAR_CONFIG_H		= conf/dropbear.config.h

DROPBEAR_SOURCE_STAMP		= $(STAMPDIR)/dropbear-source
DROPBEAR_CONFIGURE_STAMP	= $(STAMPDIR)/dropbear-configure
DROPBEAR_BUILD_STAMP		= $(STAMPDIR)/dropbear-build
DROPBEAR_INSTALL_STAMP		= $(STAMPDIR)/dropbear-install
DROPBEAR_STAMP			= $(DROPBEAR_SOURCE_STAMP) \
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

PHONY += dropbear dropbear-source dropbear-configure \
	dropbear-build dropbear-install dropbear-clean

dropbear: $(DROPBEAR_STAMP)

SOURCE += $(DROPBEAR_SOURCE_STAMP)

dropbear-source: $(DROPBEAR_SOURCE_STAMP)
$(DROPBEAR_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting and extracting upstream dropbear ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(DROPBEAR_TARBALL).sha1
	$(Q) rm -rf $(DROPBEAR_BUILD_DIR)
	$(Q) mkdir -p $(DROPBEAR_BUILD_DIR)
	$(Q) cd $(DROPBEAR_BUILD_DIR) && tar xf $(DROPBEAR_TARBALL)
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
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(DROPBEAR_DIR) \
		PROGRAMS="$(DROPBEAR_PROGRAMS)" MULTI=1 install
	$(Q) cp -av $(UCLIBC_DEV_SYSROOT)/$(DROPBEAR_MULTI_BIN) $(SYSROOTDIR)/$(DROPBEAR_MULTI_BIN)
	$(Q) $(CROSSBIN)/$(CROSSPREFIX)strip $(SYSROOTDIR)/$(DROPBEAR_MULTI_BIN)
	$(Q) for file in $(DROPBEAR_BINS); do \
		cd $(SYSROOTDIR) && ln -svf $(DROPBEAR_MULTI_BIN) $$file ; \
	done
	$(Q) mkdir -p $(SYSROOTDIR)/etc/dropbear
	$(Q) touch $@

CLEAN += dropbear-clean
dropbear-clean:
	$(Q) rm -rf $(DROPBEAR_BUILD_DIR)
	$(Q) rm -f $(DROPBEAR_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
