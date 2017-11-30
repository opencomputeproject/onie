# KVM x86_64 Virtual Machine

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
SWITCH_ASIC_VENDOR = qemu

# The VENDOR_VERSION string is appended to the overal ONIE version
# string.  HW vendors can use this to appended their own versioning
# information to the base ONIE version string.
# VENDOR_VERSION = .12.34

# Vendor ID -- IANA Private Enterprise Number:
# http://www.iana.org/assignments/enterprise-numbers
# Open Compute Project IANA number
VENDOR_ID = 42623

# Skip the i2ctools and the onie-syseeprom command for this platform
I2CTOOLS_ENABLE = no

# The onie-syseeprom command in i2ctools is deprecated.  It is recommended to
# use the one implemented in busybox instead.  The option intends to provide a
# quick way to turn off the feature in i2ctools.  The command will be removed
# from i2ctools in the future once all machines migrate their support of
# sys_eeprom to busybox.
#
# The option is significant when I2CTOOLS_ENABLE is 'yes'
#
#I2CTOOLS_SYSEEPROM = no

# Enable UEFI support
UEFI_ENABLE = yes

# Enable building firmware updates
FIRMWARE_UPDATE_ENABLE = yes

# Do not modify Ethernet management MACs programmed by hypervisor.
SKIP_ETHMGMT_MACS = yes

# Enable building of secure boot binaries
SECURE_BOOT_ENABLE = yes

# ONIE_VENDOR_SECRET_KEY_PEM -- file system path to private RSA key
# encoded in PEM format.
#
# WARNING: This key is extremely sensitive and should be handled
# carefully.  In practice, this key should never be checked into the
# code repository.  Set ONIE_VENDOR_SECRET_KEY_PEM on the make command
# line at build time.
#
# In this example, the machine is a demonstration vehicle and the
# secret key is not sensitive.  It is reasonable for this key to
# reside in the upstream code repository.
ONIE_VENDOR_SECRET_KEY_PEM = $(MACHINEDIR)/x509/onie-vendor-SHIM-secret-key.pem

# ONIE_VENDOR_CERT_DER -- file system path to public vendor x509
# certificate, encoded in DER format.
#
# Typically this variable is specified on the command line as we do
# not expect the certificate to reside in the upstream code
# repository.  Included here as this machine is a demonstration
# vehicle.
ONIE_VENDOR_CERT_DER = $(MACHINEDIR)/x509/onie-vendor-SHIM-cert.der

# ONIE_VENDOR_CERT_PEM -- file system path to public vendor x509
# certificate, encoded in PEM format.  Same as ONIE_VENDOR_CERT_DER,
# but in PEM format.
ONIE_VENDOR_CERT_PEM = $(MACHINEDIR)/x509/onie-vendor-SHIM-cert.pem

# SHIM_SELF_SIGN_SECRET_KEY_PEM
# SHIM_SELF_SIGN_PUBLIC_CERT_PEM
#
# These two parameters are for testing purposes only.  They allow one
# to simulate having shimx64.efi signed by a recognized signing
# authority.  The certificate used here must be loaded into the DB on
# the target system in order to verify the signature.
SHIM_SELF_SIGN_SECRET_KEY_PEM  = $(MACHINEDIR)/x509/sw-vendor-DB-secret-key.pem
SHIM_SELF_SIGN_PUBLIC_CERT_PEM = $(MACHINEDIR)/x509/sw-vendor-DB-cert.pem

# Console parameters can be defined here (default values are in
# build-config/arch/x86_64.make).
# For example,
# 
# CONSOLE_SPEED = 9600
# CONSOLE_DEV = 0

# Specify any extra parameters that you'd want to pass to the onie linux
# kernel command line in EXTRA_CMDLINE_LINUX env variable. Eg:
#
#EXTRA_CMDLINE_LINUX ?= install_url=http://server/path/to/installer debug earlyprintk=serial
#
# NOTE: You can give multiple space separated parameters

# Specify the default menu option when booting a recovery image.  Valid
# values are "rescue" or "embed" (without double-quotes). This
# parameter defaults to "rescue" mode if not specified here.
# RECOVERY_DEFAULT_ENTRY = embed

# Include additional files in the installer image.  This is useful to
# share code between the ONIE run-time and the installer.
UPDATER_IMAGE_PARTS_PLATFORM = $(MACHINEDIR)/rootconf/sysroot-lib-onie/test-install-sharing

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
