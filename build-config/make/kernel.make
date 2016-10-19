#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the build of the onie cross-compiled linux kernel
#

#-------------------------------------------------------------------------------

LINUX_CONFIG 		?= conf/kernel/$(LINUX_RELEASE)/linux.$(ONIE_ARCH).config
KERNELDIR   		= $(MBUILDDIR)/kernel
LINUXDIR   		= $(KERNELDIR)/linux

KERNEL_SRCPATCHDIR	= $(PATCHDIR)/kernel/$(LINUX_RELEASE)
MACHINE_KERNEL_PATCHDIR	?= $(MACHINEDIR)/kernel
KERNEL_PATCHDIR		= $(KERNELDIR)/patch

KERNEL_SOURCE_STAMP	= $(STAMPDIR)/kernel-source
KERNEL_PATCH_STAMP	= $(STAMPDIR)/kernel-patch
KERNEL_BUILD_STAMP	= $(STAMPDIR)/kernel-build
KERNEL_DTB_INSTALL_STAMP = $(STAMPDIR)/kernel-dtb-install
KERNEL_VMLINUZ_INSTALL_STAMP = $(STAMPDIR)/kernel-vmlinuz-install
KERNEL_INSTALL_STAMP	= $(STAMPDIR)/kernel-install
KERNEL_STAMP		= $(KERNEL_SOURCE_STAMP) \
			  $(KERNEL_PATCH_STAMP) \
			  $(KERNEL_BUILD_STAMP) \
			  $(KERNEL_INSTALL_STAMP)

KERNEL			= $(KERNEL_STAMP)

KERNEL_VMLINUZ		= $(IMAGEDIR)/$(MACHINE_PREFIX).vmlinuz
UPDATER_VMLINUZ		= $(MBUILDDIR)/onie.vmlinuz

PHONY += kernel kernel-source kernel-patch kernel-config
PHONY += kernel-build kernel-install kernel-clean

#-------------------------------------------------------------------------------

LINUX_BOOTDIR   = $(LINUXDIR)/arch/$(KERNEL_ARCH)/boot

#-------------------------------------------------------------------------------

kernel: $(KERNEL_STAMP)

#---

SOURCE += $(KERNEL_PATCH_STAMP)
kernel-source: $(KERNEL_SOURCE_STAMP)
$(KERNEL_SOURCE_STAMP): $(TREE_STAMP) $(KERNEL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting Linux ===="
	$(Q) $(SCRIPTDIR)/extract-package $(KERNELDIR) $(DOWNLOADDIR)/$(LINUX_TARBALL)
	$(Q) cd $(KERNELDIR) && ln -s linux-$(LINUX_RELEASE) linux
	$(Q) touch $@

#
# The kernel patches are made up of a base set of platform independent
# patches with the current machine's platform dependent patches on
# top.
#
kernel-patch: $(KERNEL_PATCH_STAMP)
$(KERNEL_PATCH_STAMP): $(KERNEL_SRCPATCHDIR)/* $(MACHINE_KERNEL_PATCHDIR)/* $(KERNEL_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== patching  Linux ===="
	$(Q) [ -r $(MACHINE_KERNEL_PATCHDIR)/series ] || \
		(echo "Unable to find machine dependent kernel patch series: $(MACHINE_KERNEL_PATCHDIR)/series" && \
		exit 1)
	$(Q) mkdir -p $(KERNEL_PATCHDIR)
	$(Q) cp $(KERNEL_SRCPATCHDIR)/* $(KERNEL_PATCHDIR)
	$(Q) cat $(MACHINE_KERNEL_PATCHDIR)/series >> $(KERNEL_PATCHDIR)/series
	$(Q) $(SCRIPTDIR)/cp-machine-patches $(KERNEL_PATCHDIR) $(MACHINE_KERNEL_PATCHDIR)/series	\
		$(MACHINE_KERNEL_PATCHDIR) $(MACHINEROOT)/kernel
	$(Q) $(SCRIPTDIR)/apply-patch-series $(KERNEL_PATCHDIR)/series $(LINUXDIR)
	$(Q) touch $@

$(LINUXDIR)/.config : $(LINUX_CONFIG) $(KERNEL_PATCH_STAMP)
	$(Q) echo "==== Copying $(LINUX_CONFIG) to $(LINUXDIR)/.config ===="
	$(Q) cp -v $< $@
	$(Q) cat $(MACHINE_KERNEL_PATCHDIR)/config >> $(LINUXDIR)/.config

kernel-old-config: $(LINUXDIR)/.config
	$(Q) $(MAKE) -C $(LINUXDIR) ARCH=$(KERNEL_ARCH) oldconfig

kernel-config: $(LINUXDIR)/.config
	$(Q) $(MAKE) -C $(LINUXDIR) ARCH=$(KERNEL_ARCH) menuconfig

ifndef MAKE_CLEAN
LINUX_NEW_FILES	= \
	$(shell test -d $(LINUXDIR) && test -f $(KERNEL_INSTALL_STAMP) && \
	  find -L $(LINUXDIR) -mindepth 1 -newer $(KERNEL_INSTALL_STAMP) \
	    -type f -print -quit 2>/dev/null)
endif

kernel-build: $(KERNEL_BUILD_STAMP)
$(KERNEL_BUILD_STAMP): $(KERNEL_SOURCE_STAMP) $(LINUX_NEW_FILES) $(LINUXDIR)/.config | $(XTOOLS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Building cross linux ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE) -C $(LINUXDIR)		\
		ARCH=$(KERNEL_ARCH)		\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		V=$(V) 				\
		all
	$(Q) touch $@

kernel-dtb-install: $(KERNEL_DTB_INSTALL_STAMP)
$(KERNEL_DTB_INSTALL_STAMP): $(KERNEL_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Building device tree blob for $(PLATFORM) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE) -C $(LINUXDIR)		\
		ARCH=$(KERNEL_ARCH)		\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		V=$(V) 				\
		$(KERNEL_DTB)
	$(Q) echo "==== Copy device tree blob to $(IMAGEDIR) ===="
	$(Q) cp -vf $(LINUX_BOOTDIR)/$(KERNEL_DTB_PATH) $(IMAGEDIR)/$(MACHINE_PREFIX).dtb
	$(Q) touch $@

kernel-vmlinuz-install: $(KERNEL_VMLINUZ_INSTALL_STAMP)
$(KERNEL_VMLINUZ_INSTALL_STAMP): $(KERNEL_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Copy vmlinuz to $(IMAGEDIR) ===="
	$(Q) cp -vf $(KERNEL_IMAGE_FILE) $(KERNEL_VMLINUZ)
	$(Q) ln -sf $(KERNEL_VMLINUZ) $(UPDATER_VMLINUZ)
	$(Q) touch $@

kernel-install: $(KERNEL_INSTALL_STAMP)
$(KERNEL_INSTALL_STAMP): $(KERNEL_INSTALL_DEPS) $(KERNEL_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) touch $@

CLEAN += kernel-clean
kernel-clean:
	$(Q) rm -rf $(KERNELDIR)
	$(Q) rm -f $(KERNEL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
