#-------------------------------------------------------------------------------
#
#  Copyright 2016 Freescale Semiconductor, Inc.
#
#  SPDX-License-Identifier:     GPL-2.0
#
#  ARM v8 Softfloat Architecture and Toolchain Setup
#

ARCH        ?= arm64
TARGET	    ?= aarch64-unknown-linux-gnueabi
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH		= arm64
KERNEL_DTB		?= $(MACHINE).dtb
KERNEL_DTB_PATH		?= $(KERNEL_DTB)
KERNEL_IMAGE_FILE	= $(LINUX_BOOTDIR)/Image.gz
KERNEL_INSTALL_DEPS	+= $(KERNEL_VMLINUZ_INSTALL_STAMP) $(KERNEL_DTB_INSTALL_STAMP)

#Toolchain Options
CROSSTOOL_NG_VERSION ?= 1.22.1#Dummy version greater than current 1.22.0
XTOOLS_CONFIG ?= $(ARCHDIR)/crosstool.armv8a.config
GCC_VERSION ?= 5.3.0
XTOOLS_LIBC ?= glibc
XTOOLS_LIBC_VERSION ?= 2.23

# This architecture requires U-Boot
UBOOT_ENABLE = yes
UBOOT_ITB_ARCH = $(KERNEL_ARCH)

PLATFORM_IMAGE_COMPLETE = $(IMAGE_BIN_STAMP) $(IMAGE_UPDATER_STAMP)
UPDATER_IMAGE_PARTS = $(UPDATER_ITB) $(UPDATER_UBOOT)
UPDATER_IMAGE_PARTS_COMPLETE = $(UPDATER_ITB) $(UBOOT_INSTALL_STAMP)

DEMO_IMAGE_PARTS = $(DEMO_UIMAGE)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_UIMAGE_COMPLETE_STAMP)
DEMO_ARCH_BINS = $(DEMO_OS_BIN)

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

