# Delta AG9032V2A Series
# CPU Module: Intel Atom Rangeley

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

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = onie_version_1.00.00

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# AGEMA IANA number
VENDOR_ID = 2254

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes
IPMITOOL_ENABLE = yes

# This platform requires the PXE_EFI64 installer
PXE_EFI64_ENABLE = no

# Console parameters
CONSOLE_DEV = 0

# Set Linux kernel version
LINUX_VERSION		= 4.1
LINUX_MINOR_VERSION	= 38

UEFI_ENABLE = yes

CONSOLE_SPEED = 115200

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
