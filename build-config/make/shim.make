#-------------------------------------------------------------------------------
#
#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of shim
#

SHIM_VERSION		= 13
SHIM_TARBALL		= shim-$(SHIM_VERSION).tar.bz2
SHIM_TARBALL_URLS	+= $(ONIE_MIRROR) \
				https://github.com/rhinstaller/shim/releases/download/$(SHIM_VERSION)
SHIM_BUILD_DIR		= $(MBUILDDIR)/shim
SHIM_DIR		= $(SHIM_BUILD_DIR)/shim-$(SHIM_VERSION)

SHIM_SRCPATCHDIR	= $(PATCHDIR)/shim
SHIM_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/shim-download
SHIM_SOURCE_STAMP	= $(USER_STAMPDIR)/shim-source
SHIM_PATCH_STAMP	= $(USER_STAMPDIR)/shim-patch
SHIM_BUILD_STAMP	= $(USER_STAMPDIR)/shim-build
SHIM_INSTALL_STAMP	= $(STAMPDIR)/shim-install
SHIM_SELF_SIGN_STAMP	= $(STAMPDIR)/shim-self-sign
SHIM_STAMP		= $(SHIM_SOURCE_STAMP) \
			  $(SHIM_PATCH_STAMP) \
			  $(SHIM_BUILD_STAMP) \
			  $(SHIM_INSTALL_STAMP)

SHIM_BINS		= $(addsuffix $(EFI_ARCH).efi, shim fb mm)
SHIM_IMAGE_NAME		= shim$(EFI_ARCH).efi

# To build ONIE with a signed shim, point this makefile to an out of
# tree directory containing the signed shim binary by setting
# $(SHIM_PREBUILT_DIR).  The $(SHIM_PREBUILT_DIR) must contain the
# prebuilt binaries:
#
# - shimx64.efi.signed
# - fbx64.efi
# - mkx64.efi

SHIM_PREBUILT_DIR	?=
ifneq ($(SHIM_PREBUILT_DIR),)
  SHIM_USE_PREBUILT	= yes
  SHIM_BIN_DIR		= $(SHIM_PREBUILT_DIR)
  SHIM_TEST_PREBUILT	= $(shell test -d $(SHIM_BIN_DIR) || echo -n "bad")
  ifeq ($(SHIM_TEST_PREBUILT),bad)
    $(error Unable to find prebuilt shim directory: $(SHIM_PREBUILT_DIR))
  endif
else
  SHIM_BIN_DIR = $(DEV_SYSROOT)/usr/share/shim
endif
SHIM_INSTALL_DIR	= $(SHIM_BUILD_DIR)/install
SHIM_SECURE_BOOT_IMAGE  = $(SHIM_INSTALL_DIR)/$(SHIM_IMAGE_NAME)

UPDATER_IMAGE_PARTS   += $(foreach f, $(SHIM_BINS), $(SHIM_INSTALL_DIR)/$f)
UPDATER_IMAGE_PARTS_COMPLETE += $(SHIM_INSTALL_STAMP)

PHONY += shim shim-download shim-source shim-patch \
	shim-build shim-install shim-clean shim-download-clean

shim: $(SHIM_STAMP)

