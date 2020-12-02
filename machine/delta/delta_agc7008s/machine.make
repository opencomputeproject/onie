# Delta agc7008s

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= 0


# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The VENDOR_VERSION string is appended to the overall ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = onie_version_1.1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 2254

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes


# Set Linux kernel version
LINUX_VERSION		= 4.9
LINUX_MINOR_VERSION	= 95

# Specify uClibc version
#UCLIBC_VERSION = 0.9.32.1

UEFI_ENABLE = yes

FIRMWARE_UPDATE_ENABLE = yes

IPMITOOL_ENABLE = yes
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
