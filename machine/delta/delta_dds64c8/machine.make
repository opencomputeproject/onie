# Delta dds64c8

ARCH        = x86_64
TARGET      = $(ARCH)-onie-linux-uclibc
CROSSPREFIX = $(TARGET)-
CROSSBIN    = $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin
EFI_ARCH    = x64

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
VENDOR_VERSION ?= -onie_version-delta_dds64c8-v9.9

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 2254

# Enable the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = yes
IPMITOOL_ENABLE = yes

# Console parameters
CONSOLE_PORT = 0x5060
GRUB_SERIAL_COMMAND = "serial --port=0x5060 --speed=115200 --word=8 --parity=no --stop=1"

# Set Linux kernel version
LINUX_VERSION = 4.9
LINUX_MINOR_VERSION = 95

# Enable UEFI support by default
UEFI_ENABLE = yes
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
