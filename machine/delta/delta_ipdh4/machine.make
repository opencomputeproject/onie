# Delta IPDH4

ARCH        = x86_64
TARGET      = $(ARCH)-onie-linux-uclibc
CROSSPREFIX = $(TARGET)-
CROSSBIN    = $(XTOOLS_INSTALL_DIR)/$(TARGET)/bin
EFI_ARCH    = x64

ONIE_ARCH ?= x86_64
SWITCH_ASIC_VENDOR = bcm

VENDOR_REV ?= 0
VENDOR_VERSION ?= -onie_version-nokia_ipdh4-v1.0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif
# Enable building of secure boot binaries
# NOTE that disabling Secure Boot will require
#  editing the kernel/config file for kvm_x86_64
#  as it defaults to expecting the paths and keys
#  that this provides.
# The kernel/config-insecure file is provided as
#  an example.
SECURE_BOOT_ENABLE = yes

# Enable extended secure boot:
#  Activates - ONIE password
SECURE_BOOT_EXT = yes

# Enable GRUB verification of files and passwords
# Requires secure boot
SECURE_GRUB = yes


# Define the makefile with security settings, to
# provide the option of using another file with different settings.
MACHINE_SECURITY_MAKEFILE ?= $(MACHINEDIR)/machine-security.make


# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Delta Electronics, Inc.
VENDOR_ID = 2254

I2CTOOLS_ENABLE = yes

CONSOLE_SPEED = 115200
CONSOLE_DEV = 0
CONSOLE_FLAG = 0

EXTRA_CMDLINE_LINUX = i2c-ismt.bus_speed=100

# Set Linux kernel version
LINUX_VERSION           = 4.9
LINUX_MINOR_VERSION     = 95

# Enable UEFI support
UEFI_ENABLE = yes

#Enable Pxe boot ONIE 
PXE_EFI64_ENABLE = yes

GRUB_CMDLINE_LINUX = "console=tty0 console=ttyS0,115200n8"
GRUB_SERIAL_COMMAND = "serial --port=0x3f8 --speed=115200 --word=8 --parity=no --stop=1"
# Secure GRUB requires Secure Boot extensions
ifeq ($(SECURE_GRUB),yes)
        SECURE_BOOT_EXT = yes
endif

# Secure boot extended requires secure boot to be active.
# This will enable onie/grub passwords, detached signatures, etc
ifeq ($(SECURE_BOOT_EXT),yes)
        SECURE_BOOT_ENABLE = yes
endif


# Override LSB_RELEASE_TAG
##override LSB_RELEASE_TAG = delta-v0.0

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
