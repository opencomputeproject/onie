# Alpha Networks SNK60I0-320F

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
VENDOR_VERSION = .alpha-0.2

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Alpha Networks Inc.
VENDOR_ID = 31874

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes

# Enable the ipmitool for this platform
IPMITOOL_ENABLE = yes

# Skip programming the Ethernet management interface MAC addresses by ONIE
SKIP_ETHMGMT_MACS = yes

# Console parameters
CONSOLE_DEV = 0

# Enable UEFI support
UEFI_ENABLE = yes



# Set uClibc-ng version

include $(MACHINEDIR)/rootconf/grub-machine.make

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

