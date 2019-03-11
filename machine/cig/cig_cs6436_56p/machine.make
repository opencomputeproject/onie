# CIG CS6436_56P

ONIE_ARCH ?= x86_64

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The SWITCH_ASIC_VENDOR is used to further differentiate the platform
# in the ONIE waterfall.  This string should be the stock ticker
# symbol of the ASIC vendor, in lower case.  The value in this example
# here is completely fictitious.
SWITCH_ASIC_VENDOR = nephos 

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = .0.1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Cambridge Industries Group (CIG)
VENDOR_ID = 40829

# Skip the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes

# The onie-syseeprom command in i2ctools is deprecated.  It is recommended to
# use the one implemented in busybox instead.  The option intends to provide a
# quick way to turn off the feature in i2ctools.  The command will be removed
# from i2ctools in the future once all machines migrate their support of
# sys_eeprom to busybox.
#
# The option is significant when I2CTOOLS_ENABLE is 'yes'
#
#I2CTOOLS_SYSEEPROM = no

# Enable UEFI support
UEFI_ENABLE = yes

#
# Console parameters can be defined here (default values are in
# build-config/arch/x86_64.make).
# For example,
# 
#CONSOLE_SPEED = 115200
CONSOLE_DEV = 2
# SERIAL_CONSOLE_ENABLE = no

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