DOWNLOAD += $(SHIM_DOWNLOAD_STAMP)
shim-download: $(SHIM_DOWNLOAD_STAMP)
$(SHIM_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream shim ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(SHIM_TARBALL) $(SHIM_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(SHIM_SOURCE_STAMP)
shim-source: $(SHIM_SOURCE_STAMP)
$(SHIM_SOURCE_STAMP): $(USER_TREE_STAMP) $(SHIM_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream shim ===="
	$(Q) $(SCRIPTDIR)/extract-package $(SHIM_BUILD_DIR) $(DOWNLOADDIR)/$(SHIM_TARBALL)
	$(Q) touch $@

shim-patch: $(SHIM_PATCH_STAMP)
$(SHIM_PATCH_STAMP): $(SHIM_SRCPATCHDIR)/* $(SHIM_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching shim ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(SHIM_SRCPATCHDIR)/series $(SHIM_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
SHIM_NEW_FILES = $(shell test -d $(SHIM_DIR) && test -f $(SHIM_BUILD_STAMP) && \
	              find -L $(SHIM_DIR) -newer $(SHIM_BUILD_STAMP) -type f -print -quit)
endif

SHIM_BUILD_ARGS = \
	CROSS_COMPILE=$(CROSSPREFIX) \
	RELEASE=onie-$(SHIM_VERSION) \
	ENABLE_HTTPBOOT=yes \
	ENABLE_SHIM_HASH=yes \
	ENABLE_SHIM_CERT=yes \
	VENDOR_CERT_FILE=$(ONIE_VENDOR_CERT_DER) \
	ARCH=$(ARCH) \
	TOPDIR=$(SHIM_DIR) \
	LIB_PATH="$(DEV_SYSROOT)/usr/lib" \
	EFI_PATH="$(GNU_EFI_LIB_PATH)" \
	EFI_INCLUDE="$(GNU_EFI_INCLUDE)"

shim-build: $(SHIM_BUILD_STAMP)
$(SHIM_BUILD_STAMP): $(SHIM_PATCH_STAMP) $(SHIM_NEW_FILES) $(GNU_EFI_INSTALL_STAMP) \
			$(PESIGN_INSTALL_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building shim-$(SHIM_VERSION) ===="
	$(Q) echo "Using ONIE vendor certificate: $(ONIE_VENDOR_CERT_DER)"
	$(Q) openssl x509 -in "$(ONIE_VENDOR_CERT_DER)" -inform der -text -noout
	$(Q) PATH='$(CROSSBIN):$(PESIGN_BIN_DIR):$(PATH)'	\
		$(MAKE) -C $(SHIM_DIR) $(SHIM_BUILD_ARGS)
	$(Q) PATH='$(CROSSBIN):$(PESIGN_BIN_DIR):$(PATH)'	\
		$(MAKE) -C $(SHIM_DIR) $(SHIM_BUILD_ARGS) \
			DESTDIR="$(DEV_SYSROOT)" \
			DATATARGETDIR="usr/share/shim" \
			install-as-data
	$(Q) touch $@

shim-install: $(SHIM_INSTALL_STAMP)
ifeq ($(SHIM_USE_PREBUILT),yes)
$(SHIM_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(SHIM_BIN_DIR)/shim$(EFI_ARCH).efi
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Installing prebuilt shim binaries ===="
else
$(SHIM_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(SHIM_BUILD_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Installing shim-$(SHIM_VERSION) ===="
endif
	$(Q) rm -rf $(SHIM_INSTALL_DIR)
	$(Q) mkdir -p $(SHIM_INSTALL_DIR)
	$(Q) for f in $(SHIM_BINS) ; do \
		cp -va $(SHIM_BIN_DIR)/$$f $(SHIM_INSTALL_DIR) || exit 1; \
	done
	$(Q) touch $@

shim-self-sign: $(SHIM_SELF_SIGN_STAMP)
$(SHIM_SELF_SIGN_STAMP): $(SHIM_BUILD_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Self signing shim-$(SHIM_VERSION) ===="
	$(Q) echo "This is for testing purposes only."
	$(Q) sbsign --key $(SHIM_SELF_SIGN_SECRET_KEY_PEM) \
		--cert $(SHIM_SELF_SIGN_PUBLIC_CERT_PEM) \
		--output "$(SHIM_INSTALL_DIR)/shim$(EFI_ARCH).efi.signed" \
		"$(SHIM_INSTALL_DIR)/shim$(EFI_ARCH).efi"
	$(Q) touch $@

MACHINE_CLEAN += shim-clean
shim-clean:
	$(Q) rm -rf $(SHIM_BUILD_DIR)
	$(Q) rm -f $(SHIM_STAMP) $(SHIM_SELF_SIGN_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += shim-download-clean
shim-download-clean:
	$(Q) rm -f $(SHIM_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(SHIM_TARBALL)
