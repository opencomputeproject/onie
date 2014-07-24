# Accton AS6712_32X

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
# Accton Technology Corporation IANA number
VENDOR_ID = 259

I2CTOOLS_ENABLE = yes

# Console unit and speed can be overwrite here.
CONSOLE_SPEED = 115200
CONSOLE_UNIT = 1
CONSOLE_FLAG = 1
CONSOLE_PORT = 0x2f8

VENDOR_VERSION = .0.1

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
