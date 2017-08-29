# Interface Masters Niagara 29XX Series

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= ONIE

UPDATER_IMAGE_PARTS_PLATFORM = $(MACHINEDIR)/rootconf/sysroot-lib-onie/onie-blkdev-common

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),ONIE)
    MACHINE_REV = 0
else
    $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
    $(error Unknown VENDOR_REV)
endif

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Interface Masters IANA number
VENDOR_ID = 30324

# Skip the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = no

# Default to msdos disk label for this platform
PARTITION_TYPE = msdos

# Set Linux kernel version
LINUX_VERSION       = 4.1
LINUX_MINOR_VERSION = 38

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
