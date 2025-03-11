#-------------------------------------------------------------------------------
#
#  Copyright (C) 2020,2021 Alex Doyle <adoyle@nvidia.com>
#  Copyright (C) 2021 Andriy Dobush <andriyd@nvidia.com>
#  Copyright (C) 2013,2014,2015,2016,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014,2015,2016,2017 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Stephen Su <sustephen@juniper.net>
#  Copyright (C) 2014 Puneet <puneet@cumulusnetworks.com>
#  Copyright (C) 2015 Carlos Cardenas <carlos@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the creation of onie images
#

ROOTCONFDIR		= $(CONFDIR)
SYSROOT_CPIO		= $(MBUILDDIR)/sysroot.cpio
SYSROOT_CPIO_XZ		= $(IMAGEDIR)/$(MACHINE_PREFIX).initrd
SYSROOT_CPIO_XZ_SIG = $(SYSROOT_CPIO_XZ).sig
ITB_IMAGE		= $(IMAGEDIR)/$(MACHINE_PREFIX).itb

UPDATER_ITB		= $(MBUILDDIR)/onie.itb
UPDATER_INITRD		= $(MBUILDDIR)/onie.initrd
UPDATER_INITRD_SIG  = $(MBUILDDIR)/onie.initrd.sig
UPDATER_ONIE_TOOLS	= $(MBUILDDIR)/onie-tools.tar.xz

UPDATER_IMAGE		= $(IMAGEDIR)/onie-updater-$(ARCH)-$(MACHINE_PREFIX)

ONIE_TOOLS_DIR	= $(abspath ../tools)
ONIE_SYSROOT_TOOLS_LIST = \
	lib/onie \
	bin/onie-boot-mode \
	bin/onie-nos-mode \
	bin/onie-fwpkg

IMAGE_BIN_STAMP		= $(STAMPDIR)/image-bin
IMAGE_UPDATER_STAMP	= $(STAMPDIR)/image-updater
IMAGE_COMPLETE_STAMP	= $(STAMPDIR)/image-complete
IMAGE			= $(IMAGE_COMPLETE_STAMP)

LSB_RELEASE_FILE = $(MBUILDDIR)/lsb-release
OS_RELEASE_FILE	 = $(MBUILDDIR)/os-release
MACHINE_CONF	 = $(MBUILDDIR)/machine-build.conf

INSTALLER_DIR	= $(abspath ../installer)

# List the packages to install
PACKAGES_INSTALL_STAMPS += \
	$(ZLIB_INSTALL_STAMP) \
	$(BUSYBOX_INSTALL_STAMP) \
	$(MTDUTILS_INSTALL_STAMP) \
	$(DROPBEAR_INSTALL_STAMP) \
	$(I2CTOOLS_INSTALL_STAMP) \
	$(LVM2_INSTALL_STAMP) \
	$(DMIDECODE_INSTALL_STAMP) \
	$(ETHTOOL_INSTALL_STAMP)

