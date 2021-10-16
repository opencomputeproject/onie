#-------------------------------------------------------------------------------
#
#  Copyright (C) 2021 Alex Doyle <adoyle@nvidia.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that will generate sample keys for Secure Boot
#

# If a vendor has been specified, make that part of the path.
ifeq (,$(MACHINEROOT))
  VENDOR   = $(basename $(MACHINEROOT)/)
endif
# Encryptiong directory default, if not overridden
ENCRYPTION_DIR ?= $(abspath ../encryption )

ENCRYPTION_SCRIPT ?= $(abspath ../encryption/onie-encrypt.sh )

# Security configuration related to this build target.
#  NOTE - the / is defined with VENDOR
MACHINE_SECURITY_DIRECTORY = $(ENCRYPTION_DIR)/machines/$(VENDOR)$(MACHINE)

# If the keys directory exists, this is good.
KEYS_DIRECTORY	= $(MACHINE_SECURITY_DIRECTORY)/keys
#KEYS_DIRECTORY	= $(ENCRYPTION_DIR)/$(MACHINE)/keys
SAFE_PLACE_DIRECTORY	= $(MACHINE_SECURITY_DIRECTORY)/safe-place
KEYS_STAMPDIR = $(KEYS_DIRECTORY)
KEYS_GENERATE_STAMP	= $(KEYS_STAMPDIR)/signing-keys-generated

KEYS_INSTALL_STAMP	= $(KEYS_STAMPDIR)/signing-keys-install
KEYS_STAMP		= $(KEYS_GENERATE_STAMP)  $(KEYS_INSTALL_STAMP)

PHONY += signing-keys-install \
          signing-keys-generate \
          signing-keys-clean \
          signing-keys-distclean \
          signing-keys-values


signing-keys: $(KEYS_STAMP)

signing-keys-values:
# Echo location of the signing keys for the build target.
# These are set by the machine's machine-security-make file
# Useful for debug or scripts that need to reference them
#  NOTE - updates to machine-security-make should be reflected here.
	@echo "SIGNING_KEY_DIRECTORY          = $(SIGNING_KEY_DIRECTORY)"
	@echo "MACHINE_SECURITY_MAKEFILE      = $(MACHINE_SECURITY_MAKEFILE)"
	@echo "ONIE_VENDOR_SECRET_KEY_PEM     = $(ONIE_VENDOR_SECRET_KEY_PEM)"
	@echo "ONIE_VENDOR_CERT_DER           = $(ONIE_VENDOR_CERT_DER)"
	@echo "ONIE_VENDOR_CERT_PEM           = $(ONIE_VENDOR_CERT_PEM)"
	@echo "SHIM_SELF_SIGN_SECRET_KEY_PEM  = $(SHIM_SELF_SIGN_SECRET_KEY_PEM)"
	@echo "SHIM_SELF_SIGN_PUBLIC_CERT_PEM = $(SHIM_SELF_SIGN_PUBLIC_CERT_PEM)"
	@echo "ONIE_MODULE_SIG_KEY_SRCPREFIX  = $(ONIE_MODULE_SIG_KEY_SRCPREFIX)"
	@echo "SHIM_EMBED_DER                 = $(SHIM_EMBED_DER)"
	@echo "SHIM_SECRET_KEY                = $(SHIM_SECRET_KEY)"
	@echo "SHIM_PUBLIC_CERT               = $(SHIM_PUBLIC_CERT)"
	@echo "SHIM_PREBUILT_DIR              = $(SHIM_PREBUILT_DIR)"
	@echo "GRUB_SECRET_KEY                = $(GRUB_SECRET_KEY)"
	@echo "GRUB_PUBLIC_CERT               = $(GRUB_PUBLIC_CERT)"
	@echo "KERNEL_SECRET_KEY              = $(KERNEL_SECRET_KEY)"
	@echo "KERNEL_PUBLIC_CERT             = $(KERNEL_PUBLIC_CERT)"
	@echo "IMAGE_SECRET_KEY               = $(IMAGE_SECRET_KEY)"
	@echo "IMAGE_PUBLIC_CERT              = $(IMAGE_PUBLIC_CERT)"
	@echo "KEK_SOFTWARE_CERT              = $(KEK_SOFTWARE_CERT)"
	@echo "KEK_HARDWARE_CERT              = $(KEK_HARDWARE_CERT)"
	@echo "DB_SOFTWARE_CERT               = $(DB_SOFTWARE_CERT)"
	@echo "DB_HARDWARE_CERT               = $(DB_HARDWARE_CERT)"
	@echo "PLATFORM_CERT                  = $(PLATFORM_CERT)"
	@echo "PLATFORM_SECRET_KEY            = $(PLATFORM_SECRET_KEY)"
	@echo "SHIM_PREBUILT_DIR              = $(SHIM_PREBUILT_DIR)"
	@echo "PK_BIOS_KEY                    = $(PK_BIOS_KEY)"
	@echo "GPG_SIGN_PUBRING               = $(GPG_SIGN_PUBRING)"
	@echo "GPG_SIGN_SECRING               = $(GPG_SIGN_SECRING)"
	@echo "GRUB_USER                      = $(GRUB_USER)"
	@echo "GRUB_PASSWD_PLAINTEXT          = $(GRUB_PASSWD_PLAINTEXT)"
	@echo "GRUB_PASSWD_HASH               = $(GRUB_PASSWD_HASH)"


signing-keys-generate: $(KEYS_GENERATE_STAMP)
$(KEYS_GENERATE_STAMP):
	$(Q) echo "====  Generating signing keys  ===="
	$(Q) $(ENCRYPTION_SCRIPT)  generate-all-keys --machine-name $(MACHINE) || exit 1
	$(Q) echo "====  Keys are in $(KEYS_DIRECTORY) ===="

	$(Q) touch $@

# If keys exist, they can be copied over as many times as needed.
signing-keys-install: $(KEYS_GENERATE_STAMP) 
	$(Q) echo "==== Installing keys in $(SYSROOTDIR) ===="
	$(Q) $(ENCRYPTION_SCRIPT)  update-keys --machine-name $(MACHINE) || exit 1


# Keys are usually generated once, and should not be part of a full clean
#  Use this if creating new keys.
signing-keys-clean:
	$(Q) rm -f $(KEYS_STAMP) $(KEYS_GENERATE_STAMP) $(KEYS_INSTALL_STAMP)
	$(Q) rm -rf $(KEYS_DIRECTORY)
	$(Q) echo "=== Finished deleting generated keys in $(KEYS_DIRECTORY)"

# This will wipe out the safe place and signed shim too
# You only want this if you are regenerating keys
#  Use the 'distclean' naming convention to indicate it wipes out
#  _everything_ for a clean start.
signing-keys-distclean: signing-keys-clean
	$(Q) echo "=== Deleting all of $(MACHINE_SECURITY_DIRECTORY)"
	$(Q) rm -rf $(MACHINE_SECURITY_DIRECTORY)
	$(Q) echo "=== Done ===="



#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
