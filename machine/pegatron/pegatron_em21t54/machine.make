# Pegatron EM21T54

ONIE_ARCH ?= armv8a
SWITCH_ASIC_VENDOR = mvl

VENDOR_REV ?= 0

MACHINE_REV = 0

#set XTOOLS_ENABLE = "no" while using spesific cross-compiler (CROSSBIN)
#XTOOLS_ENABLE = no

ifeq ($(XTOOLS_ENABLE),no)
  TARGET = aarch64-marvell-linux-gnu
  CROSSBIN = /opt/toolchains/mvl/armv8/ac5/bin
  GCC_VERSION = 7.3.0
  XTOOLS_LIBC_VERSION = 2.27
  XTOOLS_BUILD_STAMP = $(CROSSBIN)/$(TARGET)-gcc
  STRACE_ENABLE = no
endif

# Set the desired U-Boot version
UBOOT_VERSION = 2018.03

#enable u-boot dtb
UBOOT_DTB_ENABLE = yes

UBOOT_MACHINE = mvebu_db_armada8k

KERNEL_DTB = marvell/orion.dtb
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)
KERNEL_LOAD_ADDRESS = "0x2 0x2080000"
KERNEL_ENTRY_POINT  = "0x2 0x2080000"
FDT_LOAD_ADDRESS = "0x2 0x1000000"

LINUX_VERSION = 4.19
LINUX_MINOR_VERSION = 143

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
# VENDOR_VERSION =

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 32022

UPDATER_IMAGE_PARTS_PLATFORM = $(IMAGEDIR)/$(MACHINE_PREFIX).initrd

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
