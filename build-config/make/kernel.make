#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the build of the onie cross-compiled linux kernel
#

LINUX_VERSION		= 3.2
LINUX_SUBVERSION	= $(LINUX_VERSION).35
LINUX_TARBALL		= linux-$(LINUX_SUBVERSION).tar.xz
LINUX_TARBALL_SHA256	= sha256sums.asc
LINUX_TARBALL_URLS	= https://www.kernel.org/pub/linux/kernel/v3.x

#-------------------------------------------------------------------------------

LINUX_CONFIG 		= conf/linux.powerpc-e500.config
KERNELDIR   		= $(MBUILDDIR)/kernel
LINUXDIR   		= $(KERNELDIR)/linux
KERNEL_HEADERS 		= $(LINUXDIR)/usr/include

KERNEL_SRCPATCHDIR	= $(PATCHDIR)/kernel
KERNEL_PATCHDIR		= $(KERNELDIR)/patch
KERNEL_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/kernel-download
KERNEL_SOURCE_STAMP	= $(STAMPDIR)/kernel-source
KERNEL_PATCH_STAMP	= $(STAMPDIR)/kernel-patch
KERNEL_BUILD_STAMP	= $(STAMPDIR)/kernel-build
KERNEL_HEADER_STAMP	= $(STAMPDIR)/kernel-header
KERNEL_INSTALL_STAMP	= $(STAMPDIR)/kernel-install
KERNEL_STAMP		= $(KERNEL_DOWNLOAD_STAMP) \
			  $(KERNEL_SOURCE_STAMP) \
			  $(KERNEL_PATCH_STAMP) \
			  $(KERNEL_BUILD_STAMP) \
			  $(KERNEL_HEADER_STAMP) \
			  $(KERNEL_INSTALL_STAMP)

KERNEL			= $(KERNEL_STAMP)

KERNEL_DTB		?= $(MACHINE).dtb

PHONY += kernel kernel-download kernel-source kernel-patch kernel-config
PHONY += kernel-build kernel-install kernel-clean kernel-download-clean

#-------------------------------------------------------------------------------

LINUX_BOOTDIR   = $(LINUXDIR)/arch/$(ARCH)/boot

#-------------------------------------------------------------------------------

kernel: $(KERNEL_STAMP)

#---

DOWNLOAD += $(KERNEL_DOWNLOAD_STAMP)
kernel-download: $(KERNEL_DOWNLOAD_STAMP)
$(KERNEL_DOWNLOAD_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting Linux ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(LINUX_TARBALL) $(LINUX_TARBALL_URLS)
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(LINUX_TARBALL_SHA256) $(LINUX_TARBALL_URLS)
	$(Q) cd $(DOWNLOADDIR) && grep $(LINUX_TARBALL) $(LINUX_TARBALL_SHA256) | sha256sum -c -
	$(Q) touch $@

SOURCE += $(KERNEL_PATCH_STAMP)
kernel-source: $(KERNEL_SOURCE_STAMP)
$(KERNEL_SOURCE_STAMP): $(KERNEL_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting Linux ===="
	$(Q) $(SCRIPTDIR)/extract-package $(KERNELDIR) $(DOWNLOADDIR)/$(LINUX_TARBALL)
	$(Q) cd $(KERNELDIR) && ln -s linux-$(LINUX_SUBVERSION) linux
	$(Q) touch $@

#
# The kernel patches are made up of a base set of platform independent
# patches with the current machine's platform dependent patches on
# top.
#
kernel-patch: $(KERNEL_PATCH_STAMP)
$(KERNEL_PATCH_STAMP): $(KERNEL_SRCPATCHDIR)/* $(MACHINEDIR)/kernel/* $(KERNEL_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== patching  Linux ===="
	$(Q) [ -r $(MACHINEDIR)/kernel/series ] || \
		(echo "Unable to find machine dependent kernel patch series: $(MACHINEDIR)/kernel/series" && \
		exit 1)
	$(Q) mkdir -p $(KERNEL_PATCHDIR)
	$(Q) cp $(KERNEL_SRCPATCHDIR)/* $(KERNEL_PATCHDIR)
	$(Q) cat $(MACHINEDIR)/kernel/series >> $(KERNEL_PATCHDIR)/series
	$(Q) $(SCRIPTDIR)/cp-machine-patches $(KERNEL_PATCHDIR) $(MACHINEDIR)/kernel/series	\
		$(MACHINEDIR)/kernel $(MACHINEROOT)/kernel
	$(Q) $(SCRIPTDIR)/apply-patch-series $(KERNEL_PATCHDIR)/series $(LINUXDIR)
	$(Q) touch $@

$(LINUXDIR)/.config : $(LINUX_CONFIG) $(KERNEL_PATCH_STAMP)
	$(Q) echo "==== Copying $(LINUX_CONFIG) to $(LINUXDIR)/.config ===="
	$(Q) cp -v $< $@
	$(Q) cat $(MACHINEDIR)/kernel/config >> $(LINUXDIR)/.config

kernel-old-config: $(LINUXDIR)/.config
	$(Q) $(MAKE) -C $(LINUXDIR) ARCH=$(ARCH) oldconfig

kernel-config: $(LINUXDIR)/.config
	$(Q) $(MAKE) -C $(LINUXDIR) ARCH=$(ARCH) menuconfig

ifndef MAKE_CLEAN
LINUX_NEW_FILES	= \
	$(shell test -d $(LINUXDIR) && test -f $(KERNEL_INSTALL_STAMP) && \
	  find -L $(LINUXDIR) -mindepth 1 -newer $(KERNEL_INSTALL_STAMP) \
	    -type f -print -quit 2>/dev/null)
endif

kernel-header: $(KERNEL_HEADER_STAMP)
$(KERNEL_HEADER_STAMP): $(KERNEL_SOURCE_STAMP) $(LINUX_NEW_FILES) $(LINUXDIR)/.config
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing Kernel headers ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE) -C $(LINUXDIR)		\
		ARCH=$(ARCH)			\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		V=$(V) 				\
		headers_install
	$(Q) touch $@

kernel-build: $(KERNEL_BUILD_STAMP)
$(KERNEL_BUILD_STAMP): $(KERNEL_HEADER_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Building cross linux ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE) -C $(LINUXDIR)		\
		ARCH=$(ARCH)			\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		V=$(V) 				\
		all
	$(Q) PATH='$(CROSSBIN):$(PATH)' 	\
	    $(MAKE) -C $(LINUXDIR)		\
		ARCH=$(ARCH)			\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		V=$(V) 				\
		uImage $(KERNEL_DTB)
	$(Q) touch $@

kernel-install: $(KERNEL_INSTALL_STAMP)
$(KERNEL_INSTALL_STAMP): $(KERNEL_BUILD_STAMP) $(KERNEL_HEADER_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Copy device tree blob to $(IMAGEDIR) ===="
	$(Q) cp -vf $(LINUX_BOOTDIR)/$(KERNEL_DTB) $(IMAGEDIR)/$(MACHINE_PREFIX).dtb
	$(Q) touch $@

CLEAN += kernel-clean
kernel-clean:
	$(Q) rm -rf $(KERNELDIR)
	$(Q) rm -f $(KERNEL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += kernel-download-clean
kernel-download-clean:
	$(Q) rm -f $(KERNEL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LINUX_TARBALL) \
		   $(DOWNLOADDIR)/$(LINUX_TARBALL_SHA256)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
