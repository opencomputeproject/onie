# stordis_bf6064x_t

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bft

VENDOR_REV ?= 0
PRODUCT_NAME = stordis_bf6064x_t-onie


# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = 190225

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 5324

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes
IPMITOOL_ENABLE = yes
SKIP_ETHMGMT_MACS = yes

# Set Linux kernel version
LINUX_VERSION		= 4.9
LINUX_MINOR_VERSION	= 95

# Specify uClibc version
#UCLIBC_VERSION = 0.9.32.1

UEFI_ENABLE = no

CONSOLE_SPEED = 115200
CONSOLE_DEV = 0

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
