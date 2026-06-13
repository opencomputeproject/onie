#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of flashrom
#

FLASHROM_VERSION		= 1.7.0
FLASHROM_TARBALL		= flashrom-v$(FLASHROM_VERSION).tar.xz
FLASHROM_TARBALL_URLS		+= $(ONIE_MIRROR) https://download.flashrom.org/releases/
FLASHROM_BUILD_DIR		= $(USER_BUILDDIR)/flashrom
FLASHROM_DIR			= $(FLASHROM_BUILD_DIR)/flashrom-v$(FLASHROM_VERSION)
FLASHROM_MESON_BUILD		= $(FLASHROM_DIR)/onie-build
FLASHROM_CROSS_FILE		= $(FLASHROM_DIR)/onie-cross.ini

FLASHROM_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/flashrom-download
FLASHROM_SOURCE_STAMP		= $(USER_STAMPDIR)/flashrom-source
FLASHROM_BUILD_STAMP		= $(USER_STAMPDIR)/flashrom-build
FLASHROM_INSTALL_STAMP		= $(STAMPDIR)/flashrom-install
FLASHROM_STAMP			= $(FLASHROM_SOURCE_STAMP) \
				  $(FLASHROM_BUILD_STAMP) \
				  $(FLASHROM_INSTALL_STAMP)

FLASHROM_PROGRAMS		= flashrom

# flashrom 1.x builds with meson/ninja (the old Makefile was dropped after
# 0.9.x).  Select the programmers ONIE needs: 'internal' for on-board chipset
# flashing and 'nicintel_eeprom' to program the Intel NIC EEPROM (useful in
# manufacturing to set the eth0 MAC).  Both rely only on libpci, so no extra
# USB/FTDI/serial dependencies are pulled in.  A platform can override this to
# enable additional programmers.
FLASHROM_PROGRAMMERS		?= internal,nicintel_eeprom

PHONY += flashrom flashrom-download flashrom-source flashrom-build \
	 flashrom-install flashrom-clean flashrom-download-clean

flashrom: $(FLASHROM_STAMP)

DOWNLOAD += $(FLASHROM_DOWNLOAD_STAMP)
flashrom-download: $(FLASHROM_DOWNLOAD_STAMP)
$(FLASHROM_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream flashrom ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(FLASHROM_TARBALL) $(FLASHROM_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(FLASHROM_SOURCE_STAMP)
flashrom-source: $(FLASHROM_SOURCE_STAMP)
$(FLASHROM_SOURCE_STAMP): $(USER_TREE_STAMP) $(FLASHROM_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream flashrom ===="
	$(Q) $(SCRIPTDIR)/extract-package $(FLASHROM_BUILD_DIR) $(DOWNLOADDIR)/$(FLASHROM_TARBALL)
	$(Q) touch $@

flashrom-build: $(FLASHROM_BUILD_STAMP)
$(FLASHROM_BUILD_STAMP): $(FLASHROM_SOURCE_STAMP) $(PCIUTILS_BUILD_STAMP) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building flashrom-$(FLASHROM_VERSION) ===="
	# Generate a meson cross file describing the ONIE cross toolchain.
	# flashrom is only enabled for x86_64 (see arch/x86_64.make).
	$(Q) { \
		echo "[binaries]" ; \
		echo "c = '$(CROSSPREFIX)gcc'" ; \
		echo "ar = '$(CROSSPREFIX)ar'" ; \
		echo "strip = '$(CROSSPREFIX)strip'" ; \
		echo "pkgconfig = 'pkg-config'" ; \
		echo "" ; \
		echo "[host_machine]" ; \
		echo "system = 'linux'" ; \
		echo "cpu_family = 'x86_64'" ; \
		echo "cpu = 'x86_64'" ; \
		echo "endian = 'little'" ; \
		echo "" ; \
		echo "[properties]" ; \
		echo "sys_root = '$(DEV_SYSROOT)'" ; \
		echo "" ; \
		echo "[built-in options]" ; \
		echo "c_args = ['-Os']" ; \
		echo "c_link_args = ['--sysroot=$(DEV_SYSROOT)']" ; \
	} > $(FLASHROM_CROSS_FILE)
	$(Q) rm -rf $(FLASHROM_MESON_BUILD)
	$(Q) cd $(FLASHROM_DIR) && PATH='$(CROSSBIN):$(PATH)' $(ONIE_PKG_CONFIG) \
		meson setup --cross-file $(FLASHROM_CROSS_FILE) --prefix=/usr \
			-Dprogrammer=$(FLASHROM_PROGRAMMERS) \
			-Dclassic_cli=enabled \
			-Dtests=disabled \
			-Dman-pages=disabled \
			-Ddocumentation=disabled \
			-Dich_descriptors_tool=disabled \
			-Dbash_completion=disabled \
			-Duse_git_version=disabled \
			onie-build
	$(Q) PATH='$(CROSSBIN):$(PATH)' ninja -C $(FLASHROM_MESON_BUILD)
	$(Q) PATH='$(CROSSBIN):$(PATH)' DESTDIR=$(DEV_SYSROOT) \
		ninja -C $(FLASHROM_MESON_BUILD) install
	$(Q) touch $@

flashrom-install: $(FLASHROM_INSTALL_STAMP)
$(FLASHROM_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(FLASHROM_BUILD_STAMP) $(PCIUTILS_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing flashrom programs in $(SYSROOTDIR) ===="
	$(Q) for file in $(FLASHROM_PROGRAMS); do \
		cp -av $(DEV_SYSROOT)/usr/sbin/$$file $(SYSROOTDIR)/usr/sbin ; \
	     done
	$(Q) touch $@

USER_CLEAN += flashrom-clean
flashrom-clean:
	$(Q) rm -rf $(FLASHROM_BUILD_DIR)
	$(Q) rm -f $(FLASHROM_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += flashrom-download-clean
flashrom-download-clean:
	$(Q) rm -f $(FLASHROM_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(FLASHROM_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
