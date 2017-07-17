# Netberg Rangeley P1330 CPU board

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bcm

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
# Netberg IANA number
VENDOR_ID = 47294

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

CONSOLE_SPEED = 115200
CONSOLE_DEV = 1

# Recovery ISO default entry set to embed for factory production
RECOVERY_DEFAULT_ENTRY=embed

# Set Linux kernel version
LINUX_VERSION		= 3.2
LINUX_MINOR_VERSION	= 69

# Older GCC required for older 3.2 kernel
GCC_VERSION = 4.9.2

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
