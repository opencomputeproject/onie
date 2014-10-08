# Makefile fragment for Alpha Networks SNX6070-486F

ONIE_ARCH ?= powerpc-softfloat

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = SNX6070_486F
KERNEL_DTB = snx6070_486f.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 31874

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
