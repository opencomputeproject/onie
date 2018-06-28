#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014,2015,2016,2017 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the build of the onie cross-compiled U-Boot
#

UBOOT_VERSION		?= 2013.01.01
UBOOT_TARBALL		= u-boot-$(UBOOT_VERSION).tar.bz2
UBOOT_TARBALL_URLS	+= $(ONIE_MIRROR) ftp://ftp.denx.de/pub/u-boot
UBOOT_BUILD_DIR		= $(MBUILDDIR)/u-boot
UBOOT_DIR		= $(UBOOT_BUILD_DIR)/u-boot-$(UBOOT_VERSION)

UBOOT_SRCPATCHDIR	= $(PATCHDIR)/u-boot/$(UBOOT_VERSION)
UBOOT_CMNPATCHDIR	= $(PATCHDIR)/u-boot/common
UBOOT_PATCHDIR		= $(UBOOT_BUILD_DIR)/patch
UBOOT_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/u-boot-download-$(UBOOT_VERSION)
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
UBOOT_PBL		= $(UBOOT_BUILD_DIR)/$(UBOOT_MACHINE)/u-boot.pbl
UBOOT_DTB		= $(UBOOT_BUILD_DIR)/$(UBOOT_MACHINE)/u-boot-dtb.bin
UBOOT_INSTALL_IMAGE	= $(IMAGEDIR)/$(MACHINE_PREFIX).u-boot
UPDATER_UBOOT		= $(MBUILDDIR)/u-boot.bin
ifeq ($(UBOOT_PBL_ENABLE),yes)
  UPDATER_UBOOT		+= $(MBUILDDIR)/u-boot.pbl
  UPDATER_UBOOT_NAME	= u-boot.pbl
  UBOOT_IMAGE		= $(UBOOT_PBL)
  UBOOT_TARGET		= $(UBOOT_PBL)
else ifeq ($(UBOOT_DTB_ENABLE),yes)
  UPDATER_UBOOT_NAME	= u-boot.bin
  UBOOT_IMAGE		= $(UBOOT_DTB)
  UBOOT_TARGET		= all
else
  UPDATER_UBOOT_NAME	= u-boot.bin
  UBOOT_IMAGE		= $(UBOOT_BIN)
  UBOOT_TARGET		= all
endif

UBOOT_IDENT_STRING	?= ONIE $(LSB_RELEASE_TAG)

PHONY += u-boot u-boot-download u-boot-source u-boot-patch u-boot-build \
	 u-boot-install u-boot-clean u-boot-download-clean

#-------------------------------------------------------------------------------

u-boot: $(UBOOT_STAMP)

DOWNLOAD += $(UBOOT_DOWNLOAD_STAMP)
u-boot-download: $(UBOOT_DOWNLOAD_STAMP)
$(UBOOT_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream U-Boot ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(UBOOT_TARBALL) $(UBOOT_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(UBOOT_PATCH_STAMP)
u-boot-source: $(UBOOT_SOURCE_STAMP)
$(UBOOT_SOURCE_STAMP): $(TREE_STAMP) | $(UBOOT_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream U-Boot ===="
	$(Q) $(SCRIPTDIR)/extract-package $(UBOOT_BUILD_DIR) $(DOWNLOADDIR)/$(UBOOT_TARBALL)
	$(Q) touch $@

#
# The u-boot patches are made up of a base set of platform independent
# patches with the current machine's platform dependent patches on
# top.
#
u-boot-patch: $(UBOOT_PATCH_STAMP)
$(UBOOT_PATCH_STAMP): $(UBOOT_CMNPATCHDIR)/* $(UBOOT_SRCPATCHDIR)/* $(MACHINEDIR)/u-boot/* $(UBOOT_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching u-boot ===="
	$(Q) [ -r $(MACHINEDIR)/u-boot/series ] || \
		(echo "Unable to find machine dependent u-boot patch series: $(MACHINEDIR)/u-boot/series" && \
		exit 1)
	$(Q) mkdir -p $(UBOOT_PATCHDIR)
	$(Q) cp $(UBOOT_SRCPATCHDIR)/series $(UBOOT_PATCHDIR)
	$(Q) $(SCRIPTDIR)/cp-machine-patches $(UBOOT_PATCHDIR) $(UBOOT_SRCPATCHDIR)/series	\
		$(UBOOT_SRCPATCHDIR) $(UBOOT_CMNPATCHDIR)
	$(Q) cat $(MACHINEDIR)/u-boot/series >> $(UBOOT_PATCHDIR)/series
	$(Q) $(SCRIPTDIR)/cp-machine-patches $(UBOOT_PATCHDIR) $(MACHINEDIR)/u-boot/series	\
		$(MACHINEDIR)/u-boot $(MACHINEROOT)/u-boot
	$(Q) $(SCRIPTDIR)/apply-patch-series $(UBOOT_PATCHDIR)/series $(UBOOT_DIR)
	$(Q) echo "#include <version.h>" > $(UBOOT_DIR)/include/configs/onie_version.h
	$(Q) echo "#define ONIE_VERSION \
		\"onie_version=$(LSB_RELEASE_TAG)\\0\"	\
		\"onie_vendor_id=$(VENDOR_ID)\\0\"	\
		\"onie_platform=$(PLATFORM)\\0\"	\
		\"onie_machine=$(MACHINE)\\0\"		\
		\"platform=$(MACHINE)\\0\"		\
		\"onie_machine_rev=$(MACHINE_REV)\\0\"	\
		\"dhcp_vendor-class-identifier=$(PLATFORM)\\0\"	\
		\"dhcp_user-class=$(PLATFORM)_uboot\\0\"	\
		\"onie_build_date=$(ONIE_BUILD_DATE)\\0\"	\
		\"onie_uboot_version=\" U_BOOT_VERSION_STRING \"\\0\" \
		\"ver=\" U_BOOT_VERSION_STRING \"\\0\" \
		" >> $(UBOOT_DIR)/include/configs/onie_version.h
	$(Q) echo '#define CONFIG_IDENT_STRING " - $(UBOOT_IDENT_STRING)"' \
		>> $(UBOOT_DIR)/include/configs/onie_version.h
	$(Q) echo '#define PLATFORM_STRING "$(PLATFORM)"' \
		>> $(UBOOT_DIR)/include/configs/onie_version.h
	$(Q) touch $@

ifndef MAKE_CLEAN
UBOOT_NEW = $(shell test -d $(UBOOT_DIR) && test -f $(UBOOT_BUILD_STAMP) && \
	       find -L $(UBOOT_DIR) -newer $(UBOOT_BUILD_STAMP) -print -quit)
endif

$(UBOOT_IMAGE): $(UBOOT_PATCH_STAMP) $(UBOOT_NEW) | $(XTOOLS_BUILD_STAMP)
	$(Q) echo "==== Building u-boot ($(UBOOT_MACHINE)) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(UBOOT_DIR)		\
		CROSS_COMPILE=$(CROSSPREFIX) O=$(UBOOT_BUILD_DIR)/$(UBOOT_MACHINE) \
		$(UBOOT_MACHINE)_config
	$(Q) PATH='$(CROSSBIN):$(PATH)' $(MAKE) -C $(UBOOT_DIR)		\
		CROSS_COMPILE=$(CROSSPREFIX) O=$(UBOOT_BUILD_DIR)/$(UBOOT_MACHINE) \
		$(UBOOT_TARGET)

u-boot-build: $(UBOOT_BUILD_STAMP)
$(UBOOT_BUILD_STAMP): $(UBOOT_IMAGE)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) touch $@

u-boot-install: $(UBOOT_INSTALL_STAMP)
$(UBOOT_INSTALL_STAMP): $(UBOOT_BUILD_STAMP)
	$(Q) echo "==== Installing u-boot ($(MACHINE_PREFIX)) ===="
	$(Q) cp -v $(UBOOT_IMAGE) $(UBOOT_INSTALL_IMAGE)
	$(Q) chmod a-x $(UBOOT_INSTALL_IMAGE)
	$(Q) ln -sf $(UBOOT_BIN) $(MBUILDDIR)/u-boot.bin
ifeq ($(UBOOT_PBL_ENABLE),yes)
	$(Q) ln -sf $(UBOOT_PBL) $(MBUILDDIR)/u-boot.pbl
endif
	$(Q) touch $@

MACHINE_CLEAN += u-boot-clean
u-boot-clean:
	$(Q) rm -rf $(UBOOT_BUILD_DIR)
	$(Q) rm -f $(UBOOT_STAMP)
	$(Q) rm -f $(UBOOT_INSTALL_IMAGE)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += u-boot-download-clean
u-boot-download-clean:
	$(Q) rm -f $(UBOOT_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(UBOOT_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
