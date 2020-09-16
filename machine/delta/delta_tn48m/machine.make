# Makefile fragment for Delta TN48M

VENDOR_VERSION = -V03
ONIE_ARCH ?= armv8a
SWITCH_ASIC_VENDOR = mvl

VENDOR_REV ?= 0

MACHINE_REV = 0

UBOOT_ENABLE ?= yes

UBOOT_MACHINE = mvebu_db_armada8k

KERNEL_DTB = marvell/armada-7040-db.dtb
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)

FDT_LOAD_ADDRESS = 0x10000000

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 5324

# Include kexec-tools
KEXEC_ENABLE = yes

#enable u-boot dtb
UBOOT_DTB_ENABLE = yes

# Set the desired U-Boot version
UBOOT_VERSION = 2018.03

# Default to msdos disk label for this platform
PARTITION_TYPE = msdos

# Specify Linux kernel version -- comment out to use the default
LINUX_VERSION = 4.9
LINUX_MINOR_VERSION = 95

#---------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
