# Quanta Common Rangeley CPU board

ONIE_ARCH ?= x86_64

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# DELL IANA number
VENDOR_ID = 7244

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# This platform requires the PXE_EFI64 installer
PXE_EFI64_ENABLE = no

CONSOLE_SPEED = 115200
CONSOLE_DEV = 1
CONSOLE_FLAG = 0

EXTRA_CMDLINE_LINUX = i2c-ismt.bus_speed=100

# Set Linux kernel version
LINUX_VERSION		= 3.2
LINUX_MINOR_VERSION	= 69

# Specify uClibc version
UCLIBC_VERSION = 0.9.32.1

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
