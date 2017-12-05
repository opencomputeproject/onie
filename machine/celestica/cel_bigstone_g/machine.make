# Celestica Bigstone_G
#
# This configuration is for the COM-Express CPU module used on the CPU
# cards for the Celestica Bigstone_G chassis.  The target model is the
# Portwell PCOM-B632VG COM-Express module:
#
#   http://portwell.com/products/detail.php?CUSTCHAR1=PCOM-B632VG
#   http://www.portwell.com/pdf/embedded/PCOM-B632VG.pdf

# Vendor's version number can be defined here.
# Available variable is 'VENDOR_VERSION'.
# e.g.,
# VENDOR_VERSION = .00.01

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
# Celestica Inc. IANA number
VENDOR_ID = 12244

# Enable building firmware updates
FIRMWARE_UPDATE_ENABLE = yes

# Enable UEFI support
# UEFI_ENABLE = yes
PXE_EFI64_ENABLE = yes

I2CTOOLS_ENABLE = yes
I2CTOOLS_SYSEEPROM = no

# Console parameters
CONSOLE_SPEED = 57600
CONSOLE_DEV = 0

# Use the driver default MAC address for the management interfaces.
SKIP_ETHMGMT_MACS = yes

# Put the platform-discover file in the installer image
UPDATER_IMAGE_PARTS_PLATFORM = $(MACHINEDIR)/rootconf/sysroot-lib-onie/platform-discover

# Specify Linux kernel version -- comment out to use the default
LINUX_VERSION = 4.1
LINUX_MINOR_VERSION = 38

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
