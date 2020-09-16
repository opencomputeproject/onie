# WNC RSEB-W1-32

# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
VENDOR_VERSION = .0.1.1

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
# WNC IANA number
VENDOR_ID = 15756

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# Console parameters
CONSOLE_SPEED = 115200
CONSOLE_DEV = 0
UEFI_ENABLE = yes

# Specify Linux kernel version -- comment out to use the default
LINUX_VERSION = 4.9
LINUX_MINOR_VERSION = 95

EXTRA_CMDLINE_LINUX = acpi_osi=Linux


# Older GCC required for older 3.14.27 kernel
GCC_VERSION = 4.9.2
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
