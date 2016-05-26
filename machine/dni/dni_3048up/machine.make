# Makefile fragment for DNI 3048UP

# Vendor's version number can be defined here.
# Available variables are 'VENDOR_VERSION' and 'UBOOT_IDENT_STRING'.
# e.g.,
VENDOR_VERSION = -DNI_1.0.5
UBOOT_VERNOR_VERSION = 3048UP V1.0.6
UBOOT_IDENT_STRING = ONIE $(ONIE_RELEASE_TAG) - $(UBOOT_VERNOR_VERSION)

ONIE_ARCH ?= armv7a

VENDOR_REV ?= 1

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),1)
  MACHINE_REV = 1
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = dni_34xx_spi

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 5324

# Specify Linux kernel version
LINUX_VERSION       = 3.2
LINUX_MINOR_VERSION = 69

# Set the desired uClibc version
UCLIBC_VERSION = 0.9.33.2

# Set the desired U-Boot version
UBOOT_VERSION = 2012.10

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
