# Plexxi

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

# Plexxi IANA number
VENDOR_ID = 37341

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

PARTED_ENABLE = yes
PARTITION_TYPE = gpt

PXE_EFI64_ENABLE=yes

LINUX_VERSION           = 3.14
LINUX_MINOR_VERSION     = 27

# Older GCC required for older 3.14.27 kernel
GCC_VERSION = 4.9.2

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

