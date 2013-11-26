#-------------------------------------------------------------------------------
#
#  PowerPC Softfloat Architecture and Toolchain Setup
#

ARCH        ?= powerpc
TARGET	    ?= $(ARCH)-onie-linux-uclibc
CROSSPREFIX ?= $(TARGET)-
CROSSBIN    ?= $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin

KERNEL_ARCH = powerpc
KERNEL_NEEDS_DTB = yes

# This architecture requires U-Boot
UBOOT_ENABLE = yes

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

