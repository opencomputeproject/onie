#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This makefile for generate DEMO OS that install on Tomcat. 
#
DEMO_OS_INSTALLER: $(MBUILDDIR)/demo.initrd 
	$(Q) echo ">>> Making demo.itb <<<"
	$(Q) cd $(IMAGEDIR) && \
		V=$(V) $(SCRIPTDIR)/onie-mk-itb.sh $(MACHINE) $(MACHINE_PREFIX) $(UBOOT_ITB_ARCH) \
		$(KERNEL_LOAD_ADDRESS) $(KERNEL_ENTRY_POINT) $(FDT_LOAD_ADDRESS) \
		$(KERNEL_VMLINUZ) $(IMAGEDIR)/$(MACHINE_PREFIX).dtb $(DEMO_SYSROOT_CPIO_XZ) $(DEMO_UIMAGE)
	$(Q) echo ">>> Generating DEMO OS install image <<<"
	$(Q) ./scripts/onie-mk-demo.sh $(ROOTFS_ARCH) $(MACHINE) $(PLATFORM) \
			$(DEMO_INSTALLER_DIR) $(MACHINEDIR)/demo/platform.conf null $(DEMO_OS_BIN) OS $(DEMO_UIMAGE)

$(STAMPDIR)/demo-image-complete: DEMO_OS_INSTALLER

