# Makefile fragment for Accton 4654

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
VENDOR_ID = 259

ACC_ONIE_REV	?= 5
ACC_UBOOT_REV	?= 3.0.1.7

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
