#-------------------------------------------------------------------------------
#
#  Copyright (C) 2016 Audi Hsu <audi.hsu@quantatw.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# Makefile fragment for Quanta RGL-BMC
#

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
# VENDOR_VERSION = .12.34

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 7244

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

# Enable UEFI PXE
PXE_EFI64_ENABLE = yes

# Set the desired kernel version.
LINUX_VERSION		= 4.9
LINUX_MINOR_VERSION	= 95

# Use gcc-6.3.0
GCC_VERSION = 6.3.0

#
# Console parameters can be defined here (default values are in
# build-config/arch/x86_64.make).
# For example,
#
CONSOLE_SPEED = 115200
CONSOLE_DEV = 1
CONSOLE_FLAG = 0

# Enable ipmitool
IPMITOOL_ENABLE = yes

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