ifeq ($(GPT_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(GPTFDISK_INSTALL_STAMP)
endif

ifeq ($(PARTED_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(PARTED_INSTALL_STAMP)
endif

ifeq ($(GRUB_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(GRUB_INSTALL_STAMP)
endif

ifeq ($(MTREE_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(MTREE_INSTALL_STAMP)
endif

ifeq ($(ACPI_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(ACPICA_TOOLS_INSTALL_STAMP)
endif

ifeq ($(UEFI_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(EFIBOOTMGR_INSTALL_STAMP)
endif

ifeq ($(DOSFSTOOLS_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(DOSFSTOOLS_INSTALL_STAMP)
endif

ifeq ($(KEXEC_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(KEXEC_INSTALL_STAMP)
endif

ifeq ($(FLASHROM_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(FLASHROM_INSTALL_STAMP)
endif

ifeq ($(IPMITOOL_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(IPMITOOL_INSTALL_STAMP)
endif

ifeq ($(EXT3_4_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(E2FSPROGS_INSTALL_STAMP)
endif

ifeq ($(BTRFS_PROGS_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(BTRFSPROGS_INSTALL_STAMP)
endif

ifeq ($(OPENSSL_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(OPENSSL_INSTALL_STAMP)
endif

ifeq ($(MOKUTIL_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(MOKUTIL_INSTALL_STAMP)
endif

ifeq ($(KEYUTILS_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(KEYUTILS_INSTALL_STAMP)
endif

ifeq ($(SECURE_GRUB),no)
  GPG_SIGN_SECRING = ''
endif

ifeq ($(TCPDUMP_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(TCPDUMP_STAMP)
endif

ifndef MAKE_CLEAN
SYSROOT_NEW_FILES = $(shell \
			test -d $(ROOTCONFDIR)/default && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(ROOTCONFDIR)/default -mindepth 1 -cnewer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
SYSROOT_NEW_FILES += $(shell \
			test -d $(ROOTCONFDIR)/$(ROOTFS_ARCH) && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(ROOTCONFDIR)/$(ROOTFS_ARCH) -mindepth 1 -cnewer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
SYSROOT_NEW_FILES += $(shell \
			test -d $(MACHINEDIR)/rootconf && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(MACHINEDIR)/rootconf -mindepth 1 -cnewer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(strip $(SYSROOT_NEW_FILES)),)
    $(shell rm -f $(SYSROOT_COMPLETE_STAMP))
  endif
endif

PHONY += sysroot-check sysroot-complete

CHECKROOT	= $(MBUILDDIR)/check

ifeq ($(XTOOLS_LIBC),uClibc-ng)
  SYSROOT_LIBS	= ld$(CLIB64)-uClibc.so.0 ld$(CLIB64)-uClibc-$(XTOOLS_LIBC_VERSION).so \
		  ld$(CLIB64)-uClibc.so.1 \
		  libc.so.0 libuClibc-$(XTOOLS_LIBC_VERSION).so \
		  libgcc_s.so.1 libgcc_s.so
else ifeq ($(XTOOLS_LIBC),uClibc)
  SYSROOT_LIBS	= ld$(CLIB64)-uClibc.so.0 ld$(CLIB64)-uClibc-$(XTOOLS_LIBC_VERSION).so \
		  libm.so.0 libm-$(XTOOLS_LIBC_VERSION).so \
		  libgcc_s.so.1 libgcc_s.so \
		  libc.so.0 libuClibc-$(XTOOLS_LIBC_VERSION).so \
		  libcrypt.so.0 libcrypt-$(XTOOLS_LIBC_VERSION).so \
		  libutil.so.0 libutil-$(XTOOLS_LIBC_VERSION).so \


  ifeq ($(EXT3_4_ENABLE),yes)
    SYSROOT_LIBS	+= \
		  libdl.so.0 libdl-$(XTOOLS_LIBC_VERSION).so \
		  libpthread.so.0 libpthread-$(XTOOLS_LIBC_VERSION).so
  endif
  # Add librt if ACPI or LVM2 is enabled
  ifneq ($(filter yes, $(ACPI_ENABLE) $(LVM2_ENABLE)),)
    SYSROOT_LIBS	+= \
		  librt.so.0 librt-$(XTOOLS_LIBC_VERSION).so
  endif
else ifeq ($(XTOOLS_LIBC),glibc)
SYSROOT_LIBS	= ld-$(XTOOLS_LIBC_VERSION).so \
		  libm.so.6 libm-$(XTOOLS_LIBC_VERSION).so \
		  libgcc_s.so.1 libgcc_s.so \
		  libc.so.6 libc-$(XTOOLS_LIBC_VERSION).so \
		  libcrypt.so.1 libcrypt-$(XTOOLS_LIBC_VERSION).so \
		  libutil.so.1 libutil-$(XTOOLS_LIBC_VERSION).so \
		  libdl.so.2 libdl-$(XTOOLS_LIBC_VERSION).so \
		  libpthread.so.0 libpthread-$(XTOOLS_LIBC_VERSION).so \
		  librt.so.1 librt-$(XTOOLS_LIBC_VERSION).so \
		  libnss_dns.so.2 libnss_dns-$(XTOOLS_LIBC_VERSION).so \
		  libresolv.so.2 libresolv-$(XTOOLS_LIBC_VERSION).so  \
		  libnss_files.so.2 libnss_files-$(XTOOLS_LIBC_VERSION).so
  ifeq ($(ARCH),arm64)
    SYSROOT_LIBS	+= ld-linux-aarch64.so.1
  endif
endif

ifeq ($(REQUIRE_CXX_LIBS),yes)
  SYSROOT_LIBS += libstdc++.so libstdc++.so.6
  ifeq ($(GCC_VERSION),6.3.0)
    SYSROOT_LIBS += libstdc++.so.6.0.22
  else ifeq ($(GCC_VERSION),4.9.2)
    SYSROOT_LIBS += libstdc++.so.6.0.20
  else ifeq ($(GCC_VERSION),8.3.0)
    SYSROOT_LIBS += libstdc++.so.6.0.25
  else
    $(error C++ support: Unsupported GCC version: $(GCC_VERSION))
  endif
endif

# Optionally add debug utilities
DEBUG_UTILS =

# Add strace to the distribution by default
STRACE_ENABLE ?= yes

ifeq ($(STRACE_ENABLE),yes)
DEBUG_UTILS += $(XTOOLS_DEBUG_ROOT)/usr/bin/strace
endif

# sysroot-check does the following:
#
# - strip the ELF binaries (grub modules and kernel)
#
# - verifies that we have all the shared libraries required by the
#   executables in our final sysroot.

sysroot-check: $(SYSROOT_CHECK_STAMP)
$(SYSROOT_CHECK_STAMP): $(PACKAGES_INSTALL_STAMPS)
	$(Q) for file in $(SYSROOT_LIBS) ; do \
		if [ "$(ARCH)" == "arm64" ] ; then \
		    [ -r "$(DEV_SYSROOT)/lib64/$$file" ] || [ -r "$(DEV_SYSROOT)/lib/$$file" ] || { \
			    echo "ERROR: Missing SYSROOT_LIB: $$file" ; \
			    exit 1; } ; \
			find $(DEV_SYSROOT)/lib64 $(DEV_SYSROOT)/lib -name $$file | xargs -i cp -av {} $(SYSROOTDIR)/lib/ || exit 1 ; \
		else \
		    [ -r "$(DEV_SYSROOT)/lib/$$file" ] || { \
			    echo "ERROR: Missing SYSROOT_LIB: $$file under $(DEV_SYSROOT)/lib" ; \
			    exit 1; } ; \
			find $(DEV_SYSROOT)/lib -name $$file | xargs -i cp -av {} $(SYSROOTDIR)/lib/ || exit 1 ; \
		fi; \
	done
	$(Q) for file in $(DEBUG_UTILS) ; do \
		cp -av $$file $(SYSROOTDIR)/usr/bin || exit 1 ; \
		chmod +w $(SYSROOTDIR)/usr/bin/$$(basename $$file) ; \
	done
	$(Q) find $(SYSROOTDIR) -path */lib/grub/* -prune -o \( -type f -print0 \) | xargs -0 file | \
		grep ELF | awk -F':' '{ print $$1 }' | grep -v "/lib/modules/" | xargs $(CROSSBIN)/$(CROSSPREFIX)strip
ifeq ($(XTOOLS_ENABLE),yes)
	$(Q) rm -rf $(CHECKROOT)
	$(Q) $(SCRIPTDIR)/check-libs $(CROSSBIN)/$(CROSSPREFIX)populate \
		$(DEV_SYSROOT) $(SYSROOTDIR) $(CHECKROOT)
endif
	$(Q) touch $@

# Setting ONIE_BUILD_MACHINE on the command line allows you "fake" a
# real machine at runtime.  This is particularly useful when MACHINE
# is the kvm_x86_64 virtual machine.  Using these variables you can
# make the running virtual machine look like a specific real machine.
# This is useful when developing an installer for a particular
# platform.  You can develop the installer using the virtual machine.
ONIE_BUILD_MACHINE	?= $(MACHINE)

sysroot-complete: $(SYSROOT_COMPLETE_STAMP)
$(SYSROOT_COMPLETE_STAMP): $(SYSROOT_CHECK_STAMP)
	$(Q) rm -f $(SYSROOTDIR)/linuxrc
	$(Q) cd $(ROOTCONFDIR) && $(SCRIPTDIR)/install-rootfs.sh default $(SYSROOTDIR)
	$(Q) if [ -d $(ROOTCONFDIR)/$(ROOTFS_ARCH)/sysroot-lib-onie ] ; then \
		cp $(ROOTCONFDIR)/$(ROOTFS_ARCH)/sysroot-lib-onie/* $(SYSROOTDIR)/lib/onie ; \
	     fi
	$(Q) if [ -d $(ROOTCONFDIR)/$(ROOTFS_ARCH)/sysroot-bin ] ; then	\
		cp $(ROOTCONFDIR)/$(ROOTFS_ARCH)/sysroot-bin/* $(SYSROOTDIR)/bin ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-lib-onie ] ; then \
		cp $(MACHINEDIR)/rootconf/sysroot-lib-onie/* $(SYSROOTDIR)/lib/onie ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-bin ] ; then \
		cp $(MACHINEDIR)/rootconf/sysroot-bin/* $(SYSROOTDIR)/bin ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-init ] ; then \
		cp $(MACHINEDIR)/rootconf/sysroot-init/* $(SYSROOTDIR)/etc/init.d ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-rcS ] ; then \
		cp -a $(MACHINEDIR)/rootconf/sysroot-rcS/* $(SYSROOTDIR)/etc/rcS.d ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-rcK ] ; then \
		cp -a $(MACHINEDIR)/rootconf/sysroot-rcK/* $(SYSROOTDIR)/etc/rc0.d ; \
		cp -a $(MACHINEDIR)/rootconf/sysroot-rcK/* $(SYSROOTDIR)/etc/rc6.d ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-etc ] ; then \
		cp -ar $(MACHINEDIR)/rootconf/sysroot-etc/* $(SYSROOTDIR)/etc/ ; \
	     fi
ifeq ($(SECURE_BOOT_EXT),yes)
# Allow passwords to be disabled if Secure Boot is off.
# Copy the console open that uses /bin/sh as onie-console-open
	$(Q) cp $(SYSROOTDIR)/bin/onie-console $(SYSROOTDIR)/bin/onie-console-open
# Dynamically create a secured console version that uses login instead of /bin/sh
	$(Q) sed -i 's/exec \/bin\/sh -l/exec \/bin\/login/' $(SYSROOTDIR)/bin/onie-console
# Save a copy of the secured.
	$(Q) cp $(SYSROOTDIR)/bin/onie-console $(SYSROOTDIR)/bin/onie-console-secure
# Apply machine specific ONIE password file
	$(Q) if [ -e $(MACHINEDIR)/rootconf/sysroot-etc/passwd-secured ] ; then \
                cp -a $(MACHINEDIR)/rootconf/sysroot-etc/passwd-secured $(SYSROOTDIR)/etc/passwd ; \
             fi
endif
	$(Q) cd $(SYSROOTDIR) && ln -fs sbin/init ./init
	$(Q) rm -f $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_ID=onie" >> $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_RELEASE=$(LSB_RELEASE_TAG)" >> $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_DESCRIPTION=Open Network Install Environment" >> $(LSB_RELEASE_FILE)
	$(Q) rm -f $(OS_RELEASE_FILE)
	$(Q) echo "NAME=\"onie\"" >> $(OS_RELEASE_FILE)
	$(Q) echo "VERSION=\"$(LSB_RELEASE_TAG)\"" >> $(OS_RELEASE_FILE)
	$(Q) echo "ID=linux" >> $(OS_RELEASE_FILE)
	$(Q) rm -f $(MACHINE_CONF)
	$(Q) echo "onie_version=$(LSB_RELEASE_TAG)" >> $(MACHINE_CONF)
	$(Q) echo "onie_vendor_id=$(VENDOR_ID)" >> $(MACHINE_CONF)
	$(Q) echo "onie_build_machine=$(ONIE_BUILD_MACHINE)" >> $(MACHINE_CONF)
	$(Q) echo "onie_machine_rev=$(MACHINE_REV)" >> $(MACHINE_CONF)
	$(Q) echo "onie_arch=$(ARCH)" >> $(MACHINE_CONF)
	$(Q) echo "onie_build_platform=$(ARCH)-$(ONIE_BUILD_MACHINE)-r$(MACHINE_REV)" >> $(MACHINE_CONF)
	$(Q) echo "onie_config_version=$(ONIE_CONFIG_VERSION)" >> $(MACHINE_CONF)
	$(Q) echo "onie_build_date=\"$(ONIE_BUILD_DATE)\"" >> $(MACHINE_CONF)
	$(Q) echo "onie_partition_type=$(PARTITION_TYPE)" >> $(MACHINE_CONF)
	$(Q) echo "onie_kernel_version=$(LINUX_RELEASE)" >> $(MACHINE_CONF)
	$(Q) echo "onie_firmware=$(FIRMWARE_TYPE)" >> $(MACHINE_CONF)
	$(Q) echo "onie_switch_asic=$(SWITCH_ASIC_VENDOR)" >> $(MACHINE_CONF)
	$(Q) echo "onie_skip_ethmgmt_macs=$(SKIP_ETHMGMT_MACS)" >> $(MACHINE_CONF)
ifeq ($(UEFI_ENABLE),yes)
	$(Q) echo "onie_grub_image_name=$(UEFI_BOOT_LOADER)" >> $(MACHINE_CONF)
	$(Q) echo "onie_uefi_boot_loader=$(UEFI_BOOT_LOADER)" >> $(MACHINE_CONF)
	$(Q) echo "onie_uefi_arch=$(EFI_ARCH)" >> $(MACHINE_CONF)
endif
ifeq ($(SECURE_BOOT_EXT),yes)
	$(Q) echo "onie_secure_boot_ext=$(SECURE_BOOT_EXT)" >> $(MACHINE_CONF)
endif
ifeq ($(SECURE_GRUB),yes)
	$(Q) echo "onie_secure_grub=$(SECURE_GRUB)" >> $(MACHINE_CONF)
endif
ifeq ($(SECURE_BOOT_ENABLE),yes)
	$(Q) echo "onie_secure_boot=$(SECURE_BOOT_ENABLE)" >> $(MACHINE_CONF)
endif
	$(Q) cp $(LSB_RELEASE_FILE) $(SYSROOTDIR)/etc/lsb-release
	$(Q) cp $(OS_RELEASE_FILE) $(SYSROOTDIR)/etc/os-release
	$(Q) cp $(MACHINE_CONF) $(SYSROOTDIR)/etc/machine-build.conf
	$(Q) touch $@

# This step creates the cpio archive and compresses it
$(SYSROOT_CPIO_XZ) : $(SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create xz compressed sysroot for bootstrap ===="
	$(Q) fakeroot -- $(SCRIPTDIR)/make-sysroot.sh $(SYSROOTDIR) $(SYSROOT_CPIO)
	$(Q) xz --compress --force --check=crc32 --stdout -8 $(SYSROOT_CPIO) > $@
ifeq ($(SECURE_GRUB),yes)
	# Create a detached signature so that grub can verify it
	$(Q) echo "==== GPG sign file $(SYSROOT_CPIO_XZ) ===="
	$(Q) fakeroot -- $(SCRIPTDIR)/gpg-sign.sh $(GPG_SIGN_SECRING) $(SYSROOT_CPIO_XZ)
endif

$(UPDATER_INITRD) : $(SYSROOT_CPIO_XZ)
	ln -sf $< $@
ifeq ($(SECURE_GRUB),yes)
	ln -sf $(SYSROOT_CPIO_XZ_SIG) $(UPDATER_INITRD_SIG)
endif

ifndef MAKE_CLEAN
ONIE_TOOLS_FILES = $(shell \
		test -d $(ONIE_TOOLS_DIR) && test -r $(UPDATER_ONIE_TOOLS) && \
		find -L $(ONIE_TOOLS_DIR) -mindepth 1 -cnewer $(UPDATER_ONIE_TOOLS) \
		  -print -quit 2>/dev/null)
  ifneq ($(strip $(ONIE_TOOLS_FILES)),)
    $(shell rm -f $(UPDATER_ONIE_TOOLS))
  endif
endif

$(UPDATER_ONIE_TOOLS): $(SYSROOT_COMPLETE_STAMP) $(SCRIPTDIR)/onie-mk-tools.sh
	$(Q) echo "==== Create ONIE Tools tarball ===="
	$(Q) fakeroot -- $(SCRIPTDIR)/onie-mk-tools.sh $(ROOTFS_ARCH) $(ONIE_TOOLS_DIR) $@ \
		$(SYSROOTDIR) $(ONIE_SYSROOT_TOOLS_LIST)

.SECONDARY: $(ITB_IMAGE)

$(IMAGEDIR)/%.itb : $(KERNEL_INSTALL_STAMP) $(SYSROOT_CPIO_XZ) $(SCRIPTDIR)/onie-mk-itb.sh
	$(Q) echo "==== Create $* u-boot multi-file .itb image ===="
	$(Q) cd $(IMAGEDIR) && \
		V=$(V) $(SCRIPTDIR)/onie-mk-itb.sh $(MACHINE) $(MACHINE_PREFIX) $(UBOOT_ITB_ARCH) \
		$(KERNEL_LOAD_ADDRESS) $(KERNEL_ENTRY_POINT) $(FDT_LOAD_ADDRESS) \
		$(KERNEL_VMLINUZ) $(IMAGEDIR)/$(MACHINE_PREFIX).dtb $(SYSROOT_CPIO_XZ) $@

$(UPDATER_ITB) : $(ITB_IMAGE)
	ln -sf $< $@

PHONY += image-bin
image-bin: $(IMAGE_BIN_STAMP)
$(IMAGE_BIN_STAMP): $(ITB_IMAGE) $(UBOOT_INSTALL_STAMP) $(SCRIPTDIR)/onie-mk-bin.sh
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE binary image ===="
	$(Q) $(SCRIPTDIR)/onie-mk-bin.sh $(MACHINE_PREFIX) $(IMAGEDIR) \
		$(MACHINEDIR) $(UBOOT_DIR) $(IMAGEDIR)/onie-$(MACHINE_PREFIX).bin
	$(Q) touch $@

ifndef MAKE_CLEAN
IMAGE_UPDATER_FILES = $(shell \
			test -d $(INSTALLER_DIR) && \
			find -L $(INSTALLER_DIR) -mindepth 1 -cnewer $(IMAGE_UPDATER_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(strip $(IMAGE_UPDATER_FILES)),)
    $(shell rm -f $(IMAGE_UPDATER_STAMP))
  endif
endif

PHONY += image-updater
image-updater: $(IMAGE_UPDATER_STAMP)
$(IMAGE_UPDATER_STAMP): $(UPDATER_IMAGE_PARTS_COMPLETE) $(UPDATER_IMAGE_PARTS_PLATFORM_COMPLETE) \
			$(SCRIPTDIR)/onie-mk-installer.sh
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE updater ===="
	$(Q) CONSOLE_SPEED=$(CONSOLE_SPEED) \
	     CONSOLE_DEV=$(CONSOLE_DEV) \
	     CONSOLE_PORT=$(CONSOLE_PORT) \
	     GRUB_TIMEOUT=$(GRUB_TIMEOUT) \
	     UPDATER_UBOOT_NAME=$(UPDATER_UBOOT_NAME) \
	     EXTRA_CMDLINE_LINUX="$(EXTRA_CMDLINE_LINUX)" \
	     SERIAL_CONSOLE_ENABLE=$(SERIAL_CONSOLE_ENABLE) \
	     UEFI_BOOT_LOADER=$(UEFI_BOOT_LOADER) \
	     GPG_SIGN_SECRING=$(GPG_SIGN_SECRING) \
	     SECURE_GRUB=$(SECURE_GRUB) \
	     fakeroot -- $(SCRIPTDIR)/onie-mk-installer.sh onie $(ROOTFS_ARCH) $(MACHINEDIR) \
		$(MACHINE_CONF) $(INSTALLER_DIR) \
		$(UPDATER_IMAGE) $(UPDATER_IMAGE_PARTS) $(UPDATER_IMAGE_PARTS_PLATFORM)
	$(Q) touch $@

PXE_EFI64_IMAGE		= $(IMAGEDIR)/onie-recovery-$(ARCH)-$(MACHINE_PREFIX).efi64.pxe
RECOVERY_ISO_IMAGE	= $(IMAGEDIR)/onie-recovery-$(ARCH)-$(MACHINE_PREFIX).iso

RECOVERY_CONF_DIR	= $(PROJECTDIR)/build-config/recovery
RECOVERY_DIR		= $(MBUILDDIR)/recovery
RECOVERY_SYSROOT	= $(RECOVERY_DIR)/sysroot
RECOVERY_CPIO		= $(RECOVERY_DIR)/initrd.cpio
RECOVERY_INITRD		= $(RECOVERY_DIR)/$(ARCH)-$(MACHINE_PREFIX).initrd
RECOVERY_ISO_SYSROOT	= $(RECOVERY_DIR)/iso-sysroot
RECOVERY_CORE_IMG	= $(RECOVERY_DIR)/core.img
RECOVERY_EMBEDDED_IMG	= $(RECOVERY_DIR)/embedded.img
RECOVERY_EFI_DIR	= $(RECOVERY_DIR)/efi
RECOVERY_EFI_BOOTX86_IMG= $(RECOVERY_EFI_DIR)/boot/bootx64.efi
RECOVERY_ELTORITO_IMG	= $(RECOVERY_ISO_SYSROOT)/boot/eltorito.img
RECOVERY_UEFI_IMG	= $(RECOVERY_ISO_SYSROOT)/boot/efi.img
PXE_EFI64_GRUB_MODS     = $(RECOVERY_DIR)/pxe-efi64-grub-modlist

RECOVERY_INITRD_STAMP	= $(STAMPDIR)/recovery-initrd
RECOVERY_ISO_STAMP	= $(STAMPDIR)/recovery-iso
PXE_EFI64_STAMP		= $(STAMPDIR)/pxe-efi64

# Default to rescue mode for Syslinux menu, if none specified in machine.make
RECOVERY_DEFAULT_ENTRY ?= rescue

# Map RECOVERY_DEFAULT_ENTRY to GRUB entry number
ifeq ($(RECOVERY_DEFAULT_ENTRY),rescue)
  GRUB_DEFAULT_ENTRY = 0
else
  ifeq ($(RECOVERY_DEFAULT_ENTRY),embed)
    GRUB_DEFAULT_ENTRY = 1
  else
    $(error Unknown RECOVERY_DEFAULT_ENTRY requested: $(RECOVERY_DEFAULT_ENTRY))
  endif
endif

PHONY += pxe-efi64 recovery-initrd recovery-iso

# Make an initrd based on the ONIE sysroot that also includes the ONIE
# updater image.
recovery-initrd: $(RECOVERY_INITRD_STAMP)
$(RECOVERY_INITRD_STAMP): $(IMAGE_UPDATER_STAMP)
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE Recovery initrd ===="
	$(Q) rm -rf $(RECOVERY_DIR)
	$(Q) mkdir -p $(RECOVERY_DIR)
	$(Q) cp -a $(SYSROOTDIR) $(RECOVERY_SYSROOT)
	$(Q) cp $(UPDATER_IMAGE) $(RECOVERY_SYSROOT)/lib/onie/onie-updater
	$(Q) fakeroot -- $(SCRIPTDIR)/make-sysroot.sh $(RECOVERY_SYSROOT) $(RECOVERY_CPIO)
	$(Q) xz --compress --force --check=crc32 --stdout -8 $(RECOVERY_CPIO) > $(RECOVERY_INITRD)
	$(Q) touch $@

# Make hybrid .iso image containing the ONIE kernel and recovery intrd
recovery-iso: $(RECOVERY_ISO_STAMP)
$(RECOVERY_ISO_STAMP): $(GRUB_INSTALL_STAMP) $(GRUB_HOST_INSTALL_STAMP) $(RECOVERY_INITRD_STAMP) \
			$(RECOVERY_CONF_DIR)/grub-iso.cfg
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE Recovery Hybrid iso ===="
	$(Q) Q=$(Q) CONSOLE_SPEED=$(CONSOLE_SPEED) \
	     CONSOLE_DEV=$(CONSOLE_DEV) \
	     CONSOLE_PORT=$(CONSOLE_PORT) \
	     GRUB_DEFAULT_ENTRY=$(GRUB_DEFAULT_ENTRY) \
	     UEFI_ENABLE=$(UEFI_ENABLE) \
	     EXTRA_CMDLINE_LINUX="$(EXTRA_CMDLINE_LINUX)" \
	     SERIAL_CONSOLE_ENABLE=$(SERIAL_CONSOLE_ENABLE) \
	     SECURE_BOOT_ENABLE=$(SECURE_BOOT_ENABLE) \
	     SB_SHIM=$(SHIM_SECURE_BOOT_IMAGE) \
	     ONIE_VENDOR_SECRET_KEY_PEM=$(ONIE_VENDOR_SECRET_KEY_PEM) \
	     ONIE_VENDOR_CERT_PEM=$(ONIE_VENDOR_CERT_PEM) \
	     $(SCRIPTDIR)/onie-mk-iso.sh $(ARCH) $(UPDATER_VMLINUZ) \
		$(RECOVERY_INITRD) $(RECOVERY_DIR) \
		$(MACHINE_CONF) $(RECOVERY_CONF_DIR) \
		$(GRUB_TARGET_LIB_I386_DIR) $(GRUB_HOST_BIN_I386_DIR) \
		$(GRUB_TARGET_LIB_UEFI_DIR) $(GRUB_HOST_BIN_UEFI_DIR) \
		$(FIRMWARE_TYPE) $(RECOVERY_ISO_IMAGE)
	$(Q) touch $@

# Convert the .iso to a PXE-EFI64 bootable image using GRUB
pxe-efi64: $(PXE_EFI64_STAMP)
$(PXE_EFI64_STAMP): $(RECOVERY_ISO_STAMP) $(RECOVERY_CONF_DIR)/grub-embed.cfg
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE PXE EFI64 Recovery Image ===="
	$(Q) cd $(GRUB_TARGET_LIB_UEFI_DIR) && \
		ls *.mod|sed -e 's/\.mod//g'|egrep -v '(ehci|at_keyboard)' > $(PXE_EFI64_GRUB_MODS)
	$(Q) $(GRUB_HOST_INSTALL_UEFI_DIR)/usr/bin/grub-mkimage --format=$(ARCH)-efi	\
	    --config=$(RECOVERY_CONF_DIR)/grub-embed.cfg			\
	    --directory=$(GRUB_TARGET_LIB_UEFI_DIR)	\
	    --output=$(PXE_EFI64_IMAGE) --memdisk=$(RECOVERY_ISO_IMAGE)		\
	    $$(cat $(PXE_EFI64_GRUB_MODS))
	$(Q) touch $@

# Allow machines to optionally define image post-processing
# instructions.  This makefile fragment can define rules for keeping
# $(MACHINE_IMAGE_COMPLETE_STAMP) up to date, referenced by the final
# $(IMAGE_COMPLETE_STAMP) target below.
-include $(MACHINEDIR)/post-process.make

PHONY += image-complete
image-complete: $(IMAGE_COMPLETE_STAMP)
$(IMAGE_COMPLETE_STAMP): $(PLATFORM_IMAGE_COMPLETE) $(MACHINE_IMAGE_COMPLETE_STAMP)
	$(Q) echo "Created: $(UPDATER_IMAGE)"
	$(Q) touch $@

MACHINE_CLEAN += image-clean
image-clean:
	$(Q) rm -f $(IMAGEDIR)/*$(MACHINE_PREFIX)* $(SYSROOT_CPIO_XZ) $(IMAGE_COMPLETE_STAMP) $(KERNEL_VMLINUZ_INSTALL_STAMP)
	$(Q) rm -rf $(RECOVERY_DIR) $(MACHINE_IMAGE_COMPLETE_STAMP) $(MACHINE_IMAGE_PRODUCTS)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
