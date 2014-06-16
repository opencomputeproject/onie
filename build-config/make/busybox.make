#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of busybox
#

BUSYBOX_VERSION		= 1.20.0
BUSYBOX_TARBALL		= $(UPSTREAMDIR)/busybox-$(BUSYBOX_VERSION).tar.bz2
BUSYBOX_BUILD_DIR	= $(MBUILDDIR)/busybox
BUSYBOX_DIR		= $(BUSYBOX_BUILD_DIR)/busybox-$(BUSYBOX_VERSION)
BUSYBOX_CONFIG		= conf/busybox.config

BUSYBOX_SRCPATCHDIR	= $(PATCHDIR)/busybox
BUSYBOX_SOURCE_STAMP	= $(STAMPDIR)/busybox-source
BUSYBOX_PATCH_STAMP	= $(STAMPDIR)/busybox-patch
BUSYBOX_BUILD_STAMP	= $(STAMPDIR)/busybox-build
BUSYBOX_INSTALL_STAMP	= $(STAMPDIR)/busybox-install
BUSYBOX_STAMP		= $(BUSYBOX_SOURCE_STAMP) \
				  $(BUSYBOX_PATCH_STAMP) \
				  $(BUSYBOX_BUILD_STAMP) \
				  $(BUSYBOX_INSTALL_STAMP)

PHONY += busybox busybox-source busybox-config busybox-patch \
	busybox-build busybox-install busybox-clean

busybox: $(BUSYBOX_STAMP)

SOURCE += $(BUSYBOX_SOURCE_STAMP)

busybox-source: $(BUSYBOX_SOURCE_STAMP)
$(BUSYBOX_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting and extracting upstream U-Boot ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(BUSYBOX_TARBALL).sha1
	$(Q) rm -rf $(BUSYBOX_BUILD_DIR)
	$(Q) mkdir -p $(BUSYBOX_BUILD_DIR)
	$(Q) cd $(BUSYBOX_BUILD_DIR) && tar xjf $(BUSYBOX_TARBALL)
	$(Q) touch $@

busybox-patch: $(BUSYBOX_PATCH_STAMP)
$(BUSYBOX_PATCH_STAMP): $(BUSYBOX_SRCPATCHDIR)/* $(BUSYBOX_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching Busybox ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(BUSYBOX_SRCPATCHDIR)/series $(BUSYBOX_DIR)
	$(Q) touch $@

$(BUSYBOX_DIR)/.config: $(BUSYBOX_CONFIG) $(BUSYBOX_PATCH_STAMP)
	$(Q) echo "==== Copying $(BUSYBOX_CONFIG) to $(BUSYBOX_DIR)/.config ===="
	$(Q) cp -v $< $@

busybox-config: $(BUSYBOX_DIR)/.config
	PATH='$(CROSSBIN):$(PATH)' \
		$(MAKE) -C $(BUSYBOX_DIR) CROSS_COMPILE=$(CROSSPREFIX) menuconfig

ifndef MAKE_CLEAN
BUSYBOX_NEW_FILES = $(shell test -d $(BUSYBOX_DIR) && test -f $(BUSYBOX_BUILD_STAMP) && \
	              find -L $(BUSYBOX_DIR) -newer $(BUSYBOX_BUILD_STAMP) \! -name .kernelrelease  \
			\! -name busybox.links -type f -print -quit )
endif

busybox-build: $(BUSYBOX_BUILD_STAMP)
$(BUSYBOX_BUILD_STAMP): $(BUSYBOX_DIR)/.config $(BUSYBOX_NEW_FILES) $(UCLIBC_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building busybox-$(BUSYBOX_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(BUSYBOX_DIR)				\
		CONFIG_SYSROOT=$(UCLIBC_DEV_SYSROOT)		\
		CONFIG_EXTRA_CFLAGS="-Os -muclibc -I$(KERNEL_HEADERS)"	\
		CONFIG_PREFIX=$(SYSROOTDIR)			\
		CROSS_COMPILE=$(CROSSPREFIX) V=$(V)
	$(Q) touch $@

busybox-install: $(BUSYBOX_INSTALL_STAMP)
$(BUSYBOX_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(BUSYBOX_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing busybox in $(SYSROOTDIR) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(BUSYBOX_DIR)			\
		CONFIG_SYSROOT=$(UCLIBC_DEV_SYSROOT)		\
		CONFIG_EXTRA_CFLAGS="-Os -muclibc -I$(KERNEL_HEADERS)"	\
		CONFIG_PREFIX=$(SYSROOTDIR)			\
		CROSS_COMPILE=$(CROSSPREFIX)			\
		install
	$(Q) touch $@

CLEAN += busybox-clean
busybox-clean:
	$(Q) rm -rf $(BUSYBOX_BUILD_DIR)
	$(Q) rm -f $(BUSYBOX_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
