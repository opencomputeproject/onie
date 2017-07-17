#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2015,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015,2017 david_yang <david_yang@accton.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of grub
#

GRUB_VERSION		= 2.02~beta3
GRUB_TARBALL		= grub-$(GRUB_VERSION).tar.xz
GRUB_TARBALL_URLS	+= $(ONIE_MIRROR) http://git.savannah.gnu.org/cgit/grub.git/snapshot/ ftp://alpha.gnu.org/gnu/grub/
GRUB_BUILD_DIR		= $(USER_BUILDDIR)/grub
GRUB_DIR		= $(GRUB_BUILD_DIR)/grub-$(GRUB_VERSION)
GRUB_I386_DIR		= $(GRUB_BUILD_DIR)/grub-i386-pc
GRUB_UEFI_DIR		= $(GRUB_BUILD_DIR)/grub-$(ARCH)-efi
GRUB_I386_COREBOOT_DIR	= $(GRUB_BUILD_DIR)/grub-i386-coreboot
GRUB_INSTALL_I386_DIR		= $(GRUB_BUILD_DIR)/install/grub-i386-pc
GRUB_INSTALL_UEFI_DIR		= $(GRUB_BUILD_DIR)/install/grub-$(ARCH)-efi
GRUB_INSTALL_I386_COREBOOT_DIR	= $(GRUB_BUILD_DIR)/install/grub-i386-coreboot
GRUB_TARGET_LIB_I386_DIR       = $(GRUB_INSTALL_I386_DIR)/usr/lib/grub/i386-pc
GRUB_TARGET_LIB_UEFI_DIR       = $(GRUB_INSTALL_UEFI_DIR)/usr/lib/grub/$(ARCH)-efi

GRUB_SRCPATCHDIR	= $(PATCHDIR)/grub/$(GRUB_VERSION)
GRUB_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/grub-$(GRUB_VERSION)-download
GRUB_SOURCE_STAMP	= $(USER_STAMPDIR)/grub-source
GRUB_PATCH_STAMP	= $(USER_STAMPDIR)/grub-patch
GRUB_CONFIGURE_STAMP	= $(USER_STAMPDIR)/grub-configure
GRUB_BUILD_STAMP	= $(USER_STAMPDIR)/grub-build
GRUB_INSTALL_STAMP	= $(STAMPDIR)/grub-install
ifeq ($(FIRMWARE_TYPE),$(filter $(FIRMWARE_TYPE),auto bios))
  GRUB_CONFIGURE_I386_STAMP	= $(USER_STAMPDIR)/grub-configure-i386-pc
  GRUB_BUILD_I386_STAMP		= $(USER_STAMPDIR)/grub-build-i386-pc
  GRUB_INSTALL_I386_STAMP	= $(STAMPDIR)/grub-install-i386-pc
endif
ifeq ($(UEFI_ENABLE),yes)
  GRUB_TARGET_UEFI_ENABLE	= yes
endif
ifeq ($(PXE_EFI64_ENABLE),yes)
  GRUB_TARGET_UEFI_ENABLE	= yes
endif
ifeq ($(GRUB_TARGET_UEFI_ENABLE),yes)
  GRUB_CONFIGURE_UEFI_STAMP	= $(USER_STAMPDIR)/grub-configure-$(ARCH)-efi
  GRUB_BUILD_UEFI_STAMP		= $(USER_STAMPDIR)/grub-build-$(ARCH)-efi
  GRUB_INSTALL_UEFI_STAMP	= $(STAMPDIR)/grub-install-$(ARCH)-efi
endif
ifeq ($(FIRMWARE_TYPE),coreboot)
  GRUB_CONFIGURE_I386_COREBOOT_STAMP	= $(USER_STAMPDIR)/grub-configure-i386-coreboot
  GRUB_BUILD_I386_COREBOOT_STAMP	= $(USER_STAMPDIR)/grub-build-i386-coreboot
  GRUB_INSTALL_I386_COREBOOT_STAMP	= $(STAMPDIR)/grub-install-i386-coreboot
endif

GRUB_STAMP		= $(GRUB_SOURCE_STAMP) \
			  $(GRUB_PATCH_STAMP) \
			  $(GRUB_CONFIGURE_I386_STAMP) \
			  $(GRUB_CONFIGURE_UEFI_STAMP) \
			  $(GRUB_CONFIGURE_I386_COREBOOT_STAMP) \
			  $(GRUB_CONFIGURE_STAMP) \
			  $(GRUB_BUILD_I386_STAMP) \
			  $(GRUB_BUILD_UEFI_STAMP) \
			  $(GRUB_BUILD_I386_COREBOOT_STAMP) \
			  $(GRUB_BUILD_STAMP) \
			  $(GRUB_INSTALL_I386_STAMP) \
			  $(GRUB_INSTALL_UEFI_STAMP) \
			  $(GRUB_INSTALL_I386_COREBOOT_STAMP) \
			  $(GRUB_INSTALL_STAMP)

