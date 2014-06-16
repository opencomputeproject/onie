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
DEMO_SYSROOT_CPIO_XZ	= $(DEMO_SYSROOT_CPIO).xz
DEMO_UIMAGE		= $(IMAGEDIR)/demo-$(PLATFORM).uImage
DEMO_BIN		= $(IMAGEDIR)/demo-installer-$(PLATFORM).bin

DEMO_SYSROOT_COMPLETE_STAMP	= $(STAMPDIR)/demo-sysroot-complete
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
  ifneq ($(DEMO_SYSROOT_NEW_FILES),)
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
	$(Q) rm -rf $(DEMO_SYSROOTDIR)
	$(Q) echo "==== Copying existing ONIE sysroot ===="
	$(Q) cp -a $(SYSROOTDIR) $(DEMO_SYSROOTDIR)
	$(Q) cd $(DEMO_SYSROOTDIR) && rm $(DEMO_TRIM)
	$(Q) sed -i -e '/onie/d' $(DEMO_SYSROOTDIR)/etc/syslog.conf
	$(Q) cd $(DEMO_OS_DIR) && ./install $(DEMO_SYSROOTDIR)
	$(Q) t=`mktemp`; echo "machine=$(MACHINE)" > $$t ; \
		echo "platform=$(PLATFORM)" >> $$t ; \
		cp $$t $(DEMO_SYSROOTDIR)/scripts/machine.conf && rm -f $$t
	$(Q) cp $(MACHINEDIR)/demo/platform.conf $(DEMO_SYSROOTDIR)/scripts
	$(Q) touch $@

# This step creates the cpio archive and compresses it
$(DEMO_SYSROOT_CPIO_XZ) : $(DEMO_SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create xz compressed sysroot for demo OS ===="
	$(Q) cp -p $(SYSROOT_DEV_CPIO) $(DEMO_SYSROOT_CPIO)
	$(Q) fakeroot /bin/sh -c \
		"cd $(DEMO_SYSROOTDIR) && \
		find . | cpio --create -H newc --append -O $(DEMO_SYSROOT_CPIO)"
	$(Q) xz --compress --force --check=crc32 -8 $(DEMO_SYSROOT_CPIO)

$(DEMO_UIMAGE_COMPLETE_STAMP): $(KERNEL_INSTALL_STAMP) $(DEMO_SYSROOT_CPIO_XZ)
	$(Q) echo "==== Create demo $(MACHINE_PREFIX) u-boot multi-file initramfs uImage ===="
	$(Q) cd $(IMAGEDIR) && mkimage -T multi -C gzip -a 0 -e 0 -n "Demo $(MACHINE_PREFIX)" \
		-d $(LINUXDIR)/vmlinux.bin.gz:$(DEMO_SYSROOT_CPIO_XZ):$(MACHINE_PREFIX).dtb $(DEMO_UIMAGE)
	$(Q) touch $@

ifndef MAKE_CLEAN
DEMO_INSTALLER_FILES = $(shell test -d $(IMAGEDIR) && test -f $(DEMO_UIMAGE) && \
	              find -L $(DEMO_INSTALLER_DIR) -mindepth 1 -cnewer $(DEMO_BIN) \
			-type f -print -quit 2>/dev/null)
  ifneq ($(DEMO_INSTALLER_FILES),)
    $(shell rm -f $(DEMO_IMAGE_COMPLETE_STAMP))
  endif
endif

$(IMAGEDIR)/demo-installer-%.bin : $(DEMO_UIMAGE_COMPLETE_STAMP) $(MACHINE_DEMO_DIR)/*
	$(Q) echo "==== Create demo $* self-extracting archive ===="
	$(Q) ./scripts/onie-mk-demo.sh $(MACHINE) $(PLATFORM) $(DEMO_INSTALLER_DIR) $(MACHINEDIR)/demo/platform.conf \
		$(DEMO_UIMAGE) $(DEMO_BIN)

PHONY += demo-image-complete
demo-image-complete: $(DEMO_IMAGE_COMPLETE_STAMP)
$(DEMO_IMAGE_COMPLETE_STAMP): $(DEMO_BIN)
	$(Q) touch $@

CLEAN += demo-clean
demo-clean:
	$(Q) rm -rf $(DEMO_SYSROOTDIR)
	$(Q) rm -f $(MBUILDDIR)/demo-* $(DEMO_UIMAGE) $(DEMO_BIN)
	$(Q) rm -f $(DEMO_SYSROOT_COMPLETE_STAMP) $(DEMO_IMAGE_COMPLETE_STAMP)
	$(Q) rm -f $(DEMO_UIMAGE_COMPLETE_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
