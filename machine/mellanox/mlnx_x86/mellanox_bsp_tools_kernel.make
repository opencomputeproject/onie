#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of Mellanox bsp tools
#

MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR		= $(MBUILDDIR)/mellanox_bsp_tools_kernel
MELLANOX_BSP_TOOLS_KERNEL_SOURCE_DIR		= $(MACHINEDIR)/mellanox_bsp_tools/kernel_level
MELLANOX_BSP_TOOLS_KERNEL_DIR			= $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR)

MELLANOX_BSP_TOOLS_KERNEL_CONFIGURE_STAMP	= $(STAMPDIR)/mellanox_bsp_tools_kernel-configure
MELLANOX_BSP_TOOLS_KERNEL_BUILD_STAMP		= $(STAMPDIR)/mellanox_bsp_tools_kernel-build
MELLANOX_BSP_TOOLS_KERNEL_INSTALL_STAMP	= $(STAMPDIR)/mellanox_bsp_tools_kernel-install
MELLANOX_KERNEL_MODULES_INSTALL_STAMP	= $(STAMPDIR)/mellanox_kernel-modules-install
MELLANOX_BSP_TOOLS_KERNEL_STAMP		= \
				  $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_STAMP) \
				  $(MELLANOX_BSP_TOOLS_KERNEL_INSTALL_STAMP) \
				  $(MELLANOX_KERNEL_MODULES_INSTALL_STAMP)

PHONY += mellanox_bsp_tools_kernel mellanox_bsp_tools_kernel-download mellanox_bsp_tools_kernel-source mellanox_bsp_tools_kernel-patch \
	 mellanox_bsp_tools_kernel-configure mellanox_bsp_tools_kernel-build mellanox_bsp_tools_kernel-install mellanox_bsp_tools_kernel-clean \
	 mellanox_bsp_tools_kernel-download-clean

all: mellanox_bsp_tools_kernel

mellanox_bsp_tools_kernel: $(MELLANOX_BSP_TOOLS_KERNEL_STAMP)

ifndef MAKE_CLEAN
MELLANOX_BSP_TOOLS_KERNEL_NEW_FILES = $(shell test -d $(MELLANOX_BSP_TOOLS_KERNEL_DIR) && test -f $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_STAMP) && \
	              find -L $(MELLANOX_BSP_TOOLS_KERNEL_DIR) -newer $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_STAMP) -type f \
			\! -name symlinks \! -name symlinks.o -print -quit)
endif

$(MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR): $(MELLANOX_BSP_TOOLS_KERNEL_SOURCE_DIR)
	rm -rf $@
	mkdir -p $(@D)
	cp -R $(MELLANOX_BSP_TOOLS_KERNEL_SOURCE_DIR) $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR)

mellanox_bsp_tools_kernel-build: $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_STAMP)
$(MELLANOX_BSP_TOOLS_KERNEL_BUILD_STAMP): $(MELLANOX_BSP_TOOLS_KERNEL_NEW_FILES) $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR) $(DEV_SYSROOT_INIT_STAMP) kernel
	$(Q) echo "====  Building mellanox_bsp_tools_kernel-$(MELLANOX_BSP_TOOLS_KERNEL_VERSION) ===="
	$(Q) cd $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR) &&	\
	    PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE)				\
		V=$(V) 				\
		-f Makefile.wrapper		\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		MLNX_BSP_KSRCS=$(LINUXDIR)	\
		all
	$(Q) touch $@


mellanox_bsp_tools_kernel-install: $(MELLANOX_BSP_TOOLS_KERNEL_INSTALL_STAMP)
$(MELLANOX_BSP_TOOLS_KERNEL_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_STAMP) $(SYSROOT_INIT_STAMP) kernel $(MELLANOX_KERNEL_MODULES_INSTALL_STAMP)
	$(Q) echo "==== Installing mellanox_bsp_tools_kernel in $(DEV_SYSROOT) ===="
	$(Q) cd $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR) &&	\
	    PATH='$(CROSSBIN):$(PATH)'		\
	    $(MAKE)				\
		V=$(V) 				\
		-f Makefile.wrapper		\
		CROSS_COMPILE=$(CROSSPREFIX)	\
		MLNX_BSP_KSRCS=$(LINUXDIR)	\
		INSTALL_MOD_PATH=$(SYSROOTDIR)  \
		DESTDIR=$(SYSROOTDIR)		\
		install
	$(Q) touch $@

mellanox-kernel-modules-install: $(MELLANOX_KERNEL_MODULES_INSTALL_STAMP)
$(MELLANOX_KERNEL_MODULES_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) kernel
	$(Q) PATH='$(CROSSBIN):$(PATH)'         \
	    $(MAKE) -C $(LINUXDIR)              \
	        ARCH=$(KERNEL_ARCH)             \
	        CROSS_COMPILE=$(CROSSPREFIX)    \
	        V=$(V)                          \
	        headers_install                 \
	        INSTALL_HDR_PATH=$(SYSROOTDIR)/usr
	$(Q) PATH='$(CROSSBIN):$(PATH)'         \
	    $(MAKE) -C $(LINUXDIR)              \
	        INSTALL_MOD_PATH=$(SYSROOTDIR)  \
	        ARCH=$(KERNEL_ARCH)             \
	        V=$(V)                          \
	        modules_install
	$(Q) touch $@

USERSPACE_CLEAN += mellanox_bsp_tools_kernel-clean
mellanox_bsp_tools_kernel-clean:
	$(Q) rm -rf $(MELLANOX_BSP_TOOLS_KERNEL_BUILD_DIR)
	$(Q) rm -f $(MELLANOX_BSP_TOOLS_KERNEL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