# GRUB configuration options common to i386-pc and $(ARCH)-efi
GRUB_COMMON_CONFIG = 			\
		--prefix=/usr		\
		--enable-device-mapper	\
		--disable-nls		\
		--disable-efiemu	\
		--disable-grub-mkfont	\
		--disable-grub-themes

PHONY += grub grub-download grub-source grub-patch \
	 grub-configure grub-build grub-install grub-clean \
	 grub-download-clean

GRUB_SBIN = grub-install grub-bios-setup grub-probe grub-reboot grub-set-default
GRUB_BIN = grub-mkrelpath grub-mkimage grub-editenv

grub: $(GRUB_STAMP)

DOWNLOAD += $(GRUB_DOWNLOAD_STAMP)
grub-download: $(GRUB_DOWNLOAD_STAMP)
$(GRUB_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream grub ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(GRUB_TARBALL) $(GRUB_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(GRUB_SOURCE_STAMP)
grub-source: $(GRUB_SOURCE_STAMP)
$(GRUB_SOURCE_STAMP): $(USER_TREE_STAMP) | $(GRUB_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream grub ===="
	$(Q) $(SCRIPTDIR)/extract-package $(GRUB_BUILD_DIR) $(DOWNLOADDIR)/$(GRUB_TARBALL)
	$(Q) touch $@

grub-patch: $(GRUB_PATCH_STAMP)
$(GRUB_PATCH_STAMP): $(GRUB_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Patching grub-$(GRUB_VERSION) ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(GRUB_SRCPATCHDIR)/series $(GRUB_DIR)
	$(Q) cd $(GRUB_DIR) && ./autogen.sh
	$(Q) touch $@

$(GRUB_CONFIGURE_I386_STAMP): $(GRUB_PATCH_STAMP) $(LVM2_BUILD_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-i386-pc-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_I386_DIR)
	$(Q) cd $(GRUB_I386_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		grub_build_mkfont_excuse="explicitly disabled"	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--host=$(TARGET)				\
		--with-platform=pc				\
		CC=$(CROSSPREFIX)gcc				\
		CPPFLAGS="$(ONIE_CPPFLAGS)"			\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

$(GRUB_CONFIGURE_UEFI_STAMP): $(GRUB_PATCH_STAMP) $(LVM2_BUILD_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-$(ARCH)-efi-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_UEFI_DIR)
	$(Q) cd $(GRUB_UEFI_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		grub_build_mkfont_excuse="explicitly disabled"	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--host=$(TARGET)				\
		--with-platform=efi				\
		CC=$(CROSSPREFIX)gcc				\
		CPPFLAGS="$(ONIE_CPPFLAGS)"			\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

$(GRUB_CONFIGURE_I386_COREBOOT_STAMP): $(GRUB_PATCH_STAMP) $(LVM2_BUILD_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-i386-coreboot-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_I386_COREBOOT_DIR)
	$(Q) cd $(GRUB_I386_COREBOOT_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--host=$(TARGET)				\
		--with-platform=coreboot				\
		CC=$(CROSSPREFIX)gcc				\
		CPPFLAGS="$(ONIE_CPPFLAGS)"			\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

grub-configure: $(GRUB_CONFIGURE_STAMP)
$(GRUB_CONFIGURE_STAMP): $(GRUB_CONFIGURE_I386_STAMP) $(GRUB_CONFIGURE_UEFI_STAMP) $(GRUB_CONFIGURE_I386_COREBOOT_STAMP)
	$(Q) touch $@

$(GRUB_BUILD_I386_STAMP): $(GRUB_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-i386-pc-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_I386_DIR)
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(GRUB_I386_DIR) install DESTDIR=$(GRUB_INSTALL_I386_DIR)
	$(Q) touch $@

$(GRUB_BUILD_UEFI_STAMP): $(GRUB_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-$(ARCH)-efi-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_UEFI_DIR)
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(GRUB_UEFI_DIR) install DESTDIR=$(GRUB_INSTALL_UEFI_DIR)
	$(Q) touch $@

$(GRUB_BUILD_I386_COREBOOT_STAMP): $(GRUB_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-i386-coreboot-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_I386_COREBOOT_DIR)
	$(Q) PATH='$(CROSSBIN):$(PATH)'			\
		$(MAKE) -C $(GRUB_I386_COREBOOT_DIR) install DESTDIR=$(GRUB_INSTALL_I386_COREBOOT_DIR)
	$(Q) touch $@

grub-build: $(GRUB_BUILD_STAMP)
$(GRUB_BUILD_STAMP): $(GRUB_BUILD_I386_STAMP) $(GRUB_BUILD_UEFI_STAMP) $(GRUB_BUILD_I386_COREBOOT_STAMP)
	$(Q) touch $@

# $(1) -- the type of grub binary
# $(2) -- the build grub install direcoty
# $(3) -- the destination systroot directory
define grub_install
	$(Q) echo "==== Installing $(1) in $(3) ===="
	$(Q) cp -a $(2)/usr/lib/grub $(3)/usr/lib
	$(Q) cp -a $(2)/usr/share/grub $(3)/usr/share
	$(Q) for f in $(GRUB_SBIN) ; do \
		cp -a $(2)/usr/sbin/$$f $(3)/usr/sbin ; \
	done
	$(Q) for f in $(GRUB_BIN) ; do \
		cp -a $(2)/usr/bin/$$f $(3)/usr/bin ; \
	done
endef

$(GRUB_INSTALL_I386_STAMP): $(SYSROOT_INIT_STAMP) $(GRUB_BUILD_I386_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(call grub_install, grub-i386-pc, $(GRUB_INSTALL_I386_DIR), $(SYSROOTDIR))
	$(Q) touch $@

$(GRUB_INSTALL_UEFI_STAMP): $(SYSROOT_INIT_STAMP) $(GRUB_INSTALL_I386_STAMP) $(GRUB_BUILD_UEFI_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(call grub_install, grub-$(ARCH)-efi, $(GRUB_INSTALL_UEFI_DIR), $(SYSROOTDIR))
	$(Q) touch $@

$(GRUB_INSTALL_I386_COREBOOT_STAMP): $(SYSROOT_INIT_STAMP) $(GRUB_INSTALL_I386_STAMP) $(GRUB_BUILD_I386_COREBOOT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(call grub_install, grub-i386-coreboot, $(GRUB_INSTALL_I386_COREBOOT_DIR), $(SYSROOTDIR))
	$(Q) touch $@

grub-install: $(GRUB_INSTALL_STAMP)
$(GRUB_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(GRUB_INSTALL_I386_STAMP) \
	$(GRUB_INSTALL_UEFI_STAMP) $(GRUB_INSTALL_I386_COREBOOT_STAMP)
	$(Q) touch $@

USER_CLEAN += grub-clean
grub-clean:
	$(Q) rm -rf $(GRUB_BUILD_DIR)
	$(Q) rm -f $(GRUB_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += grub-download-clean
grub-download-clean:
	$(Q) rm -f $(GRUB_DOWNLOAD_STAMP) $(DOWNLOADDIR)/grub*

# ---------------------------------------------------------------------------
# grub-host build rules

# Building the .ISO image requires a host build of GRUB.

GRUB_HOST_BUILD_DIR		= $(USER_BUILDDIR)/grub-host
GRUB_HOST_DIR			= $(GRUB_HOST_BUILD_DIR)/grub-$(GRUB_VERSION)
GRUB_HOST_I386_DIR		= $(GRUB_HOST_BUILD_DIR)/grub-i386-pc
GRUB_HOST_UEFI_DIR		= $(GRUB_HOST_BUILD_DIR)/grub-x86_64-efi
GRUB_HOST_INSTALL_I386_DIR	= $(GRUB_HOST_BUILD_DIR)/i386-pc-install
GRUB_HOST_LIB_I386_DIR		= $(GRUB_HOST_INSTALL_I386_DIR)/usr/lib/grub/i386-pc
GRUB_HOST_BIN_I386_DIR		= $(GRUB_HOST_INSTALL_I386_DIR)/usr/bin
GRUB_HOST_INSTALL_UEFI_DIR	= $(GRUB_HOST_BUILD_DIR)/x86_64-efi-install
GRUB_HOST_LIB_UEFI_DIR		= $(GRUB_HOST_INSTALL_UEFI_DIR)/usr/lib/grub/x86_64-efi
GRUB_HOST_BIN_UEFI_DIR		= $(GRUB_HOST_INSTALL_UEFI_DIR)/usr/bin
GRUB_HOST_CONFIGURE_STAMP	= $(USER_STAMPDIR)/grub-host-configure
GRUB_HOST_BUILD_STAMP		= $(USER_STAMPDIR)/grub-host-build
GRUB_HOST_INSTALL_STAMP		= $(STAMPDIR)/grub-host-install
GRUB_HOST_CONFIGURE_I386_STAMP	= $(USER_STAMPDIR)/grub-host-configure-i386-pc
GRUB_HOST_BUILD_I386_STAMP	= $(USER_STAMPDIR)/grub-host-build-i386-pc
GRUB_HOST_INSTALL_I386_STAMP	= $(USER_STAMPDIR)/grub-host-install-i386-pc
GRUB_HOST_UEFI_ENABLE		= no
ifeq ($(UEFI_ENABLE),yes)
  GRUB_HOST_UEFI_ENABLE = yes
endif
ifeq ($(PXE_EFI64_ENABLE),yes)
  GRUB_HOST_UEFI_ENABLE = yes
endif
ifeq ($(GRUB_HOST_UEFI_ENABLE),yes)
  GRUB_HOST_CONFIGURE_UEFI_STAMP= $(USER_STAMPDIR)/grub-host-configure-x86_64-efi
  GRUB_HOST_BUILD_UEFI_STAMP	= $(USER_STAMPDIR)/grub-host-build-x86_64-efi
  GRUB_HOST_INSTALL_UEFI_STAMP	= $(USER_STAMPDIR)/grub-host-install-x86_64-efi
endif

PHONY += grub-host-configure grub-host-build grub-host-install grub-host-clean

GRUB_HOST_STAMP = $(GRUB_HOST_CONFIGURE_I386_STAMP) \
		  $(GRUB_HOST_CONFIGURE_UEFI_STAMP) \
		  $(GRUB_HOST_CONFIGURE_STAMP) \
		  $(GRUB_HOST_BUILD_I386_STAMP) \
		  $(GRUB_HOST_BUILD_UEFI_STAMP) \
		  $(GRUB_HOST_BUILD_STAMP) \
		  $(GRUB_HOST_INSTALL_I386_STAMP) \
		  $(GRUB_HOST_INSTALL_UEFI_STAMP) \
		  $(GRUB_HOST_INSTALL_STAMP)

grub-host: $(GRUB_HOST_STAMP)

$(GRUB_HOST_CONFIGURE_I386_STAMP): $(GRUB_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-host-i386-pc-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_HOST_I386_DIR)
	$(Q) cd $(GRUB_HOST_I386_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		grub_build_mkfont_excuse="explicitly disabled"	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--with-platform=pc
	$(Q) touch $@

$(GRUB_HOST_CONFIGURE_UEFI_STAMP): $(GRUB_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure grub-host-x86_64-efi-$(GRUB_VERSION) ===="
	$(Q) mkdir -p $(GRUB_HOST_UEFI_DIR)
	$(Q) cd $(GRUB_HOST_UEFI_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		grub_build_mkfont_excuse="explicitly disabled"	\
		$(GRUB_DIR)/configure $(GRUB_COMMON_CONFIG)	\
		--with-platform=efi
	$(Q) touch $@

grub-host-configure: $(GRUB_HOST_CONFIGURE_STAMP)
$(GRUB_HOST_CONFIGURE_STAMP): $(GRUB_HOST_CONFIGURE_I386_STAMP) $(GRUB_HOST_CONFIGURE_UEFI_STAMP)
	$(Q) touch $@

$(GRUB_HOST_BUILD_I386_STAMP): $(GRUB_HOST_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-host-i386-pc-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_HOST_I386_DIR)
	$(Q) touch $@

$(GRUB_HOST_BUILD_UEFI_STAMP): $(GRUB_HOST_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building grub-host-x86_64-efi-$(GRUB_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(GRUB_HOST_UEFI_DIR)
	$(Q) touch $@

grub-host-build: $(GRUB_HOST_BUILD_STAMP)
$(GRUB_HOST_BUILD_STAMP): $(GRUB_HOST_BUILD_I386_STAMP) $(GRUB_HOST_BUILD_UEFI_STAMP)
	$(Q) touch $@

$(GRUB_HOST_INSTALL_I386_STAMP): $(GRUB_HOST_BUILD_I386_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing grub-host-i386-pc in $(GRUB_HOST_INSTALL_I386_DIR) ===="
	$(Q) $(MAKE) -C $(GRUB_HOST_I386_DIR) install DESTDIR=$(GRUB_HOST_INSTALL_I386_DIR)
	$(Q) touch $@

$(GRUB_HOST_INSTALL_UEFI_STAMP): $(GRUB_HOST_BUILD_UEFI_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing grub-host-x86_64-efi in $(GRUB_HOST_INSTALL_UEFI_DIR) ===="
	$(Q) $(MAKE) -C $(GRUB_HOST_UEFI_DIR) install DESTDIR=$(GRUB_HOST_INSTALL_UEFI_DIR)
	$(Q) touch $@

grub-host-install: $(GRUB_HOST_INSTALL_STAMP)
$(GRUB_HOST_INSTALL_STAMP): $(TREE_STAMP) $(GRUB_HOST_INSTALL_I386_STAMP) $(GRUB_HOST_INSTALL_UEFI_STAMP)
	$(Q) touch $@

USER_CLEAN += grub-host-clean
grub-host-clean:
	$(Q) rm -rf $(GRUB_HOST_BUILD_DIR)
	$(Q) rm -f $(GRUB_HOST_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
