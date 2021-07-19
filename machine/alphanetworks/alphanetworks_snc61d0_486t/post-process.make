RECOVERY_ISO_GRUB_CONF ?= $(abspath ../build-config/recovery/grub-iso.cfg)
RECOVERY_ISO_GRUB_CONF_ORI ?= $(MACHINEDIR)/rootconf/onie-grub/grub-iso.cfg.ori
MACHINE_IMAGE_COMPLETE_STAMP = $(STAMPDIR)/machine-image-complete
RECOVERY_ISO_GRUB_CONF_COMPLETE_STAMP = $(STAMPDIR)/iso-grub-machine-complete

PHONY += machine-image-complete
machine-image-complete: $(MACHINE_IMAGE_COMPLETE_STAMP)
$(MACHINE_IMAGE_COMPLETE_STAMP): $(RECOVERY_ISO_STAMP)
	$(Q) cp -f $(RECOVERY_ISO_GRUB_CONF_ORI) $(RECOVERY_ISO_GRUB_CONF)
	$(Q) rm -f $(RECOVERY_ISO_GRUB_CONF_ORI)
	$(Q) rm -f $(RECOVERY_ISO_GRUB_CONF_COMPLETE_STAMP)
	$(Q) touch $@
