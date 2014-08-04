# Makefile fragment for Accton AS5600_52X

ONIE_ARCH ?= powerpc-softfloat

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

EXT3_4_ENABLE = no
MTDUTILS_ENABLE = no

UBOOT_MACHINE = AS5600_52X
KERNEL_DTB = as5600_52x.dtb

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Accton Technology Corporation IANA number
VENDOR_ID = 259

VENDOR_VERSION = .00.03
UBOOT_INDENT_STRING = 3.0.4.6

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
