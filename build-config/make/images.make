#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the creation of onie images
#

ROOTCONFDIR		= $(CONFDIR)
SYSROOT_CPIO		= $(MBUILDDIR)/sysroot.cpio
SYSROOT_CPIO_XZ		= $(IMAGEDIR)/$(MACHINE_PREFIX).initrd
UIMAGE			= $(IMAGEDIR)/$(MACHINE_PREFIX).uImage
ITB_IMAGE		= $(IMAGEDIR)/$(MACHINE_PREFIX).itb

UPDATER_ITB		= $(MBUILDDIR)/onie.itb
UPDATER_INITRD		= $(MBUILDDIR)/onie.initrd
UPDATER_ONIE_TOOLS	= $(MBUILDDIR)/onie-tools.tar.xz

UPDATER_IMAGE		= $(IMAGEDIR)/onie-updater-$(ARCH)-$(MACHINE_PREFIX)

ONIE_TOOLS_LIST = \
	lib/onie \
	bin/onie-boot-mode

IMAGE_BIN_STAMP		= $(STAMPDIR)/image-bin
IMAGE_UPDATER_STAMP	= $(STAMPDIR)/image-updater
IMAGE_COMPLETE_STAMP	= $(STAMPDIR)/image-complete
IMAGE			= $(IMAGE_COMPLETE_STAMP)

LSB_RELEASE_FILE = $(MBUILDDIR)/lsb-release
OS_RELEASE_FILE	 = $(MBUILDDIR)/os-release
MACHINE_CONF	 = $(MBUILDDIR)/machine.conf
RC_LOCAL	 = $(abspath $(MACHINEDIR)/rc.local)

INSTALLER_DIR	= $(abspath ../installer)

# List the packages to install
PACKAGES_INSTALL_STAMPS = \
	$(ZLIB_INSTALL_STAMP) \
	$(BUSYBOX_INSTALL_STAMP) \
	$(MTDUTILS_INSTALL_STAMP) \
	$(DROPBEAR_INSTALL_STAMP) \
	$(I2CTOOLS_INSTALL_STAMP) \
	$(LVM2_INSTALL_STAMP) \
	$(DMIDECODE_INSTALL_STAMP) \
	$(ETHTOOL_INSTALL_STAMP)

