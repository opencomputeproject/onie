#------------------------------------------------------------------------------
#
#
#------------------------------------------------------------------------------
#
# This is a makefile fragment that replace configuration of grub menu
# for STX-60D0-062F.
#

RECOVERY_ISO_GRUB_CONF = $(abspath ../build-config/recovery/grub-iso.cfg)
RECOVERY_ISO_GRUB_CONF_ORI = $(MACHINEDIR)/rootconf/onie-grub/grub-iso.cfg.ori
RECOVERY_ISO_GRUB_CONF_COMPLETE_STAMP = $(STAMPDIR)/iso-grub-machine-complete
RECOVERY_ISO_GRUB_MACHINE_CONF = $(MACHINEDIR)/rootconf/onie-grub/grub-iso.cfg
MACHINE_IMAGE_COMPLETE_STAMP = $(STAMPDIR)/machine-image-complete

$(RECOVERY_ISO_GRUB_CONF_COMPLETE_STAMP) : $(RECOVERY_ISO_STAMP)
	$(Q) cp -f $(RECOVERY_ISO_GRUB_CONF) $(RECOVERY_ISO_GRUB_CONF_ORI)
	$(Q) cp -f $(RECOVERY_ISO_GRUB_MACHINE_CONF) $(RECOVERY_ISO_GRUB_CONF)
	$(Q) touch $@

sysroot-machine-clean:
	$(Q) if [ -f "$(RECOVERY_ISO_GRUB_CONF_ORI)" ] ; then \
	        cp -f $(RECOVERY_ISO_GRUB_CONF_ORI) $(RECOVERY_ISO_GRUB_CONF); \
	        rm -f $(RECOVERY_ISO_GRUB_CONF_ORI); \
	     fi;
	$(Q) rm -f $(MACHINE_IMAGE_COMPLETE_STAMP)
	$(Q) rm -f $(RECOVERY_ISO_GRUB_CONF_COMPLETE_STAMP)

$(STAMPDIR)/recovery-iso: $(RECOVERY_ISO_GRUB_CONF_COMPLETE_STAMP)
sysroot-clean: sysroot-machine-clean

#------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
