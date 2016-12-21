#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2015,2016 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Stephen Su <sustephen@juniper.net>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#  x86 Architecture and Toolchain Setup
#

ARCH        ?= x86_64
TARGET      ?= $(ARCH)-onie-linux-uclibc
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

#
# Console parameters
#
# These are passed to grub, the ONIE Linux kernel, and the demo OS
# grub and kernel (in other words, everything that uses the console).
# The default values are defined here.  They can be overridden by the
# platform's machine.make.
#
# CONSOLE_DEV is 0 or 1, corresponding to Linux /dev/ttyS[01].
# They always map to serial devices at 0x3f8 and 0x2f8, respectively,
# without any BIOS shenanigans.
#
# CONSOLE_PORT is the serial device IO port address.  It is derived
# from CONSOLE_DEV.  So there's no need to define it unless
# you have a weird platform or you're just a nudnik.
#
# CONSOLE_SPEED is what you think it is.  We really like it fast
# because this is the 21st century.
#
CONSOLE_SPEED ?= 115200
CONSOLE_DEV ?= 0
ifndef CONSOLE_PORT
  ifeq ($(CONSOLE_DEV), 0)
    CONSOLE_PORT = 0x3f8
  else ifeq ($(CONSOLE_DEV), 1)
    CONSOLE_PORT = 0x2f8
  else
    $(error unknown CONSOLE_DEV value $(CONSOLE_DEV))
  endif
endif

KERNEL_ARCH		= x86
KERNEL_IMAGE_FILE	= $(LINUX_BOOTDIR)/bzImage
KERNEL_INSTALL_DEPS	+= $(KERNEL_VMLINUZ_INSTALL_STAMP)

CLIB64 = 64

PLATFORM_IMAGE_COMPLETE = $(IMAGE_UPDATER_STAMP) $(RECOVERY_ISO_STAMP)

# Disable UEFI support by default
UEFI_ENABLE ?= no
ifeq ($(UEFI_ENABLE),yes)
  # Set the target firmware type.  Possible values are "auto", "uefi"
  # and "bios":
  #  - auto -- auto-detect the firmware type at runtime, either 'uefi' or 'bios'
  #  - uefi -- UEFI firmware mode
  #  - bios -- legacy BIOS mode
  #
  # If firmware type is set to "bios" on a UEFI system, the ONIE
  # installer uses the legacy GRUB MBR method.  The system will *not*
  # have a ESP and UEFI will need to use CSM.
  #
  # Explicitly setting "bios" is intended for older ONIE systems that
  # were UEFI capable, but since ONIE did not support UEFI at the time
  # were treated as legacy BIOS.  This option allows those systems to
  # continue to use the legacy BIOS method.
  #
  # If firmware type is set to "uefi" on a BIOS system, the ONIE
  # installer will fail at runtime.
  FIRMWARE_TYPE ?= auto
else
  # Without UEFI support force legacy BIOS firmware
  FIRMWARE_TYPE ?= bios
endif

PXE_EFI64_ENABLE ?= no

ifeq ($(PXE_EFI64_ENABLE),yes)
  PLATFORM_IMAGE_COMPLETE += $(PXE_EFI64_STAMP)
endif

UPDATER_IMAGE_PARTS = $(UPDATER_VMLINUZ) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS) \
			$(ROOTCONFDIR)/grub-arch/sysroot-lib-onie/onie-blkdev-common

UPDATER_IMAGE_PARTS_COMPLETE = $(KERNEL_INSTALL_STAMP) $(UPDATER_INITRD) $(UPDATER_ONIE_TOOLS)

DEMO_IMAGE_PARTS = $(DEMO_KERNEL_VMLINUZ) $(DEMO_SYSROOT_CPIO_XZ)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_KERNEL_COMPLETE_STAMP) $(DEMO_SYSROOT_CPIO_XZ)
DEMO_ARCH_BINS = $(DEMO_OS_BIN) $(DEMO_DIAG_BIN)

# Include MTD utilities
MTDUTILS_ENABLE ?= yes

# Default to GPT on x86.  A particular machine.make can override this,
# though it is required for UEFI.
PARTITION_TYPE ?= gpt

# Include the GPT partitioning tools
GPT_ENABLE = yes

# gptfdisk requires C++
REQUIRE_CXX_LIBS = yes

# Include the GNU parted partitioning tools
PARTED_ENABLE = yes

# Include ext3/4 file system tools
EXT3_4_ENABLE = yes

# Include btrfs file system tools
BTRFS_PROGS_ENABLE = yes

# Include GRUB tools
GRUB_ENABLE = yes
GRUB_IMAGE_NAME = grubx64.efi

# Default to include the i2ctools.  A particular machine.make can
# override this.
I2CTOOLS_ENABLE ?= yes

# The onie-syseeprom in i2ctools is deprecated from now on.
# It is recommended to migrate the support from i2ctools to busybox.
# To compatible with current design, the feature is still enabled by default.
I2CTOOLS_SYSEEPROM ?= yes

# Include dmidecode tools
DMIDECODE_ENABLE = yes

# Include lvm2 tools
LVM2_ENABLE = yes

# Include ethtool by default
ETHTOOL_ENABLE ?= yes

# Include dosfstools
DOSFSTOOLS_ENABLE = yes

# Include kexec-tools
KEXEC_ENABLE = yes

# Include flashrom
FLASHROM_ENABLE = yes

# Include ipmitool
IPMITOOL_ENABLE ?= no

# Enable serial console support
SERIAL_CONSOLE_ENABLE ?= yes

# Update this if the GRUB configuration mechanism changes from one
# release to the next.
ONIE_CONFIG_VERSION = 1

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
