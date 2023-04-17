# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
# VENDOR_VERSION = .00.01


ONIE_ARCH = x86_64
SWITCH_ASIC_VENDOR = bft

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 50424

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# Console parameters
CONSOLE_SPEED = 115200
CONSOLE_DEV = 0
CONSOLE_FLAG = 0

# Enable UEFI support
UEFI_ENABLE = yes
RECOVERY_DEFAULT_ENTRY = embed

# Set Linux kernel version
LINUX_VERSION = 4.9
LINUX_MINOR_VERSION = 95

GCC_VERSION = 8.3.0

# Set uClibc-ng version
XTOOLS_LIBC_VERSION = 1.0.35

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
