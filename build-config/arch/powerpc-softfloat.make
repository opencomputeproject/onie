#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014,2016 david_yang <david_yang@accton.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#  PowerPC Softfloat Architecture and Toolchain Setup
#

ARCH        ?= powerpc
TARGET	    ?= $(ARCH)-onie-linux-uclibc
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH		= powerpc
KERNEL_LOAD_ADDRESS	?= 0x00000000
KERNEL_ENTRY_POINT	?= 0x00000000
FDT_LOAD_ADDRESS        ?= no
KERNEL_DTB		?= $(MACHINE).dtb
KERNEL_DTB_PATH		?= $(KERNEL_DTB)
KERNEL_IMAGE_FILE	= $(LINUXDIR)/vmlinux.bin.gz
KERNEL_INSTALL_DEPS	+= $(KERNEL_VMLINUZ_INSTALL_STAMP) $(KERNEL_DTB_INSTALL_STAMP)

# This architecture requires U-Boot
UBOOT_ENABLE = yes
UBOOT_ITB_ARCH = ppc

# Include MTD utilities
MTDUTILS_ENABLE ?= yes

# Include ext3/4 file system tools - also required for BTRFS
EXT3_4_ENABLE ?= yes

# Include btrfs file system tools
BTRFS_PROGS_ENABLE ?= yes

PLATFORM_IMAGE_COMPLETE = $(IMAGE_BIN_STAMP) $(IMAGE_UPDATER_STAMP)
UPDATER_IMAGE_PARTS = $(UPDATER_ITB) $(UPDATER_UBOOT)
UPDATER_IMAGE_PARTS_COMPLETE = $(UPDATER_ITB) $(UBOOT_INSTALL_STAMP)

DEMO_IMAGE_PARTS = $(DEMO_UIMAGE)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_UIMAGE_COMPLETE_STAMP)
DEMO_ARCH_BINS = $(DEMO_OS_BIN)

ONIE_CONFIG_VERSION = 0

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

