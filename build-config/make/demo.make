#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2015 david_yang <david_yang@accton.com>
#
#  SPDX-License-Identifier:     GPL-2.0
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
DEMO_OS_BIN		= $(IMAGEDIR)/demo-installer-$(PLATFORM).bin
DEMO_DIAG_BIN		= $(IMAGEDIR)/demo-diag-installer-$(PLATFORM).bin

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
			test -d $(DEMO_OS_DIR)/$(ROOTFS_ARCH) && \
			test -f $(DEMO_SYSROOT_COMPLETE_STAMP) &&  \
			find -L $(DEMO_OS_DIR)/$(ROOTFS_ARCH) -mindepth 1 -cnewer $(DEMO_SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(strip $(DEMO_SYSROOT_NEW_FILES)),)
    $(shell rm -f $(DEMO_SYSROOT_COMPLETE_STAMP))
  endif
endif

# List of files to remove from base ONIE image for the demo.
DEMO_TRIM = \
   etc/rc0.d/K25discover.sh	\
   etc/rc3.d/S50discover.sh	\
   etc/rc6.d/K25discover.sh	\
   etc/rcS.d/S03boot-mode.sh	\
   etc/init.d/discover.sh	\
   etc/init.d/boot-mode.sh	\
   bin/discover			\
   bin/uninstaller		\
   bin/onie-uninstaller		\
   lib/onie/udhcp4_sd		

PHONY += demo-sysroot-complete
demo-sysroot-complete: $(DEMO_SYSROOT_COMPLETE_STAMP)
$(DEMO_SYSROOT_COMPLETE_STAMP): $(SYSROOT_CPIO_XZ)
	$(Q) rm -rf $(DEMO_SYSROOTDIR)
	$(Q) echo "==== Copying existing ONIE sysroot ===="
	$(Q) cp -a $(SYSROOTDIR) $(DEMO_SYSROOTDIR)
	$(Q) cd $(DEMO_SYSROOTDIR) && rm $(DEMO_TRIM)
	$(Q) sed -i -e '/onie/d' $(DEMO_SYSROOTDIR)/etc/syslog.conf
	$(Q) cd $(DEMO_OS_DIR) && $(SCRIPTDIR)/install-rootfs.sh default $(DEMO_SYSROOTDIR)
	$(Q) cd $(DEMO_OS_DIR) && $(SCRIPTDIR)/install-rootfs.sh $(ROOTFS_ARCH) $(DEMO_SYSROOTDIR)
	$(Q) mkdir -p $(DEMO_SYSROOTDIR)/lib/demo
	$(Q) t=`mktemp`; echo "machine=$(MACHINE)" > $$t ; \
		echo "platform=$(PLATFORM)" >> $$t ; \
		cp $$t $(DEMO_SYSROOTDIR)/lib/demo/machine.conf && rm -f $$t
	$(Q) cp $(MACHINEDIR)/demo/platform.conf $(DEMO_SYSROOTDIR)/lib/demo
	$(Q) touch $@

# This step creates the cpio archive and compresses it
$(DEMO_SYSROOT_CPIO_XZ) : $(DEMO_SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create xz compressed sysroot for demo OS ===="
	$(Q) fakeroot -- $(SCRIPTDIR)/make-sysroot.sh $(SCRIPTDIR)/make-devices.pl $(DEMO_SYSROOTDIR) $(DEMO_SYSROOT_CPIO)
	$(Q) xz --compress --force --check=crc32 --stdout -8 $(DEMO_SYSROOT_CPIO) > $@

$(DEMO_UIMAGE_COMPLETE_STAMP): $(KERNEL_INSTALL_STAMP) $(DEMO_SYSROOT_CPIO_XZ)
	$(Q) echo "==== Create demo $(MACHINE_PREFIX) u-boot multi-file initramfs itb ===="
	$(Q) cd $(IMAGEDIR) && \
		V=$(V) $(SCRIPTDIR)/onie-mk-itb.sh $(MACHINE) $(MACHINE_PREFIX) $(UBOOT_ITB_ARCH) \
		$(KERNEL_VMLINUZ) $(IMAGEDIR)/$(MACHINE_PREFIX).dtb $(DEMO_SYSROOT_CPIO_XZ) $(DEMO_UIMAGE)
	$(Q) touch $@

$(DEMO_KERNEL_COMPLETE_STAMP): $(KERNEL_INSTALL_STAMP)
	$(Q) cd $$(dirname $(DEMO_KERNEL_VMLINUZ)) && \
		ln -sf $(KERNEL_VMLINUZ) $$(basename $(DEMO_KERNEL_VMLINUZ))
	$(Q) touch $@

ifndef MAKE_CLEAN
DEMO_INSTALLER_FILES = $(shell test -d $(IMAGEDIR) && test -f $(DEMO_SYSROOT_CPIO_XZ) && \
	              find -L $(DEMO_INSTALLER_DIR) -mindepth 1 -cnewer $(DEMO_OS_BIN) \
			-type f -print -quit 2>/dev/null)
  ifneq ($(strip $(DEMO_INSTALLER_FILES)),)
    $(shell rm -f $(DEMO_IMAGE_COMPLETE_STAMP) $(DEMO_OS_BIN) $(DEMO_DIAG_BIN))
  endif
endif

define demo_MKIMAGE
	./scripts/onie-mk-demo.sh $(ONIE_ARCH) $(MACHINE) $(PLATFORM) \
		$(DEMO_INSTALLER_DIR) $(MACHINEDIR)/demo/platform.conf $(1) $(2) $(DEMO_IMAGE_PARTS) 
endef

$(DEMO_OS_BIN) : $(DEMO_IMAGE_PARTS_COMPLETE) $(MACHINE_DEMO_DIR)/*
	$(Q) echo "==== Create demo OS $(PLATFORM) self-extracting archive ===="
	$(Q) $(call demo_MKIMAGE, $@, OS)

$(DEMO_DIAG_BIN) : $(DEMO_OS_BIN)
	$(Q) echo "==== Create demo DIAG $(PLATFORM) self-extracting archive ===="
	$(Q) $(call demo_MKIMAGE, $@, DIAG)

PHONY += demo-image-complete
demo-image-complete: $(DEMO_IMAGE_COMPLETE_STAMP)
$(DEMO_IMAGE_COMPLETE_STAMP): $(DEMO_ARCH_BINS)
	$(Q) touch $@

CLEAN += demo-clean
demo-clean:
	$(Q) rm -rf $(DEMO_SYSROOTDIR)
	$(Q) rm -f $(MBUILDDIR)/demo-* $(DEMO_IMAGE_PARTS) $(DEMO_OS_BIN) $(DEMO_DIAG_BIN)
	$(Q) rm -f $(DEMO_SYSROOT_COMPLETE_STAMP) $(DEMO_IMAGE_COMPLETE_STAMP)
	$(Q) rm -f $(DEMO_IMAGE_PARTS_COMPLETE)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
