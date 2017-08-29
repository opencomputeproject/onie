# DELL S6000 Series
# CPU Module: Intel Atom Centerton (S1220)

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

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# DELL IANA number
VENDOR_ID = 674

# This platform requires the PXE_EFI64 installer
PXE_EFI64_ENABLE = yes

# Set Linux kernel version
LINUX_VERSION		= 3.2
LINUX_MINOR_VERSION	= 69

# Older GCC required for older 3.2 kernel
GCC_VERSION = 4.9.2

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = yes

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
