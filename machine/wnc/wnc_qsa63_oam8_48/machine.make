# Makefile fragment for WNC Tomcat

VENDOR_VERSION = -V001
ONIE_ARCH ?= armv8a
SWITCH_ASIC_VENDOR = mvl

VENDOR_REV ?= 0

MACHINE_REV = 0

# By default do not enable building firmware updates 
FIRMWARE_UPDATE_ENABLE = yes

UBOOT_ENABLE ?= yes

UBOOT_MACHINE = tomcat_alleycat5

KERNEL_DTB = marvell/ac5_rd.dtb
KERNEL_DTB_PATH = dts/$(KERNEL_DTB)

FDT_LOAD_ADDRESS = "0x2 0x01000000"

KERNEL_ENTRY_POINT  = "0x2 0x02080000"
KERNEL_LOAD_ADDRESS = "0x2 0x02080000"

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 15756

# Include kexec-tools
KEXEC_ENABLE = yes

#enable u-boot dtb
UBOOT_DTB_ENABLE = yes

# Set the desired U-Boot version
UBOOT_VERSION = 2018.03

# Default to msdos disk label for this platform
PARTITION_TYPE = msdos

# Specify Linux kernel version -- comment out to use the default
LINUX_VERSION = 4.14
LINUX_MINOR_VERSION = 76

include $(MACHINEDIR)/demo/demo_machine.make

#
# Local Variables:
# mode: makefile-gmake
# End:
