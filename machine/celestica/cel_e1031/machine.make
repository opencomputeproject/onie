# Celestica E1031(Haliburton)
# CPU Module: Intel Atom Rangeley (C2000)

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
VENDOR_VERSION = .0.0.4

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 12244
# Add the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

PARTED_ENABLE = yes

PARTITION_TYPE = gpt

# Console parameters
CONSOLE_DEV = 1
CONSOLE_FLAG = 1

# Set Linux kernel version
LINUX_VERSION           = 3.2
LINUX_MINOR_VERSION     = 69

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
