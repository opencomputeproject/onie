# Alpha Networks SNH60A0-320F

ONIE_ARCH ?= x86_64

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = .0.1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Alpha Networks Inc.
VENDOR_ID = 31874

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes

# Console parameters
CONSOLE_DEV = 1

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

LINUX_VERSION		= 3.14
LINUX_MINOR_VERSION	= 27

# Specify uClibc version
UCLIBC_VERSION = 0.9.32.1

