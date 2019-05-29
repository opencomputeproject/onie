# Pegatron fn_6254_dn_f

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = nephos

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
VENDOR_ID = 32022

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

CONSOLE_SPEED = 115200
CONSOLE_DEV = 0
CONSOLE_FLAG = 0

# Recovery ISO default entry set to embed for factory production
RECOVERY_DEFAULT_ENTRY=embed

# Specify Linux kernel version -- comment out to use the default
LINUX_VERSION = 4.9
LINUX_MINOR_VERSION = 95

#Extra kernel command line
#EXTRA_CMDLINE_LINUX ?= debug
 
include $(MACHINEDIR)/rootconf/sysroot_machine.make

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
