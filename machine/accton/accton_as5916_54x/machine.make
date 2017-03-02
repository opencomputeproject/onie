# Accton AS5916_54X

# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
# VENDOR_VERSION = .00.01

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

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Accton Technology Corporation IANA number
VENDOR_ID = 259

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

MACHINE_BUSYBOX_DIR = $(MACHINEDIR)/busybox/r$(MACHINE_REV)

# Console parameters
CONSOLE_DEV = 0

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
