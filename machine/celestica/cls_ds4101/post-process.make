INSTALLER_GRUB_COMMON_CONF ?= $(abspath ../installer/grub-arch/grub/grub-common.cfg)
INSTALLER_GRUB_COMMON_CONF_ORI ?= $(MACHINEDIR)/rootconf/grub/grub-common.cfg.ori
MACHINE_IMAGE_COMPLETE_STAMP = $(STAMPDIR)/machine-image-complete

PHONY += machine-image-complete
machine-image-complete: $(MACHINE_IMAGE_COMPLETE_STAMP)
$(MACHINE_IMAGE_COMPLETE_STAMP): $(IMAGE_UPDATER_STAMP)
	$(Q) cp -f $(INSTALLER_GRUB_COMMON_CONF_ORI) $(INSTALLER_GRUB_COMMON_CONF)
	$(Q) rm -f $(INSTALLER_GRUB_COMMON_CONF_ORI)
	$(Q) touch $@