#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the creation of onie images
#

ROOTCONFDIR		= $(CONFDIR)
SYSROOT_CPIO		= $(MBUILDDIR)/sysroot.cpio
SYSROOT_CPIO_XZ		= $(SYSROOT_CPIO).xz
UIMAGE			= $(IMAGEDIR)/$(MACHINE_PREFIX).uImage

IMAGE_BIN_STAMP		= $(STAMPDIR)/image-bin
IMAGE_UPDATER_STAMP	= $(STAMPDIR)/image-updater
IMAGE_COMPLETE_STAMP	= $(STAMPDIR)/image-complete
IMAGE		= $(IMAGE_COMPLETE_STAMP)

LSB_RELEASE_FILE = $(MBUILDDIR)/lsb-release
OS_RELEASE_FILE	= $(MBUILDDIR)/os-release
MACHINE_CONF	= $(MBUILDDIR)/machine.conf

INSTALLER_DIR	= $(abspath ../installer)

# List the packages to install
PACKAGES_INSTALL_STAMPS = \
	$(BUSYBOX_INSTALL_STAMP)

ifndef MAKE_CLEAN
SYSROOT_NEW_FILES = $(shell \
			test -d $(ROOTCONFDIR)/default && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(ROOTCONFDIR)/default -mindepth 1 -cnewer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(SYSROOT_NEW_FILES),)
    $(shell rm -f $(SYSROOT_COMPLETE_STAMP))
  endif
endif

PHONY += sysroot-complete
sysroot-complete: $(SYSROOT_COMPLETE_STAMP)
$(SYSROOT_COMPLETE_STAMP): $(PACKAGES_INSTALL_STAMPS)
	$(Q) sudo rm -f $(SYSROOTDIR)/linuxrc
	$(Q) echo "==== Installing the basic set of devices ===="
	$(Q) sudo $(SCRIPTDIR)/make-devices.pl $(SYSROOTDIR)
	$(Q) cd $(ROOTCONFDIR) && sudo ./install $(SYSROOTDIR)
	$(Q) cd $(SYSROOTDIR) && sudo ln -fs sbin/init ./init
	$(Q) rm -f $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_ID=onie" >> $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_RELEASE=$(LSB_RELEASE_TAG)" >> $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_DESCRIPTION=Open Network Install Environment" >> $(LSB_RELEASE_FILE)
	$(Q) rm -f $(OS_RELEASE_FILE)
	$(Q) echo "NAME=\"onie\"" >> $(OS_RELEASE_FILE)
	$(Q) echo "VERSION=\"$(LSB_RELEASE_TAG)\"" >> $(OS_RELEASE_FILE)
	$(Q) echo "ID=linux" >> $(OS_RELEASE_FILE)
	$(Q) rm -f $(MACHINE_CONF)
	$(Q) echo "onie_version=$(LSB_RELEASE_TAG)" >> $(MACHINE_CONF)
	$(Q) echo "onie_vendor_id=$(VENDOR_ID)" >> $(MACHINE_CONF)
	$(Q) echo "onie_platform=$(PLATFORM)" >> $(MACHINE_CONF)
	$(Q) echo "onie_machine=$(MACHINE)" >> $(MACHINE_CONF)
	$(Q) echo "onie_machine_rev=$(MACHINE_REV)" >> $(MACHINE_CONF)
	$(Q) echo "onie_arch=$(ARCH)" >> $(MACHINE_CONF)
	$(Q) sudo cp $(LSB_RELEASE_FILE) $(SYSROOTDIR)/etc/lsb-release
	$(Q) sudo cp $(OS_RELEASE_FILE) $(SYSROOTDIR)/etc/os-release
	$(Q) sudo cp $(MACHINE_CONF) $(SYSROOTDIR)/etc/machine.conf
	$(Q) touch $@

# This step creates the cpio archive and compresses it
$(SYSROOT_CPIO_XZ) : $(SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create xz compressed sysroot for bootstrap ===="
	$(Q) ( cd $(SYSROOTDIR) && \
		sudo find . | sudo cpio --create -H newc > $(SYSROOT_CPIO) )
	$(Q) xz --compress --force --check=crc32 -8 $(SYSROOT_CPIO)

.SECONDARY: $(IMAGEDIR)/$(MACHINE_PREFIX).uImage

$(IMAGEDIR)/%.uImage : $(KERNEL_INSTALL_STAMP) $(SYSROOT_CPIO_XZ)
	$(Q) echo "==== Create $* u-boot multi-file initramfs uImage ===="
	$(Q) ( cd $(IMAGEDIR) && mkimage -T multi -C gzip -a 0 -e 0 -n "$*" \
		-d $(LINUXDIR)/vmlinux.bin.gz:$(SYSROOT_CPIO_XZ):$*.dtb $*.uImage )

PHONY += image-bin
image-bin: $(IMAGE_BIN_STAMP)
$(IMAGE_BIN_STAMP): $(IMAGEDIR)/$(MACHINE_PREFIX).uImage $(UBOOT_INSTALL_STAMP) $(SCRIPTDIR)/onie-mk-bin.sh
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE binary image ===="
	$(Q) $(SCRIPTDIR)/onie-mk-bin.sh $(MACHINE_PREFIX) $(IMAGEDIR) \
		$(MACHINEDIR) $(UBOOT_DIR) $(IMAGEDIR)/onie-$(MACHINE_PREFIX).bin
	$(Q) touch $@

ifndef MAKE_CLEAN
IMAGE_UPDATER_FILES = $(shell \
			test -d $(INSTALLER_DIR) && \
			find -L $(INSTALLER_DIR) -mindepth 1 -cnewer $(IMAGE_UPDATER_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(IMAGE_UPDATER_FILES),)
    $(shell rm -f $(IMAGE_UPDATER_STAMP))
  endif
endif

PHONY += image-updater
image-updater: $(IMAGE_UPDATER_STAMP)
$(IMAGE_UPDATER_STAMP): $(IMAGEDIR)/$(MACHINE_PREFIX).uImage $(UBOOT_INSTALL_STAMP) $(SCRIPTDIR)/onie-mk-installer.sh
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE updater ===="
	$(Q) $(SCRIPTDIR)/onie-mk-installer.sh $(MACHINE_PREFIX) $(MACHINE_CONF) \
		$(INSTALLER_DIR) $(IMAGEDIR) $(MACHINEDIR) $(IMAGEDIR)/onie-updater-$(ARCH)-$(MACHINE_PREFIX)
	$(Q) touch $@

PHONY += image-complete
image-complete: $(IMAGE_COMPLETE_STAMP)
$(IMAGE_COMPLETE_STAMP): $(IMAGE_BIN_STAMP) $(IMAGE_UPDATER_STAMP)
	$(Q) touch $@

CLEAN += image-clean
image-clean:
	$(Q) rm -f $(IMAGEDIR)/onie-$(MACHINE_PREFIX).bin $(IMAGEDIR)/onie-installer-$(MACHINE_PREFIX).sh \
		$(IMAGEDIR)/$(MACHINE_PREFIX).uImage $(SYSROOT_CPIO_XZ) $(IMAGE_COMPLETE_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
