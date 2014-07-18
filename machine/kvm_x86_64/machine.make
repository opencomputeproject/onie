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

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
# VENDOR_VERSION = .12.34

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 42623

# Skip the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = no

# Set the desired kernel version.
LINUX_VERSION		= 3.14
LINUX_MINOR_VERSION	= 16

# Set the desired uClibc version
UCLIBC_VERSION = 0.9.33.2

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

#
# Console unit and speed can be overwrite here.
# For example,
# 
# CONSOLE_SPEED = 9600
# CONSOLE_UNIT = 0
# CONSOLE_FLAG = 0
# CONSOLE_PORT = 0x3f8
