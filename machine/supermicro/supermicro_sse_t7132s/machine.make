# Supermicro SSE-7132S

# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
# VENDOR_VERSION = .00.01

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = none

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = .1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Supermicro IANA number
VENDOR_ID = 10876

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
I2CTOOLS_SYSEEPROM = no

# Enable UEFI support
UEFI_ENABLE = yes
PXE_EFI64_ENABLE = yes

GPT_ENABLE = yes
PARTED_ENABLE = yes
IPMITOOL_ENABLE = yes

LINUX_VERSION           = 4.9
LINUX_MINOR_VERSION     = 95

RECOVERY_DEFAULT_ENTRY = embed

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
