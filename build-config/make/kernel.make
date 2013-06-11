#-------------------------------------------------------------------------------
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the build of the onie cross-compiled linux kernel
#

LINUX_VERSION		= 3.2
LINUX_SUBVERSION	= $(LINUX_VERSION).35
LINUX_TARBALL		= $(UPSTREAMDIR)/linux-$(LINUX_SUBVERSION).tar.xz
#-------------------------------------------------------------------------------

LINUX_CONFIG 		= conf/linux.powerpc-e500.config
KERNELDIR   		= $(MBUILDDIR)/kernel
LINUXDIR   		= $(KERNELDIR)/linux
KERNEL_HEADERS 		= $(LINUXDIR)/usr/include

KERNEL_SRCPATCHDIR	= $(PATCHDIR)/kernel
KERNEL_PATCHDIR		= $(KERNELDIR)/patch
KERNEL_SOURCE_STAMP	= $(STAMPDIR)/kernel-source
KERNEL_PATCH_STAMP	= $(STAMPDIR)/kernel-patch
KERNEL_BUILD_STAMP	= $(STAMPDIR)/kernel-build
KERNEL_HEADER_STAMP	= $(STAMPDIR)/kernel-header
KERNEL_INSTALL_STAMP	= $(STAMPDIR)/kernel-install
KERNEL_STAMP		= $(KERNEL_SOURCE_STAMP) \
			  $(KERNEL_PATCH_STAMP) \
			  $(KERNEL_BUILD_STAMP) \
			  $(KERNEL_HEADER_STAMP) \
			  $(KERNEL_INSTALL_STAMP)

KERNEL			= $(KERNEL_STAMP)

PHONY += kernel kernel-source kernel-patch kernel-config 
PHONY += kernel-build kernel-install kernel-clean

#-------------------------------------------------------------------------------

LINUX_BOOTDIR   = $(LINUXDIR)/arch/$(ARCH)/boot

#-------------------------------------------------------------------------------

kernel: $(KERNEL_STAMP)

#---

SOURCE += $(KERNEL_PATCH_STAMP)

kernel-source: $(KERNEL_SOURCE_STAMP)
$(KERNEL_SOURCE_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting and extracting Linux ===="
	$(Q) cd $(UPSTREAMDIR) && sha1sum -c $(LINUX_TARBALL).sha1
	$(Q) rm -rf $(KERNELDIR)
	$(Q) mkdir -p $(KERNELDIR)
	$(Q) cd $(KERNELDIR) && tar xJf $(LINUX_TARBALL)
	$(Q) ln -s $(KERNELDIR)/linux-$(LINUX_SUBVERSION)/ $(LINUXDIR)
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
	$(Q) cp $(MACHINEDIR)/kernel/*.patch $(KERNEL_PATCHDIR)
	$(Q) cat $(MACHINEDIR)/kernel/series >> $(KERNEL_PATCHDIR)/series
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
		uImage $(MACHINE).dtb
	$(Q) touch $@

kernel-install: $(KERNEL_INSTALL_STAMP)
$(KERNEL_INSTALL_STAMP): $(KERNEL_BUILD_STAMP) $(KERNEL_HEADER_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Copy device tree blob to $(IMAGEDIR) ===="
	$(Q) cp -vf $(LINUX_BOOTDIR)/$(MACHINE).dtb $(IMAGEDIR)/$(MACHINE).dtb
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
