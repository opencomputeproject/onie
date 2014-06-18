# Accton AS5712_54X

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
VENDOR_ID = 259

I2CTOOLS_ENABLE = yes


ACCTON_REV ?= 0.1

ifdef ACCTON_REV
ACCTON_VERSION = $(shell echo $(LSB_RELEASE_TAG) | cut -c3- | sed -e 's/\.0/\./g').$(ACCTON_REV)
endif

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
