# Silicom Madrid

ONIE_ARCH ?= x86_64

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

SWITCH_ASIC_VENDOR = none

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Silicom Connectivity Solutions IANA number
VENDOR_ID = 15694

IPMITOOL_ENABLE = yes

SKIP_ETHMGMT_MACS = yes

# Console parameters
CONSOLE_DEV = 0

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
