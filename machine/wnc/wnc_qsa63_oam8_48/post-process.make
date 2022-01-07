# Makefile fragment for WNC Tomcat Updater
MACHINE_IMAGE_COMPLETE_STAMP = $(STAMPDIR)/machine-image-complete

PHONY += machine-image-complete
machine-image-complete: $(MACHINE_IMAGE_COMPLETE_STAMP)
$(MACHINE_IMAGE_COMPLETE_STAMP): $(IMAGE_UPDATER_STAMP)
	$(Q) echo ">>> Making update image <<<"
	$(Q) fakeroot -- $(SCRIPTDIR)/onie-mk-installer.sh onie $(ROOTFS_ARCH) $(MACHINEDIR) \
	$(MACHINE_CONF) $(INSTALLER_DIR) \
	$(UPDATER_IMAGE) $(UPDATER_ITB) $(UPDATER_IMAGE_PARTS_PLATFORM)
	$(Q) touch $@
