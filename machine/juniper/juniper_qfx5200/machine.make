# Juniper Networks QFX5200 

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
VENDOR_VERSION = .0.1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Juniper Networks Inc.
VENDOR_ID = 2636

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# Console parameters
CONSOLE_DEV = 0

# Enable UEFI support
UEFI_ENABLE = yes

# Set Linux kernel version
LINUX_VERSION		= 4.9
LINUX_MINOR_VERSION	= 95

# ONIE defaults the serial console baud rate to 115200
CONSOLE_SPEED = 9600

# Older GCC required for older 3.14.27 kernel
GCC_VERSION = 4.9.2

RECOVERY_DEFAULT_ENTRY = embed

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

