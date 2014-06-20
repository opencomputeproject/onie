# Makefile fragment for Accton as5600_52x

VENDOR_REV ?= r01a

# Translate Accton hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),r01a)
  MACHINE_REV = 0
else ifeq ($(VENDOR_REV),r01d)
  # This machine has new SDRAM and a different oscillator
  MACHINE_REV = 1
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 259

ACC_ONIE_REV	?= 3
ACC_UBOOT_REV	?= 3.0.4.6

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
