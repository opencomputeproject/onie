#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the creation of onie images
#

ROOTCONFDIR	= $(CONFDIR)
SYSROOT_CPIO	= $(MBUILDDIR)/sysroot.cpio
SYSROOT_CPIO_XZ	= $(SYSROOT_CPIO).xz
UIMAGE		= $(IMAGEDIR)/$(MACHINE).uImage
IMAGE		= 

IMAGE_COMPLETE_STAMP	= $(STAMPDIR)/image-complete
IMAGE		= $(IMAGE_COMPLETE_STAMP)

LSB_RELEASE_FILE = $(MBUILDDIR)/lsb-release
OS_RELEASE_FILE = $(MBUILDDIR)/os-release

# List the packages to install
PACKAGES_INSTALL_STAMPS = \
	$(BUSYBOX_INSTALL_STAMP)

ifndef MAKE_CLEAN
SYSROOT_NEW_FILES = $(shell \
			test -d $(ROOTCONFDIR)/default && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(ROOTCONFDIR)/default -mindepth 1 -newer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
endif

PHONY += sysroot-complete
sysroot-complete: $(SYSROOT_COMPLETE_STAMP)
$(SYSROOT_COMPLETE_STAMP): $(PACKAGES_INSTALL_STAMPS) $(SYSROOT_NEW_FILES)
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
	$(Q) sudo cp $(LSB_RELEASE_FILE) $(SYSROOTDIR)/etc/lsb-release
	$(Q) sudo cp $(OS_RELEASE_FILE) $(SYSROOTDIR)/etc/os-release
	$(Q) touch $@

# This step creates the cpio archive and compresses it
$(SYSROOT_CPIO_XZ) : $(SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create xz compressed sysroot for bootstrap ===="
	$(Q) ( cd $(SYSROOTDIR) && \
		sudo find . | sudo cpio --create -H newc > $(SYSROOT_CPIO) )
	$(Q) xz --compress --force --check=crc32 -8 $(SYSROOT_CPIO)

$(IMAGEDIR)/onie-%.bin : $(KERNEL_INSTALL_STAMP) $(SYSROOT_CPIO_XZ) $(UBOOT_INSTALL_STAMP)
	$(Q) echo "==== Create $* u-boot multi-file initramfs uImage ===="
	$(Q) ( cd $(IMAGEDIR) && mkimage -T multi -C gzip -a 0 -e 0 -n "$*" \
		-d $(LINUXDIR)/vmlinux.bin.gz:$(SYSROOT_CPIO_XZ):$*.dtb $*.uImage )
	$(Q) echo "==== Create $* ONIE binary image ===="
	$(Q) $(SCRIPTDIR)/onie-mk-bin.sh $* $(IMAGEDIR) $(MACHINEDIR) $(UBOOT_DIR) $@

PHONY += image-complete
image-complete: $(IMAGE_COMPLETE_STAMP)
$(IMAGE_COMPLETE_STAMP): $(IMAGEDIR)/onie-$(MACHINE).bin
	$(Q) touch $@


#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
