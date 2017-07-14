# WNC ONIE
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

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = .1.1

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
# WNC is 15756
VENDOR_ID = 15756

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

# Set the desired kernel version.
LINUX_VERSION		= 3.14
LINUX_MINOR_VERSION	= 27

# Older GCC required for older 3.14.27 kernel
GCC_VERSION = 4.9.2

#UEFI_ENABLE = yes
IPMITOOL_ENABLE = yes

#
# Console parameters can be defined here (default values are in
# build-config/arch/x86_64.make).
# For example,
# 
CONSOLE_SPEED = 115200
CONSOLE_DEV = 1
CONSOLE_FLAG = 1

# Specify any extra parameters that you'd want to pass to the onie linux
# kernel command line in EXTRA_CMDLINE_LINUX env variable. Eg:
#
#EXTRA_CMDLINE_LINUX ?= install_url=http://server/path/to/installer debug earlyprintk=serial
#
# NOTE: You can give multiple space separated parameters

# Specify the default menu option for syslinux when booting a recovery image
# Valid values are "rescue" or "embed" (without double-quotes). This parameter
# defaults to "rescue" mode if not specified here.
SYSLINUX_DEFAULT_MODE ?= rescue

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
