#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the creation of a demo "hello world"
# operating system and ONIE compatible installer.
#

DEMO_SYSROOTDIR		= $(MBUILDDIR)/demo-sysroot
DEMO_SYSROOT_CPIO	= $(MBUILDDIR)/demo-sysroot.cpio
DEMO_SYSROOT_CPIO_XZ	= $(MBUILDDIR)/demo.initrd
DEMO_KERNEL_VMLINUZ	= $(MBUILDDIR)/demo.vmlinuz
DEMO_UIMAGE		= $(IMAGEDIR)/demo-$(PLATFORM).itb
DEMO_BIN		= $(IMAGEDIR)/demo-installer-$(PLATFORM).bin

DEMO_SYSROOT_COMPLETE_STAMP	= $(STAMPDIR)/demo-sysroot-complete
DEMO_KERNEL_COMPLETE_STAMP	= $(STAMPDIR)/demo-kernel-complete
DEMO_UIMAGE_COMPLETE_STAMP	= $(STAMPDIR)/demo-uimage-complete
DEMO_IMAGE_COMPLETE_STAMP	= $(STAMPDIR)/demo-image-complete
DEMO_IMAGE		= $(DEMO_IMAGE_COMPLETE_STAMP)

DEMO_DIR		= $(abspath ../demo)
DEMO_OS_DIR		= $(DEMO_DIR)/os
DEMO_INSTALLER_DIR	= $(DEMO_DIR)/installer
MACHINE_DEMO_DIR	= $(MACHINEDIR)/demo

ifndef MAKE_CLEAN
DEMO_SYSROOT_NEW_FILES = $(shell \
			test -d $(DEMO_OS_DIR)/default && \
			test -f $(DEMO_SYSROOT_COMPLETE_STAMP) &&  \
			find -L $(DEMO_OS_DIR)/default -mindepth 1 -cnewer $(DEMO_SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
DEMO_SYSROOT_NEW_FILES += $(shell \
			test -d $(DEMO_OS_DIR)/$(ONIE_ARCH) && \
			test -f $(DEMO_SYSROOT_COMPLETE_STAMP) &&  \
			find -L $(DEMO_OS_DIR)/$(ONIE_ARCH) -mindepth 1 -cnewer $(DEMO_SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(strip $(DEMO_SYSROOT_NEW_FILES)),)
    $(shell rm -f $(DEMO_SYSROOT_COMPLETE_STAMP))
  endif
endif

# List of files to remove from base ONIE image for the demo.
DEMO_TRIM = \
   etc/rc3.d/S50discover.sh	\
   etc/init.d/discover.sh	\
   bin/discover			\
   bin/uninstaller		\
   scripts/udhcp4_sd		

PHONY += demo-sysroot-complete
demo-sysroot-complete: $(DEMO_SYSROOT_COMPLETE_STAMP)
$(DEMO_SYSROOT_COMPLETE_STAMP): $(SYSROOT_COMPLETE_STAMP)
	$(Q) sudo rm -rf $(DEMO_SYSROOTDIR)
	$(Q) echo "==== Copying existing ONIE sysroot ===="
	$(Q) sudo cp -a $(SYSROOTDIR) $(DEMO_SYSROOTDIR)
	$(Q) cd $(DEMO_SYSROOTDIR) && sudo rm $(DEMO_TRIM)
	$(Q) sudo sed -i -e '/onie/d' $(DEMO_SYSROOTDIR)/etc/syslog.conf
	$(Q) cd $(DEMO_OS_DIR) && sudo ./install default $(DEMO_SYSROOTDIR)
	$(Q) cd $(DEMO_OS_DIR) && sudo ./install $(ONIE_ARCH) $(DEMO_SYSROOTDIR)
	$(Q) t=`mktemp`; echo "machine=$(MACHINE)" > $$t ; \
		echo "platform=$(PLATFORM)" >> $$t ; \
		sudo cp $$t $(DEMO_SYSROOTDIR)/scripts/machine.conf && rm -f $$t
	$(Q) sudo cp $(MACHINEDIR)/demo/platform.conf $(DEMO_SYSROOTDIR)/scripts
	$(Q) touch $@

# This step creates the cpio archive and compresses it
$(DEMO_SYSROOT_CPIO_XZ) : $(DEMO_SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create xz compressed sysroot for demo OS ===="
	$(Q) ( cd $(DEMO_SYSROOTDIR) && \
		sudo find . | sudo cpio --create -H newc > $(DEMO_SYSROOT_CPIO) )
	$(Q) xz --compress --force --check=crc32 --stdout -8 $(DEMO_SYSROOT_CPIO) > $@

$(DEMO_UIMAGE_COMPLETE_STAMP): $(KERNEL_INSTALL_STAMP) $(DEMO_SYSROOT_CPIO_XZ)
	$(Q) echo "==== Create demo $(MACHINE_PREFIX) u-boot multi-file initramfs itb ===="
	$(Q) cd $(IMAGEDIR) && $(SCRIPTDIR)/onie-mk-itb.sh $(MACHINE) \
				$(MACHINE_PREFIX) $(DEMO_SYSROOT_CPIO_XZ) $(DEMO_UIMAGE)
	$(Q) touch $@

$(DEMO_KERNEL_COMPLETE_STAMP): $(KERNEL_INSTALL_STAMP)
	$(Q) cd $$(dirname $(DEMO_KERNEL_VMLINUZ)) && \
		ln -sf $(KERNEL_VMLINUZ) $$(basename $(DEMO_KERNEL_VMLINUZ))
	$(Q) touch $@

ifndef MAKE_CLEAN
DEMO_INSTALLER_FILES = $(shell test -d $(IMAGEDIR) && test -f $(DEMO_SYSROOT_CPIO_XZ) && \
	              find -L $(DEMO_INSTALLER_DIR) -mindepth 1 -cnewer $(DEMO_BIN) \
			-type f -print -quit 2>/dev/null)
  ifneq ($(strip $(DEMO_INSTALLER_FILES)),)
    $(shell rm -f $(DEMO_IMAGE_COMPLETE_STAMP) $(DEMO_BIN))
  endif
endif

# $(IMAGEDIR)/demo-installer-%.bin : $(DEMO_IMAGE_PARTS_COMPLETE) $(MACHINE_DEMO_DIR)/*
$(DEMO_BIN) : $(DEMO_IMAGE_PARTS_COMPLETE) $(MACHINE_DEMO_DIR)/*
	$(Q) echo "==== Create demo $(PLATFORM) self-extracting archive ===="
	$(Q) ./scripts/onie-mk-demo.sh $(ONIE_ARCH) $(MACHINE) $(PLATFORM) \
		$(DEMO_INSTALLER_DIR) $(MACHINEDIR)/demo/platform.conf $@ $(DEMO_IMAGE_PARTS)

PHONY += demo-image-complete
demo-image-complete: $(DEMO_IMAGE_COMPLETE_STAMP)
$(DEMO_IMAGE_COMPLETE_STAMP): $(DEMO_BIN)
	$(Q) touch $@

CLEAN += demo-clean
demo-clean:
	$(Q) sudo rm -rf $(DEMO_SYSROOTDIR)
	$(Q) rm -f $(MBUILDDIR)/demo-* $(DEMO_IMAGE_PARTS) $(DEMO_BIN)
	$(Q) rm -f $(DEMO_SYSROOT_COMPLETE_STAMP) $(DEMO_IMAGE_COMPLETE_STAMP)
	$(Q) rm -f $(DEMO_IMAGE_PARTS_COMPLETE)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
