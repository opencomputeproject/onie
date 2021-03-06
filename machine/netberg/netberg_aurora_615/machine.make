# Netberg Aurora 615

# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
# VENDOR_VERSION = .00.01


ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = none

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

UEFI_ENABLE = yes
#PXE_EFI64_ENABLE = yes

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# Console parameters
CONSOLE_DEV = 0
CONSOLE_SPEED ?= 115200

# Set Linux kernel version
#LINUX_VERSION		= 4.1
#LINUX_MINOR_VERSION = 38
LINUX_VERSION		= 4.9
LINUX_MINOR_VERSION	= 95
GCC_VERSION = 4.9.2
#EXTRA_CMDLINE_LINUX = acpi_osi=Linux
#GCC_VERSION = 4.9.2
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
