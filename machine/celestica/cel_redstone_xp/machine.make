# KVM x86_64 Virtual Machin

ONIE_ARCH ?= x86_64

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
# Open Compute Project IANA number
VENDOR_ID = 12244
# Add the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes

PARTED_ENABLE = yes

PARTITION_TYPE = gpt
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
