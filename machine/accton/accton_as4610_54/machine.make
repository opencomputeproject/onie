# Makefile fragment for Accton AS4610_54

ONIE_ARCH ?= armv7a

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

UBOOT_MACHINE = AS4610_54

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = .2.5.4

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
VENDOR_ID = 259

# Specify Linux kernel version
LINUX_VERSION       = 3.2
LINUX_MINOR_VERSION = 69

# Set the desired uClibc version
UCLIBC_VERSION = 0.9.33.2

#-------------------------------------------------------------------------------
#
# Local Variables:
UBOOT_VERSION = 2012.10
# mode: makefile-gmake
# End:
