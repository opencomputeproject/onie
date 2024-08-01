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
KERNEL_MODULE_ORDER_FILE = $(MBUILDDIR)/kernel/linux/modules.order
KERNEL_MODULES_INSTALL_DIR = $(SYSROOTDIR)/lib/modules

SYSROOT_COMPLETE_STAMP	= $(STAMPDIR)/sysroot-complete
KERNEL_INSTALL_STAMP	= $(STAMPDIR)/kernel-install

$(SYSROOT_MACHINE_COMPLETE_STAMP): $(KERNEL_INSTALL_STAMP) $(SYSROOT_COMPLETE_STAMP)
	$(Q) cp -f $(INSTALLER_GRUB_COMMON_CONF) $(INSTALLER_GRUB_COMMON_CONF_ORI)
	$(Q) cp -f $(INSTALLER_GRUB_MACHINE_CONF) $(INSTALLER_GRUB_COMMON_CONF)
	$(Q) mkdir -p $(KERNEL_MODULES_INSTALL_DIR) && \
	     for file in $(shell cat ${KERNEL_MODULE_ORDER_FILE} | sed -e 's/kernel\///g') ; do \
	         cp -av $(LINUXDIR)/$$file $(KERNEL_MODULES_INSTALL_DIR); \
	     done

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
