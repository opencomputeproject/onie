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
DEMO_INSTALL_SCRIPT = $(abspath ../demo/installer/grub-arch/install.sh)
DEMO_INSTALL_SCRIPT_ORI = $(MACHINEDIR)/demo/install.sh.ori
DEMO_INSTALL_SCRIPT_MACHINE = $(MACHINEDIR)/demo/install.sh
DEMO_SYSROOT_MACHINE_COMPLETE_STAMP = $(STAMPDIR)/sysroot-demo-machine-complete
DEMO_IMAGE_MACHINE_COMPLETE_STAMP = $(STAMPDIR)/demo-image-machine-complete

$(DEMO_SYSROOT_MACHINE_COMPLETE_STAMP): $(DEMO_SYSROOT_COMPLETE_STAMP)
	$(Q) cp -f $(DEMO_INSTALL_SCRIPT) $(DEMO_INSTALL_SCRIPT_ORI)
	$(Q) cp -f $(DEMO_INSTALL_SCRIPT_MACHINE) $(DEMO_INSTALL_SCRIPT)

$(DEMO_IMAGE_MACHINE_COMPLETE_STAMP): $(DEMO_IMAGE_COMPLETE_STAMP)
	$(Q) cp -f $(DEMO_INSTALL_SCRIPT_ORI) $(DEMO_INSTALL_SCRIPT)
	$(Q) rm -f $(DEMO_INSTALL_SCRIPT_ORI)
	$(Q) if [ -f "$(INSTALLER_GRUB_COMMON_CONF_ORI)" ] ; then \
	        cp -f $(INSTALLER_GRUB_COMMON_CONF_ORI) $(INSTALLER_GRUB_COMMON_CONF); \
	        rm -f $(INSTALLER_GRUB_COMMON_CONF_ORI); \
	     fi;

demo-machine-clean:
	$(Q) if [ -f "$(DEMO_INSTALL_SCRIPT_ORI)" ] ; then \
	        cp -f $(DEMO_INSTALL_SCRIPT_ORI) $(DEMO_INSTALL_SCRIPT); \
	        rm -f $(DEMO_INSTALL_SCRIPT_ORI); \
	     fi;
	$(Q) rm -f $(DEMO_IMAGE_MACHINE_COMPLETE_STAMP)

$(MBUILDDIR)/demo.initrd: $(DEMO_SYSROOT_MACHINE_COMPLETE_STAMP)

$(STAMPDIR)/demo-image-complete: $(DEMO_IMAGE_MACHINE_COMPLETE_STAMP)

demo-clean: demo-machine-clean

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
