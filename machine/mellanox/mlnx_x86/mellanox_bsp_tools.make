#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of Mellanox bsp tools
#

MELLANOX_BSP_TOOLS_BUILD_DIR		= $(MBUILDDIR)/mellanox_bsp_tools
MELLANOX_BSP_TOOLS_SOURCE_DIR		= $(MACHINEDIR)/mellanox_bsp_tools/bios
MELLANOX_BSP_TOOLS_DIR			= $(MELLANOX_BSP_TOOLS_BUILD_DIR)
MELLANOX_BSP_TOOLS_INSTALL_STAMP	= $(STAMPDIR)/mellanox_bsp_tools-install
MELLANOX_BSP_TOOLS_STAMP		= \
				  $(MELLANOX_BSP_TOOLS_INSTALL_STAMP)

PHONY += mellanox_bsp_tools \
	 mellanox_bsp_tools-install mellanox_bsp_tools-clean

mellanox_bsp_tools: $(MELLANOX_BSP_TOOLS_STAMP)

$(MELLANOX_BSP_TOOLS_DIR):
	mkdir -p $@

ifndef MAKE_CLEAN
MELLANOX_BSP_TOOLS_NEW_FILES = $(shell test -d $(MELLANOX_BSP_TOOLS_DIR) && test -f $(MELLANOX_BSP_TOOLS_BUILD_STAMP) && \
	              find -L $(MELLANOX_BSP_TOOLS_DIR) -newer $(MELLANOX_BSP_TOOLS_BUILD_STAMP) -type f \
			\! -name symlinks \! -name symlinks.o -print -quit)
endif

mellanox_bsp_tools-install: $(MELLANOX_BSP_TOOLS_INSTALL_STAMP)
$(MELLANOX_BSP_TOOLS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(DEV_SYSROOT_INIT_STAMP) $(MELLANOX_BSP_TOOLS_KERNEL_INSTALL_STAMP)
	$(Q) echo "==== Installing mellanox_bsp_tools in $(SYSROOTDIR) ===="
	$(Q) cp -v $(MELLANOX_BSP_TOOLS_SOURCE_DIR)/* $(SYSROOTDIR)/usr/bin
	$(Q) touch $@

USERSPACE_CLEAN += mellanox_bsp_tools-clean
mellanox_bsp_tools-clean:
	$(Q) rm -rf $(MELLANOX_BSP_TOOLS_BUILD_DIR)
	$(Q) rm -f $(MELLANOX_BSP_TOOLS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

PACKAGES_INSTALL_STAMPS += $(MELLANOX_BSP_TOOLS_INSTALL_STAMP)
#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
