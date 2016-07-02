#-------------------------------------------------------------------------------
#
#  Copyright (C) 2016 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the creation of a ONIE compliant
# firmware update package.
#

FIRMWARE_DIR		= $(MBUILDDIR)/firmware
FIRMWARE_CONF		= $(FIRMWARE_DIR)/machine.conf
FIRMWARE_UPDATE_BASE	= onie-firmware-$(PLATFORM).bin
FIRMWARE_UPDATE_IMAGE	= $(IMAGEDIR)/$(FIRMWARE_UPDATE_BASE)

FIRMWARE_UPDATE_COMPLETE_STAMP	= $(STAMPDIR)/firmware-update-complete

MACHINE_FW_DIR		= $(MACHINEDIR)/firmware
MACHINE_FW_INSTALLER	= $(MACHINE_FW_DIR)/fw-install.sh
MACHINE_FW_VERSION	= $(MACHINE_FW_DIR)/fw-version.make

# If firmware updates are enabled, then $(MACHINE_FW_INSTALLER) and
# $(MACHINE_FW_VERSION) must exist.
ifneq (yes,$(shell test -f $(MACHINE_FW_INSTALLER) && echo -n yes))
  $(warning ERROR: Firmware updates enabled, but no machine firmware installer script found.)
  $(error ERROR: Expecting to find $(MACHINE_FW_INSTALLER))
endif
ifneq (yes,$(shell test -f $(MACHINE_FW_VERSION) && echo -n yes))
  $(warning ERROR: Firmware updates enabled, but no machine firmware version found.)
  $(error ERROR: Expecting to find $(MACHINE_FW_VERSION))
endif
include $(MACHINE_FW_VERSION)
ifeq ($(FW_VERSION),)
  $(warning ERROR: FW_VERSION not defined.)
  $(error ERROR: Expecting to find FW_VERSION defined in $(MACHINE_FW_VERSION))
endif

ifndef MAKE_CLEAN
FIRMWARE_NEW_FILES = $(shell \
			test -d $(MACHINE_FW_DIR) && \
			test -f $(FIRMWARE_UPDATE_COMPLETE_STAMP) &&  \
			find -L $(MACHINE_FW_DIR) -mindepth 1 -cnewer $(FIRMWARE_UPDATE_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
FIRMWARE_NEW_FILES += $(shell \
			test -d $(INSTALLER_DIR) && \
			test -f $(FIRMWARE_UPDATE_COMPLETE_STAMP) &&  \
			find -L $(INSTALLER_DIR) -mindepth 1 -cnewer $(FIRMWARE_UPDATE_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(strip $(FIRMWARE_NEW_FILES)),)
    $(shell rm -f $(FIRMWARE_UPDATE_COMPLETE_STAMP))
  endif
endif

PHONY += firmware-update-complete
firmware-update-complete: $(FIRMWARE_UPDATE_COMPLETE_STAMP)
$(FIRMWARE_UPDATE_COMPLETE_STAMP): $(IMAGE_UPDATER_SHARCH) $(MACHINE_FW_INSTALLER) $(SCRIPTDIR)/onie-mk-installer.sh
	$(Q) mkdir -p $(FIRMWARE_DIR)
	$(Q) rm -f $(FIRMWARE_CONF)
	$(Q) echo "onie_version=$(FW_VERSION)" >> $(FIRMWARE_CONF)
	$(Q) echo "onie_vendor_id=$(VENDOR_ID)" >> $(FIRMWARE_CONF)
	$(Q) echo "onie_platform=$(RUNTIME_ONIE_PLATFORM)" >> $(FIRMWARE_CONF)
	$(Q) echo "onie_machine=$(RUNTIME_ONIE_MACHINE)" >> $(FIRMWARE_CONF)
	$(Q) echo "onie_machine_rev=$(MACHINE_REV)" >> $(FIRMWARE_CONF)
	$(Q) echo "onie_arch=$(ARCH)" >> $(FIRMWARE_CONF)
	$(Q) echo "onie_config_version=$(ONIE_CONFIG_VERSION)" >> $(FIRMWARE_CONF)
	$(Q) echo "onie_build_date=\"$$(date -Imin)\"" >> $(FIRMWARE_CONF)
	$(Q) echo "==== Create firmware update $(PLATFORM) self-extracting archive ===="
	$(Q) rm -f $(FIRMWARE_UPDATE_IMAGE)
	$(Q) $(SCRIPTDIR)/onie-mk-installer.sh firmware $(ROOTFS_ARCH) $(MACHINEDIR) \
		$(FIRMWARE_CONF) $(INSTALLER_DIR) $(FIRMWARE_UPDATE_IMAGE)
	$(Q) touch $@

PHONY += firmware-update
firmware-update: $(FIRMWARE_UPDATE_COMPLETE_STAMP)
	$(Q) echo "=== Finished making firmware update package $(FIRMWARE_UPDATE_BASE) ==="

CLEAN += firmware-update-clean
firmware-update-clean:
	$(Q) rm -f $(FIRMWARE_UPDATE_COMPLETE_STAMP) $(FIRMWARE_UPDATE_IMAGE)
	$(Q) rm -rf $(FIRMWARE_DIR) $(FIRMWARE_UPDATE_IMAGE)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
