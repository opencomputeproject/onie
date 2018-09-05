# DELLEMCEMC S5100 Series
# CPU Module: Intel Atom Rangeley (C2538)

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = cavium

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
# DELLEMCEMC IANA number
VENDOR_ID = 674

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

CONSOLE_SPEED = 115200
CONSOLE_DEV = 1
CONSOLE_FLAG = 0

EXTRA_CMDLINE_LINUX = i2c-ismt.bus_speed=100

# Set Linux kernel version
LINUX_VERSION		= 4.9
LINUX_MINOR_VERSION	= 95

# Enable UEFI support
UEFI_ENABLE = yes

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
