# Security makefile fragment for the kvm_x86_64 build target.

#  Copyright (C) 2021 Alex Doyle <adoyle@nvidia.com>

#
# This holds all the variables that affect the security configuration
#  for an ONIE build.  While different variables may be set to the
#  same key file, this provides an explicit mapping as to
#  which key will be used in a particular context.
#
# The paths in this file reference example keys generated with:
#   make signing-keys-generate MACHINE=kvm_x86_64
#
# Production builds for real devices should have different keys and
#  different locations to meet the customization and security needs
#  of the vendor.

# Developer NOTE: the build-config/make/signing-keys.make file prints 
#        these values with the signing-keys-values make target.
#        Changes here should be reflected there.

# When programming the UEFI BIOS, the Platform key should be set to
#  be this key:
#  $(SIGNING_KEY_DIRECTORY)HW/efi-keys/HW-platform-key-cert.der

# A per-machine directory to hold encryption keys/settings
ENCRYPTION_DIRECTORY ?= $(PROJECTDIR)/encryption/machines/$(MACHINE)

# KVM uses test keys generated under onie/encryption.
#   Again, your use may/should be different.
SIGNING_KEY_DIRECTORY ?= $(ENCRYPTION_DIRECTORY)/keys

# A 'safe place' to store files we don't want changing - like the signed shim
SAFE_PLACE_DIRECTORY ?= $(ENCRYPTION_DIRECTORY)/safe-place

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
ONIE_VENDOR_SECRET_KEY_PEM ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem

# ONIE_VENDOR_CERT_DER -- file system path to public vendor x509
# certificate, encoded in DER format.
#
# Typically this variable is specified on the command line as we do
# not expect the certificate to reside in the upstream code
# repository.  Included here as this machine is a demonstration
# vehicle.
ONIE_VENDOR_CERT_DER ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.der

# ONIE_VENDOR_CERT_PEM -- file system path to public vendor x509
# certificate, encoded in PEM format.  Same as ONIE_VENDOR_CERT_DER
# but in PEM format.
# This is also used in the machine kernel config.
ONIE_VENDOR_CERT_PEM ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem

# These two parameters are for testing purposes only.  They allow one
# to simulate having shimx64.efi signed by a recognized signing
# authority.  The certificate used here must be loaded into the DB on
# the target system in order to verify the signature.
SHIM_SELF_SIGN_SECRET_KEY_PEM ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-secret-key.pem
SHIM_SELF_SIGN_PUBLIC_CERT_PEM ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-cert.pem

# Directory used by MODULE_SIG_KEY_SRCPREFIX in onie/build-config/make/kernel.make
# ...which means it is where the kernel will look for the public key it builds
#  in to itself to verify module signatures with.
ONIE_MODULE_SIG_KEY_SRCPREFIX ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys

# This key is built into the shim. So when the SHIM is signed, that chain
#  of trust will pass to this key as well. Typically this would be the NOS key,
#  to be trusted by the entity that signed the shim with a different key.
SHIM_EMBED_DER ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.der

# Keys that sign shim
SHIM_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-secret-key.pem
SHIM_PUBLIC_CERT ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-cert.pem

# Location of signed shim, fb, and mk efi files, used by images.make
# If it does not exist yet, set it blank since the shim may need to
#  be built, signed, and then put into the safe place
ifeq ($(wildcard $(SAFE_PLACE_DIRECTORY)),)
  SHIM_PREBUILT_DIR ?=
else
# A place for the signed shim
  SHIM_PREBUILT_DIR ?= $(SAFE_PLACE_DIRECTORY)
endif


# Keys that sign Grub
GRUB_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem
GRUB_PUBLIC_CERT ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem

# Keys that sign the kernel
KERNEL_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem
KERNEL_PUBLIC_CERT ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem

# Keys that sign grub in the recovery image
IMAGE_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-secret-key.pem
IMAGE_PUBLIC_CERT ?= $(SIGNING_KEY_DIRECTORY)/ONIE/efi-keys/ONIE-shim-key-cert.pem

# UEFI keys

# Key Exchange Key database. Keys here can modify db/dbx entries
KEK_SOFTWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-key-exchange-key-cert.pem
KEK_HARDWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-key-exchange-key-cert.pem

# Key DataBase - keys here are available for shim/grub use too
DB_SOFTWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/SW/efi-keys/SW-database-key-cert.pem
DB_HARDWARE_CERT ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-database-key-cert.pem

# Example of Support for an additional key in UEFI db. This could be a development key,
# or an additional NOS vendor key.  Uncomment to use.
#DB_EXTRA_CERT ?= $(SIGNING_KEY_DIRECTORY)/extra/key-exported-dev/dev-code-signing.pem

# Hardware manufacturer's keys
PLATFORM_CERT ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-platform-key-cert.pem
PLATFORM_SECRET_KEY ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-platform-key-secret-key.pem

# Copy this key to be available for the developer at BIOS setup time.
PK_BIOS_KEY ?= $(SIGNING_KEY_DIRECTORY)/HW/efi-keys/HW-platform-key-cert.der

# Secure GRUB settings
# GPG Keys - used for signing files that GRUB loads
GPG_SIGN_PUBRING ?= $(SIGNING_KEY_DIRECTORY)/ONIE/gpg-keys/ONIE-pubring.kbx
GPG_SIGN_SECRING ?= $(SIGNING_KEY_DIRECTORY)/ONIE/gpg-keys/ONIE-secret.asc

# GRUB user
GRUB_USER ?= root

# Set GRUB password
#  By plaintext
GRUB_PASSWD_PLAINTEXT ?= onie

#  Or by supplying a hash (currently unset)
GRUB_PASSWD_HASH ?= 

