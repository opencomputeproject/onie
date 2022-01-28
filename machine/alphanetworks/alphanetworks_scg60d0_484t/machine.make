# Alpha Networks SCG60D0-484T

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= 1

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else ifeq ($(VENDOR_REV),1)
  MACHINE_REV = 1
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

# Enable the ipmitool for this platform
IPMITOOL_ENABLE = yes

# Console parameters
CONSOLE_DEV = 1

# Enable UEFI support
UEFI_ENABLE = yes

# Set Linux kernel version
LINUX_VERSION = 4.9
LINUX_MINOR_VERSION = 95

# Set GCC version
GCC_VERSION = 8.3.0

# Set uClibc-ng version
XTOOLS_LIBC_VERSION = 1.0.38

include $(MACHINEDIR)/rootconf/grub-machine.make

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

