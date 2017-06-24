# This file is derived from https://github.com/opencomputeproject/onie/blob/master/build-config/arch/armv7a/armv7a.make
#-------------------------------------------------------------------------------
#
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#  Copyright (C) 2016 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#  ARM v8 Softfloat Architecture and Toolchain Setup
#

ARCH        ?= arm64
TARGET	    ?= aarch64-onie-linux-gnueabi
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH		= arm64
KERNEL_LOAD_ADDRESS     ?= 0x80080000
KERNEL_ENTRY_POINT      ?= 0x80080000
FDT_LOAD_ADDRESS	?= no
KERNEL_DTB		?= $(MACHINE).dtb
KERNEL_DTB_PATH		?= $(KERNEL_DTB)
KERNEL_IMAGE_FILE	= $(LINUX_BOOTDIR)/Image.gz
KERNEL_INSTALL_DEPS	+= $(KERNEL_VMLINUZ_INSTALL_STAMP) $(KERNEL_DTB_INSTALL_STAMP)

#Toolchain Options
XTOOLS_LIBC ?= glibc
XTOOLS_LIBC_VERSION ?= 2.25

STRACE_ENABLE ?= yes

# Enable u-boot support by default. a machine make file can override this
 UBOOT_ENABLE ?= yes
 UBOOT_ITB_ARCH = $(KERNEL_ARCH)

# Disable Grub support by default. a machine make file can override this
GRUB_ENABLE ?= no
GRUB_IMAGE_NAME = grubaa64.efi

# Disable UEFI support by default. a machine make file can override this
UEFI_ENABLE ?= no
ifeq ($(UEFI_ENABLE),yes)
  # Set the target firmware type.  Possible values are "uefi"
  FIRMWARE_TYPE = uefi
endif

ifeq ($(UEFI_ENABLE),yes)
  PLATFORM_IMAGE_COMPLETE = $(IMAGE_UPDATER_STAMP) $(RECOVERY_ISO_STAMP)
else
  PLATFORM_IMAGE_COMPLETE = $(IMAGE_BIN_STAMP) $(IMAGE_UPDATER_STAMP)
endif

PXE_EFI64_ENABLE ?= no

ifeq ($(PXE_EFI64_ENABLE),yes)
  PLATFORM_IMAGE_COMPLETE += $(PXE_EFI64_STAMP)
endif

ifeq ($(UEFI_ENABLE),yes)
  UPDATER_IMAGE_PARTS = $(UPDATER_VMLINUZ) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS) \
			$(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/onie-blkdev-common
  UPDATER_IMAGE_PARTS_COMPLETE = $(KERNEL_INSTALL_STAMP) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS)
else
  UPDATER_IMAGE_PARTS = $(UPDATER_ITB) $(UPDATER_UBOOT)
  UPDATER_IMAGE_PARTS_COMPLETE = $(UPDATER_ITB) $(UBOOT_INSTALL_STAMP)
endif

DEMO_IMAGE_PARTS = $(DEMO_KERNEL_VMLINUZ) $(DEMO_SYSROOT_CPIO_XZ)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_KERNEL_COMPLETE_STAMP) $(DEMO_SYSROOT_CPIO_XZ)
DEMO_ARCH_BINS = $(DEMO_OS_BIN) $(DEMO_DIAG_BIN)

# Include MTD utilities
MTDUTILS_ENABLE ?= yes

# Default to GPT on ARM.  A particular machine.make can override this.
PARTITION_TYPE ?= gpt

# Include the GPT partitioning tools
GPT_ENABLE = yes

# gptfdisk requires C++
REQUIRE_CXX_LIBS = yes

# Include the GNU parted partitioning tools
PARTED_ENABLE = yes

# Include ext3/4 file system tools
EXT3_4_ENABLE = yes

# Default to include the i2ctools.  A particular machine.make can
# override this.
I2CTOOLS_ENABLE ?= yes

# Include lvm2 tools (needed for parted)
LVM2_ENABLE = yes
# Currently armv8a requires a special version of lvm2
LVM2_VERSION ?= 2_02_155

# Include ethtool by default
ETHTOOL_ENABLE ?= yes

# Include kexec-tools
KEXEC_ENABLE = yes

# Update this if the configuration mechanism changes from one release
# to the next.
ONIE_CONFIG_VERSION = 1

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

