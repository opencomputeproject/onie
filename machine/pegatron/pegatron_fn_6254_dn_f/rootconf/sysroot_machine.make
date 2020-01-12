#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that copy library for pegatron mercedes to sysroot
#

INSTALLER_GRUB_COMMON_CONF = $(abspath ../installer/grub-arch/grub/grub-common.cfg)
INSTALLER_GRUB_COMMON_CONF_ORI = $(MACHINEDIR)/rootconf/grub/grub-common.cfg.ori
INSTALLER_GRUB_MACHINE_CONF = $(MACHINEDIR)/rootconf/grub/grub-common.cfg
SYSROOT_MACHINE_COMPLETE_STAMP = $(STAMPDIR)/sysroot-machine-complete
MACHINE_IMAGE_COMPLETE_STAMP = $(STAMPDIR)/machine-image-complete

$(SYSROOT_MACHINE_COMPLETE_STAMP): $(SYSROOT_COMPLETE_STAMP)
	$(Q) cp -f $(INSTALLER_GRUB_COMMON_CONF) $(INSTALLER_GRUB_COMMON_CONF_ORI)
	$(Q) cp -f $(INSTALLER_GRUB_MACHINE_CONF) $(INSTALLER_GRUB_COMMON_CONF)

sysroot-machine-clean:
	$(Q) if [ -f "$(INSTALLER_GRUB_COMMON_CONF_ORI)" ] ; then \
	        cp -f $(INSTALLER_GRUB_COMMON_CONF_ORI) $(INSTALLER_GRUB_COMMON_CONF); \
	        rm -f $(INSTALLER_GRUB_COMMON_CONF_ORI); \
	     fi;
	$(Q) rm -f $(MACHINE_IMAGE_COMPLETE_STAMP)

$(IMAGEDIR)/$(MACHINE_PREFIX).initrd: $(SYSROOT_MACHINE_COMPLETE_STAMP)

sysroot-clean: sysroot-machine-clean

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
