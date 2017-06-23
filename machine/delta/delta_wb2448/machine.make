# Delta Electronics, Inc.
# CPU Module: Intel Atom BayTrail

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
# Delta Electronics, Inc. IANA number
VENDOR_ID = 2254 

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# This platform requires the PXE_EFI64 installer
PXE_EFI64_ENABLE = yes


# Console parameters
CONSOLE_DEV = 0

#UEFI_ENABLE = yes

# Specify Linux kernel version -- comment out to use the default
LINUX_VERSION = 4.1
LINUX_MINOR_VERSION = 38

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
