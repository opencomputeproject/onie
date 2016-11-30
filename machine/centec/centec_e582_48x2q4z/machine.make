# CENTEC E582-48X2Q4Z 

# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
# VENDOR_VERSION = .00.01

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = centec

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
# CENTEC IANA number
VENDOR_ID = 27975 

I2CTOOLS_SYSEEPROM = no

# Enable UEFI support
UEFI_ENABLE = yes

# This platform requires the PXE_EFI64 installer
PXE_EFI64_ENABLE = yes

# Set Linux kernel version
#LINUX_VERSION		= 3.2
#LINUX_MINOR_VERSION	= 69

EXTRA_CMDLINE_LINUX = nopat acpi_enforce_resources=no

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
