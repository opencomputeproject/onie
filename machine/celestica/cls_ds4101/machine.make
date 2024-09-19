# KVM x86_64 Virtual Machine

#  Copyright (C) 2021 Alex Doyle <adoyle@nvidia.com>
#  Copyright (C) 2014,2016,2017,2018 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Stephen Su <sustephen@juniper.net>
#  Copyright (C) 2014 david_yang <david_yang@accton.com>
#  Copyright (C) 2014 Mandeep Sandhu <mandeep.sandhu@cyaninc.com>

ONIE_ARCH ?= x86_64

VENDOR_REV ?= 0

# Translate hardware revision to ONIE hardware revision
ifeq ($(VENDOR_REV),0)
  MACHINE_REV = 0
else
  $(warning Unknown VENDOR_REV '$(VENDOR_REV)' for MACHINE '$(MACHINE)')
  $(error Unknown VENDOR_REV)
endif

# The SWITCH_ASIC_VENDOR is used to further differentiate the platform
# in the ONIE waterfall.  This string should be the stock ticker
# symbol of the ASIC vendor, in lower case.  The value in this example
# here is completely fictitious.
SWITCH_ASIC_VENDOR = bcm

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
VENDOR_VERSION = .3.0.0

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 12244

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
IPMITOOL_ENABLE = yes

# Enable building firmware updates
FIRMWARE_UPDATE_ENABLE = no

# Do not modify Ethernet management MACs programmed by hypervisor.
SKIP_ETHMGMT_MACS = yes

# Enable building of secure boot binaries
# NOTE that disabling Secure Boot will require
#  editing the kernel/config file for kvm_x86_64
#  as it defaults to expecting the paths and keys
#  that this provides.
# The kernel/config-insecure file is provided as
#  an example.
SECURE_BOOT_ENABLE = no

# Enable extended secure boot:
#  Activates - ONIE password
#SECURE_BOOT_EXT = yes

# Enable GRUB verification of files and passwords
# Requires secure boot
SECURE_GRUB = no

# Define the makefile with security settings, to
# provide the option of using another file with different settings.
MACHINE_SECURITY_MAKEFILE ?= $(MACHINEDIR)/machine-security.make

# Console parameters can be defined here (default values are in
# build-config/arch/x86_64.make).
# For example,
# 
CONSOLE_SPEED = 115200 
CONSOLE_DEV = 0

# Specify any extra parameters that you'd want to pass to the onie linux
# kernel command line in EXTRA_CMDLINE_LINUX env variable. Eg:
#
#EXTRA_CMDLINE_LINUX ?= "quiet nomodeset" 
#
# NOTE: You can give multiple space separated parameters

# Specify the default menu option when booting a recovery image.  Valid
# values are "rescue" or "embed" (without double-quotes). This
# parameter defaults to "rescue" mode if not specified here.
# RECOVERY_DEFAULT_ENTRY = embed

# Include additional files in the installer image.  This is useful to
# share code between the ONIE run-time and the installer.
UPDATER_IMAGE_PARTS_PLATFORM = $(MACHINEDIR)/rootconf/sysroot-lib-onie/test-install-sharing
#LINUX_VERSION           = 4.9
#LINUX_MINOR_VERSION     = 95 

# Secure GRUB requires Secure Boot extensions
ifeq ($(SECURE_GRUB),yes)
	SECURE_BOOT_EXT = yes
endif

# Secure boot extended requires secure boot to be active.
# This will enable onie/grub passwords, detached signatures, etc
ifeq ($(SECURE_BOOT_EXT),yes)
	SECURE_BOOT_ENABLE = yes
endif

include $(MACHINEDIR)/rootconf/sysroot_machine.make
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
