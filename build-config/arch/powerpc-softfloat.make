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
KERNEL_INSTALL_DEPS	+= kernel-dtb-install

# This architecture requires U-Boot
UBOOT_ENABLE = yes

PLATFORM_IMAGE_COMPLETE = $(IMAGE_BIN_STAMP) $(IMAGE_UPDATER_STAMP)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

