#-------------------------------------------------------------------------------
#
#  PowerPC Softfloat Architecture and Toolchain Setup
#

ARCH        ?= powerpc
TARGET	    ?= $(ARCH)-onie-linux-uclibc
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH		= powerpc
KERNEL_DTB		?= $(MACHINE).dtb
KERNEL_INSTALL_DEPS	+= $(KERNEL_DTB_INSTALL_STAMP)

# This architecture requires U-Boot
UBOOT_ENABLE = yes

PLATFORM_IMAGE_COMPLETE = $(IMAGE_BIN_STAMP) $(IMAGE_UPDATER_STAMP)
DEMO_IMAGE_PARTS = $(DEMO_UIMAGE)
DEMO_IMAGE_PARTS_COMPLETE = $(DEMO_UIMAGE_COMPLETE_STAMP)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

