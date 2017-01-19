#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 david_yang <david_yang@accton.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#  ARM v7a Softfloat Architecture and Toolchain Setup
#

ARCH        ?= arm
TARGET	    ?= $(ARCH)-onie-linux-uclibcgnueabi
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH		= arm
KERNEL_LOAD_ADDRESS	?= 0x60008000
KERNEL_ENTRY_POINT	?= 0x60008000
FDT_LOAD_ADDRESS        ?= no
KERNEL_DTB		?= $(MACHINE).dtb
KERNEL_DTB_PATH		?= $(KERNEL_DTB)
KERNEL_IMAGE_FILE	= $(LINUX_BOOTDIR)/compressed/piggy.gzip
KERNEL_INSTALL_DEPS	+= $(KERNEL_VMLINUZ_INSTALL_STAMP) $(KERNEL_DTB_INSTALL_STAMP)

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

# Include btrfs file system tools
BTRFS_PROGS_ENABLE = yes

# Default to include the i2ctools.  A particular machine.make can
# override this.
I2CTOOLS_ENABLE ?= yes

# Include lvm2 tools
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