ifeq ($(GPT_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(GPTFDISK_INSTALL_STAMP)
endif

ifeq ($(PARTED_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(PARTED_INSTALL_STAMP)
endif

ifeq ($(GRUB_ENABLE),yes)
  PACKAGES_INSTALL_STAMPS += $(GRUB_INSTALL_STAMP)
endif

ifndef MAKE_CLEAN
SYSROOT_NEW_FILES = $(shell \
			test -d $(ROOTCONFDIR)/default && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(ROOTCONFDIR)/default -mindepth 1 -cnewer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
SYSROOT_NEW_FILES += $(shell \
			test -d $(ROOTCONFDIR)/$(ONIE_ARCH) && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(ROOTCONFDIR)/$(ONIE_ARCH) -mindepth 1 -cnewer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
SYSROOT_NEW_FILES += $(shell \
			test -d $(MACHINEDIR)/rootconf && \
			test -f $(SYSROOT_INIT_STAMP) &&  \
			find -L $(MACHINEDIR)/rootconf -mindepth 1 -cnewer $(SYSROOT_COMPLETE_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(strip $(SYSROOT_NEW_FILES)),)
    $(shell rm -f $(SYSROOT_COMPLETE_STAMP))
  endif
  RC_LOCAL_DEP = $(shell test -r $(RC_LOCAL) && echo $(RC_LOCAL))
endif

PHONY += sysroot-check sysroot-complete

CHECKROOT	= $(MBUILDDIR)/check
CHECKDIR	= $(CHECKROOT)/checkdir
CHECKFILES	= $(CHECKROOT)/checkfiles.txt
SYSFILES	= $(CHECKROOT)/sysfiles.txt

SYSROOT_LIBS	= ld$(CLIB64)-uClibc.so.0 ld$(CLIB64)-uClibc-$(UCLIBC_VERSION).so \
		  libm.so.0 libm-$(UCLIBC_VERSION).so \
		  libgcc_s.so.1 libgcc_s.so \
		  libc.so.0 libuClibc-$(UCLIBC_VERSION).so \
		  libcrypt.so.0 libcrypt-$(UCLIBC_VERSION).so \
		  libutil.so.0 libutil-$(UCLIBC_VERSION).so

ifeq ($(EXT3_4_ENABLE),yes)
SYSROOT_LIBS	+= \
		  libdl.so.0 libdl-$(UCLIBC_VERSION).so \
		  libpthread.so.0 libpthread-$(UCLIBC_VERSION).so
endif

ifeq ($(REQUIRE_CXX_LIBS),yes)
  SYSROOT_LIBS += libstdc++.so libstdc++.so.6 libstdc++.so.6.0.17
endif

# sysroot-check does the following:
#
# - strip the ELF binaries (grub moduels and kernel)
#
# - verifies that we have all the shared libraries required by the
#   executables in our final sysroot.


sysroot-check: $(SYSROOT_CHECK_STAMP)
$(SYSROOT_CHECK_STAMP): $(PACKAGES_INSTALL_STAMPS)
	$(Q) for file in $(SYSROOT_LIBS) ; do \
		cp -av $(DEV_SYSROOT)/lib/$$file $(SYSROOTDIR)/lib/ || exit 1 ; \
	done
	$(Q) find $(SYSROOTDIR) -path */lib/grub/* -prune -o \( -type f -print0 \) | xargs -0 file | \
		grep ELF | awk -F':' '{ print $$1 }' | xargs $(CROSSBIN)/$(CROSSPREFIX)strip
	$(Q) rm -rf $(CHECKROOT)
	$(Q) mkdir -p $(CHECKROOT) && \
	     $(CROSSBIN)/$(CROSSPREFIX)populate -r $(DEV_SYSROOT) \
		-s $(SYSROOTDIR) -d $(CHECKDIR) && \
		(cd $(SYSROOTDIR) && find . > $(SYSFILES)) && \
		(cd $(CHECKDIR) && find . > $(CHECKFILES)) && \
		diff -q $(SYSFILES) $(CHECKFILES) > /dev/null 2>&1 || { \
			(echo "ERROR: Missing files in SYSROOTDIR:" && \
			 diff $(SYSFILES) $(CHECKFILES) ; \
			 false) \
		}
	$(Q) touch $@

# Setting RUNTIME_ONIE_PLATFORM and RUNTIME_ONIE_MACHINE on the
# command line allows you "fake" a real machine at runtime.  This is
# particularly useful when MACHINE is the kvm_x86_64 virtual machine.
# Using these variables you can make the running virtual machine look
# like a specific real machine.  This is useful when developing an
# installer for a particular platform.  You can develope the installer
# using the virtual machine.
RUNTIME_ONIE_MACHINE	?= $(MACHINE)
RUNTIME_ONIE_PLATFORM	?= $(ARCH)-$(RUNTIME_ONIE_MACHINE)-r$(MACHINE_REV)

sysroot-complete: $(SYSROOT_COMPLETE_STAMP)
$(SYSROOT_COMPLETE_STAMP): $(SYSROOT_CHECK_STAMP) $(RC_LOCAL_DEP)
	$(Q) rm -f $(SYSROOTDIR)/linuxrc
	$(Q) cd $(ROOTCONFDIR) && ./install default $(SYSROOTDIR)
	$(Q) if [ -d $(ROOTCONFDIR)/$(ONIE_ARCH)/sysroot-lib-onie ] ; then \
		cp $(ROOTCONFDIR)/$(ONIE_ARCH)/sysroot-lib-onie/* $(SYSROOTDIR)/lib/onie ; \
	     fi
	$(Q) if [ -d $(ROOTCONFDIR)/$(ONIE_ARCH)/sysroot-bin ] ; then	\
		cp $(ROOTCONFDIR)/$(ONIE_ARCH)/sysroot-bin/* $(SYSROOTDIR)/bin ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-lib-onie ] ; then \
		cp $(MACHINEDIR)/rootconf/sysroot-lib-onie/* $(SYSROOTDIR)/lib/onie ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-bin ] ; then \
		cp $(MACHINEDIR)/rootconf/sysroot-bin/* $(SYSROOTDIR)/bin ; \
	     fi
	$(Q) if [ -d $(MACHINEDIR)/rootconf/sysroot-etc ] ; then \
		cp $(MACHINEDIR)/rootconf/sysroot-etc/* $(SYSROOTDIR)/etc ; \
	     fi
	$(Q) cd $(SYSROOTDIR) && ln -fs sbin/init ./init
	$(Q) rm -f $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_ID=onie" >> $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_RELEASE=$(LSB_RELEASE_TAG)" >> $(LSB_RELEASE_FILE)
	$(Q) echo "DISTRIB_DESCRIPTION=Open Network Install Environment" >> $(LSB_RELEASE_FILE)
	$(Q) rm -f $(OS_RELEASE_FILE)
	$(Q) echo "NAME=\"onie\"" >> $(OS_RELEASE_FILE)
	$(Q) echo "VERSION=\"$(LSB_RELEASE_TAG)\"" >> $(OS_RELEASE_FILE)
	$(Q) echo "ID=linux" >> $(OS_RELEASE_FILE)
	$(Q) rm -f $(MACHINE_CONF)
ifdef ACCTON_REV
	$(Q) echo "onie_version=$(ACCTON_VERSION)" >> $(MACHINE_CONF)
else
	$(Q) echo "onie_version=$(LSB_RELEASE_TAG)" >> $(MACHINE_CONF)
endif
	$(Q) echo "onie_vendor_id=$(VENDOR_ID)" >> $(MACHINE_CONF)
	$(Q) echo "onie_platform=$(RUNTIME_ONIE_PLATFORM)" >> $(MACHINE_CONF)
	$(Q) echo "onie_machine=$(RUNTIME_ONIE_MACHINE)" >> $(MACHINE_CONF)
	$(Q) echo "onie_machine_rev=$(MACHINE_REV)" >> $(MACHINE_CONF)
	$(Q) echo "onie_arch=$(ARCH)" >> $(MACHINE_CONF)
	$(Q) echo "onie_config_version=$(ONIE_CONFIG_VERSION)" >> $(MACHINE_CONF)
	$(Q) echo "onie_build_date=\"$$(date -Imin)\"" >> $(MACHINE_CONF)
	$(Q) echo "onie_partition_type=$(PARTITION_TYPE)" >> $(MACHINE_CONF)
	$(Q) echo "onie_kernel_version=$(LINUX_SUBVERSION)" >> $(MACHINE_CONF)
	$(Q) cp $(LSB_RELEASE_FILE) $(SYSROOTDIR)/etc/lsb-release
	$(Q) cp $(OS_RELEASE_FILE) $(SYSROOTDIR)/etc/os-release
	$(Q) cp $(MACHINE_CONF) $(SYSROOTDIR)/etc/machine.conf
	$(Q) if [ -r $(RC_LOCAL) ] ; then \
		cp -a $(RC_LOCAL) $(SYSROOTDIR)/etc/rc.local ; \
	     fi
	$(Q) touch $@

# This step creates the cpio archive and compresses it
$(SYSROOT_CPIO_XZ) : $(SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create xz compressed sysroot for bootstrap ===="
	$(Q) fakeroot -- $(SCRIPTDIR)/make-sysroot.sh $(SCRIPTDIR)/make-devices.pl $(SYSROOTDIR) $(SYSROOT_CPIO)
	$(Q) xz --compress --force --check=crc32 --stdout -8 $(SYSROOT_CPIO) > $@

$(UPDATER_INITRD) : $(SYSROOT_CPIO_XZ)
	ln -sf $< $@

$(UPDATER_ONIE_TOOLS):  $(SYSROOT_COMPLETE_STAMP)
	$(Q) echo "==== Create ONIE Tools tarball ===="
	$(Q) tar -C $(SYSROOTDIR) -cJf $@ $(ONIE_TOOLS_LIST)

.SECONDARY: $(ITB_IMAGE)

$(IMAGEDIR)/%.itb : $(KERNEL_INSTALL_STAMP) $(SYSROOT_CPIO_XZ)
	$(Q) echo "==== Create $* u-boot multi-file .itb image ===="
	$(Q) cd $(IMAGEDIR) && $(SCRIPTDIR)/onie-mk-itb.sh $(MACHINE) \
				$(MACHINE_PREFIX) $(SYSROOT_CPIO_XZ) $@

$(UPDATER_ITB) : $(ITB_IMAGE)
	ln -sf $< $@

PHONY += image-bin
image-bin: $(IMAGE_BIN_STAMP)
$(IMAGE_BIN_STAMP): $(ITB_IMAGE) $(UBOOT_INSTALL_STAMP) $(SCRIPTDIR)/onie-mk-bin.sh
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE binary image ===="
	$(Q) $(SCRIPTDIR)/onie-mk-bin.sh $(MACHINE_PREFIX) $(IMAGEDIR) \
		$(MACHINEDIR) $(UBOOT_DIR) $(IMAGEDIR)/onie-$(MACHINE_PREFIX).bin
	$(Q) touch $@

ifndef MAKE_CLEAN
IMAGE_UPDATER_FILES = $(shell \
			test -d $(INSTALLER_DIR) && \
			find -L $(INSTALLER_DIR) -mindepth 1 -cnewer $(IMAGE_UPDATER_STAMP) \
			  -print -quit 2>/dev/null)
  ifneq ($(strip $(IMAGE_UPDATER_FILES)),)
    $(shell rm -f $(IMAGE_UPDATER_STAMP))
  endif
endif

PHONY += image-updater
image-updater: $(IMAGE_UPDATER_STAMP)
$(IMAGE_UPDATER_STAMP): $(UPDATER_IMAGE_PARTS_COMPLETE) $(SCRIPTDIR)/onie-mk-installer.sh
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE updater ===="
	$(Q) $(SCRIPTDIR)/onie-mk-installer.sh $(ONIE_ARCH) $(MACHINEDIR) \
		$(MACHINE_CONF) $(INSTALLER_DIR) \
		$(UPDATER_IMAGE) $(UPDATER_IMAGE_PARTS)
	$(Q) touch $@

PXE_EFI64_IMAGE		= $(IMAGEDIR)/onie-recovery-$(ARCH)-$(MACHINE_PREFIX).efi64.pxe
RECOVERY_ISO_IMAGE	= $(IMAGEDIR)/onie-recovery-$(ARCH)-$(MACHINE_PREFIX).iso

RECOVERY_CONF_DIR	= $(PROJECTDIR)/build-config/recovery
RECOVERY_SYSROOT	= $(MBUILDDIR)/recovery-sysroot
RECOVERY_CPIO		= $(MBUILDDIR)/recovery.cpio
RECOVERY_INITRD		= $(MBUILDDIR)/recovery.initrd
RECOVERY_ISO_SYSROOT	= $(MBUILDDIR)/recovery-sysroot-iso
PXE_EFI64_GRUB_MODS	= $(MBUILDDIR)/pxe-efi64-grub-modlist

RECOVERY_INITRD_STAMP	= $(STAMPDIR)/recovery-initrd
RECOVERY_ISO_STAMP	= $(STAMPDIR)/recovery-iso
PXE_EFI64_STAMP		= $(STAMPDIR)/pxe-efi64

RECOVERY_SYSLINUX_CFG	= $(shell if test -r $(MACHINEDIR)/recovery/syslinux.cfg; then \
			  echo $(MACHINEDIR)/recovery/syslinux.cfg; else \
			  echo $(RECOVERY_CONF_DIR)/syslinux.cfg; fi )

RECOVERY_GRUBPXE_CFG	= $(shell if test -r $(MACHINEDIR)/recovery/grub-pxe.cfg; then \
			  echo $(MACHINEDIR)/recovery/grub-pxe.cfg; else \
			  echo $(RECOVERY_CONF_DIR)/grub-pxe.cfg; fi )

PHONY += pxe-efi64 recovery-initrd recovery-iso

# Make an initrd based on the ONIE sysroot that also includes the ONIE
# updater image.
recovery-initrd: $(RECOVERY_INITRD_STAMP)
$(RECOVERY_INITRD_STAMP): $(IMAGE_UPDATER_STAMP)
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE Recovery initrd ===="
	$(Q) rm -rf $(RECOVERY_SYSROOT)
	$(Q) cp -a $(SYSROOTDIR) $(RECOVERY_SYSROOT)
	$(Q) cp $(UPDATER_IMAGE) $(RECOVERY_SYSROOT)/lib/onie/onie-updater
	$(Q) fakeroot -- $(SCRIPTDIR)/make-sysroot.sh $(SCRIPTDIR)/make-devices.pl $(RECOVERY_SYSROOT) $(RECOVERY_CPIO)
	$(Q) xz --compress --force --check=crc32 --stdout -8 $(RECOVERY_CPIO) > $(RECOVERY_INITRD)
	$(Q) touch $@

# Make hybrid .iso image containing the ONIE kernel and recovery intrd
recovery-iso: $(RECOVERY_ISO_STAMP)
$(RECOVERY_ISO_STAMP): $(RECOVERY_INITRD_STAMP) $(RECOVERY_GRUBPXE_CFG) $(RECOVERY_SYSLINUX_CFG)
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE Recovery Hybrid iso ===="
	$(Q) rm -rf $(RECOVERY_ISO_SYSROOT)
	$(Q) mkdir -p $(RECOVERY_ISO_SYSROOT)
	$(Q) cp $(UPDATER_VMLINUZ) $(RECOVERY_ISO_SYSROOT)/vmlinuz
	$(Q) cp $(RECOVERY_INITRD) $(RECOVERY_ISO_SYSROOT)/initrd.xz
	$(Q) [ -r /usr/lib/syslinux/isolinux.bin ] || {						\
		echo "ERROR:  /usr/lib/syslinux/isolinux.bin is not present";			\
		echo "ERROR:  Is the syslinux-common package installed on your build host??" ;	\
		exit 1; }
	$(Q) cp /usr/lib/syslinux/isolinux.bin $(RECOVERY_ISO_SYSROOT)
	$(Q) cp /usr/lib/syslinux/menu.c32 $(RECOVERY_ISO_SYSROOT)
	$(Q) cp $(RECOVERY_SYSLINUX_CFG) $(RECOVERY_ISO_SYSROOT)
	$(Q) mkdir -p $(RECOVERY_ISO_SYSROOT)/boot/grub
	$(Q) cat $(MACHINE_CONF) $(RECOVERY_GRUBPXE_CFG) > $(RECOVERY_ISO_SYSROOT)/boot/grub/grub.cfg
	$(Q) genisoimage -r -V "ONIE-RECOVERY" -cache-inodes -J -l -b isolinux.bin	\
		-c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table		\
		-o $(RECOVERY_ISO_IMAGE) $(RECOVERY_ISO_SYSROOT)
	$(Q) isohybrid.pl $(RECOVERY_ISO_IMAGE)
	$(Q) touch $@

# Convert the .iso to a PXE-EFI64 bootable image using GRUB
pxe-efi64: $(PXE_EFI64_STAMP)
$(PXE_EFI64_STAMP): $(GRUB_HOST_INSTALL_STAMP) $(RECOVERY_ISO_STAMP) $(RECOVERY_CONF_DIR)/grub-embed.cfg
	$(Q) echo "==== Create $(MACHINE_PREFIX) ONIE PXE EFI64 Recovery Image ===="
	$(Q) cd $(GRUB_HOST_INSTALL_DIR)/usr/lib/grub/x86_64-efi && \
		ls *.mod|sed -e 's/\.mod//g'|egrep -v '(ehci|at_keyboard)' > $(PXE_EFI64_GRUB_MODS)
	$(Q) $(GRUB_HOST_INSTALL_DIR)/usr/bin/grub-mkimage --format=x86_64-efi	\
	    --config=$(RECOVERY_CONF_DIR)/grub-embed.cfg			\
	    --directory=$(GRUB_HOST_INSTALL_DIR)/usr/lib/grub/x86_64-efi	\
	    --output=$(PXE_EFI64_IMAGE) --memdisk=$(RECOVERY_ISO_IMAGE)		\
	    $$(cat $(PXE_EFI64_GRUB_MODS))
	$(Q) touch $@

PHONY += image-complete
image-complete: $(IMAGE_COMPLETE_STAMP)
$(IMAGE_COMPLETE_STAMP): $(PLATFORM_IMAGE_COMPLETE)
	$(Q) touch $@

USERSPACE_CLEAN += image-clean
image-clean:
	$(Q) rm -f $(IMAGEDIR)/*$(MACHINE_PREFIX)* $(SYSROOT_CPIO_XZ) $(IMAGE_COMPLETE_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
