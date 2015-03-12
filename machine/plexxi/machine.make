# Plexxi

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
# Open Compute Project IANA number
VENDOR_ID = 37341

# Skip the i2ctools and the onie-syseeprom command for this platform
#I2CTOOLS_ENABLE = no

PARTITION_TYPE=msdos

PXE_EFI64_ENABLE=yes

LINUX_VERSION           = 3.14
LINUX_MINOR_VERSION     = 27

CONSOLE_SPEED = 38400
CONSOLE_DEV = 0
CONSOLE_FLAG = 1

# Ends up at the end of the kernel cmdline in installer/x86_64/grub.d/50_onie_grub
GRUB_CMDLINE_LINUX = $${plexxi_onie_cmdline}

# Include platform overrides in updater
UPDATER_IMAGE_PARTS_PLATFORM = $(MACHINEDIR)/rootconf/sysroot-lib-onie/onie-blkdev-platform

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:

