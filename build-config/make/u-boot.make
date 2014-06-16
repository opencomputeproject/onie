#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the build of the onie cross-compiled U-Boot
#

UBOOT_VERSION		= 2013.01.01
UBOOT_TARBALL		= $(UPSTREAMDIR)/u-boot-$(UBOOT_VERSION).tar.bz2
UBOOT_BUILD_DIR		= $(MBUILDDIR)/u-boot
UBOOT_DIR		= $(UBOOT_BUILD_DIR)/u-boot-$(UBOOT_VERSION)

UBOOT_SRCPATCHDIR	= $(PATCHDIR)/u-boot
UBOOT_PATCHDIR		= $(UBOOT_BUILD_DIR)/patch
UBOOT_SOURCE_STAMP	= $(STAMPDIR)/u-boot-source
UBOOT_PATCH_STAMP	= $(STAMPDIR)/u-boot-patch
UBOOT_BUILD_STAMP	= $(STAMPDIR)/u-boot-build
UBOOT_INSTALL_STAMP	= $(STAMPDIR)/u-boot-install
UBOOT_STAMP		= $(UBOOT_SOURCE_STAMP) \
			  $(UBOOT_PATCH_STAMP) \
			  $(UBOOT_BUILD_STAMP) \
			  $(UBOOT_INSTALL_STAMP)

UBOOT			= $(UBOOT_INSTALL_STAMP)

UBOOT_NAME		= $(shell echo $(MACHINE_PREFIX) | tr [:lower:] [:upper:])
UBOOT_MACHINE		?= $(UBOOT_NAME)
UBOOT_BIN		= $(UBOOT_BUILD_DIR)/$(UBOOT_MACHINE)/u-boot.bin
UBOOT_INSTALL_IMAGE	= $(IMAGEDIR)/$(MACHINE_PREFIX).u-boot

PHONY += u-boot u-boot-source u-boot-patch u-boot-build \
	 u-boot-install u-boot-clean

#-------------------------------------------------------------------------------

u-boot: $(UBOOT_STAMP)

SOURCE += $(UBOOT_PATCH_STAMP)

u-boot-source: $(UBOOT_SOURCE_STAMP)
$(UBOOT_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== $(PLATFORM): Getting and extracting upstream U-Boot ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(UBOOT_TARBALL).sha1
	$(Q) rm -rf $(UBOOT_BUILD_DIR)
	$(Q) mkdir -p $(UBOOT_BUILD_DIR)
	$(Q) cd $(UBOOT_BUILD_DIR) && tar xjf $(UBOOT_TARBALL)
	$(Q) touch $@

#
# The u-boot patches are made up of a base set of platform independent
# patches with the current machine's platform dependent patches on
# top.
#
u-boot-patch: $(UBOOT_PATCH_STAMP)
$(UBOOT_PATCH_STAMP): $(UBOOT_SRCPATCHDIR)/* $(MACHINEDIR)/u-boot/* $(UBOOT_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching u-boot ===="
	$(Q) [ -r $(MACHINEDIR)/u-boot/series ] || \
		(echo "Unable to find machine dependent u-boot patch series: $(MACHINEDIR)/u-boot/series" && \
		exit 1)
	$(Q) mkdir -p $(UBOOT_PATCHDIR)
	$(Q) cp $(UBOOT_SRCPATCHDIR)/* $(UBOOT_PATCHDIR)
	$(Q) cp $(MACHINEDIR)/u-boot/*.patch $(UBOOT_PATCHDIR)
	$(Q) cat $(MACHINEDIR)/u-boot/series >> $(UBOOT_PATCHDIR)/series
	$(Q) $(SCRIPTDIR)/apply-patch-series $(UBOOT_PATCHDIR)/series $(UBOOT_DIR)
	$(Q) echo "#define ONIE_VERSION \
		\"onie_version=$(LSB_RELEASE_TAG)\\0\"	\
		\"onie_vendor_id=$(VENDOR_ID)\\0\"	\
		\"onie_platform=$(PLATFORM)\\0\"	\
		\"onie_machine=$(MACHINE)\\0\"		\
		\"platform=$(MACHINE)\\0\"		\
		\"onie_machine_rev=$(MACHINE_REV)\\0\"	\
		\"dhcp_vendor-class-identifier=$(PLATFORM)\\0\"	\
		\"dhcp_user-class=$(PLATFORM)_uboot\\0\"	\
		" > $(UBOOT_DIR)/include/configs/onie_version.h
	$(Q) echo '#define CONFIG_IDENT_STRING " - $(ACC_UBOOT_REV)"' \
		>> $(UBOOT_DIR)/include/configs/onie_version.h
	$(Q) echo '#define PLATFORM_STRING "$(PLATFORM)"' \
		>> $(UBOOT_DIR)/include/configs/onie_version.h
	$(Q) touch $@

ifndef MAKE_CLEAN
UBOOT_NEW = $(shell test -d $(UBOOT_DIR) && test -f $(UBOOT_BUILD_STAMP) && \
	       find -L $(UBOOT_DIR) -newer $(UBOOT_BUILD_STAMP) -print -quit)
endif

$(UBOOT_BUILD_DIR)/%/u-boot.bin: $(UBOOT_PATCH_STAMP) $(UBOOT_NEW)
	$(Q) echo "==== Building u-boot ($*) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(UBOOT_DIR)		\
		CROSS_COMPILE=$(CROSSPREFIX) O=$(UBOOT_BUILD_DIR)/$*	\
		$*_config
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(UBOOT_DIR)		\
		CROSS_COMPILE=$(CROSSPREFIX) O=$(UBOOT_BUILD_DIR)/$*	\
		all

u-boot-build: $(UBOOT_BUILD_STAMP)
$(UBOOT_BUILD_STAMP): $(UBOOT_BIN)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) touch $@

u-boot-install: $(UBOOT_INSTALL_STAMP)
$(UBOOT_INSTALL_STAMP): $(UBOOT_BUILD_STAMP)
	$(Q) echo "==== Installing u-boot ($(MACHINE_PREFIX)) ===="
	$(Q) cp -v $(UBOOT_BIN) $(UBOOT_INSTALL_IMAGE)
	$(Q) chmod a-x $(UBOOT_INSTALL_IMAGE)
	$(Q) touch $@

CLEAN += u-boot-clean
u-boot-clean:
	$(Q) rm -rf $(UBOOT_BUILD_DIR)
	$(Q) rm -f $(UBOOT_STAMP)
	$(Q) rm -f $(IMAGEDIR)/*.u-boot
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
