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

FLASHROM_VERSION		= 0.9.8
FLASHROM_TARBALL		= flashrom-$(FLASHROM_VERSION).tar.bz2
FLASHROM_TARBALL_URLS		+= $(ONIE_MIRROR) http://download.flashrom.org/releases/
FLASHROM_BUILD_DIR		= $(USER_BUILDDIR)/flashrom
FLASHROM_DIR			= $(FLASHROM_BUILD_DIR)/flashrom-$(FLASHROM_VERSION)

FLASHROM_SRCPATCHDIR		= $(PATCHDIR)/flashrom
FLASHROM_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/flashrom-download
FLASHROM_SOURCE_STAMP		= $(USER_STAMPDIR)/flashrom-source
FLASHROM_PATCH_STAMP		= $(USER_STAMPDIR)/flashrom-patch
FLASHROM_BUILD_STAMP		= $(USER_STAMPDIR)/flashrom-build
FLASHROM_INSTALL_STAMP		= $(STAMPDIR)/flashrom-install
FLASHROM_STAMP			= $(FLASHROM_SOURCE_STAMP) \
				  $(FLASHROM_PATCH_STAMP) \
				  $(FLASHROM_BUILD_STAMP) \
				  $(FLASHROM_INSTALL_STAMP)

FLASHROM_PROGRAMS		= flashrom

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

# Disable all flashrom methods, except for 'internal' by default.
# Individual platforms can define FLASHROM_MAKE_CONFIG_PLATFORM to
# enable support for specific flashing methods, for example:
#
#   FLASHROM_MAKE_CONFIG_PLATFORM = CONFIG_XYZ=yes
#
# See the Makefile in the flashrom source directory for the complete
# list of CONFIG_XYZ variables.
#
# Note: Leaving the Intel NIC EEPROMs enabled, as that could be useful
# in manufacturing to program the MAC address for eth0.
FLASHROM_MAKE_CONFIG = \
	CC=$(CROSSPREFIX)gcc CFLAGS="-Wall -Wshadow $(ONIE_CFLAGS)" \
	LDFLAGS="$(ONIE_LDFLAGS)" \
	PREFIX=/usr DESTDIR=$(DEV_SYSROOT) \
	CONFIG_SERPROG=no CONFIG_RAYER_SPI=no CONFIG_PONY_SPI=no \
	CONFIG_NIC3COM=no CONFIG_GFXNVIDIA=no CONFIG_SATASII=no \
	CONFIG_ATAHPT=no CONFIG_ATAVIA=no CONFIG_FT2232_SPI=no \
	CONFIG_USBBLASTER_SPI=no CONFIG_MSTARDDC_SPI=no CONFIG_PICKIT2_SPI=no \
	CONFIG_DRKAISER=no CONFIG_NICREALTEK=no CONFIG_NICNATSEMI=no \
	CONFIG_OGP_SPI=no CONFIG_BUSPIRATE_SPI=no CONFIG_DEDIPROG=no \
	CONFIG_SATAMV=no CONFIG_IT8212=no CONFIG_PRINT_WIKI=no \
	$(FLASHROM_MAKE_CONFIG_PLATFORM)

flashrom-build: $(FLASHROM_BUILD_STAMP)
$(FLASHROM_BUILD_STAMP): $(FLASHROM_SOURCE_STAMP) $(PCIUTILS_BUILD_STAMP) \
				| $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building flashrom-$(FLASHROM_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(FLASHROM_DIR) \
		$(FLASHROM_MAKE_CONFIG) all
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(FLASHROM_DIR) \
		$(FLASHROM_MAKE_CONFIG) install
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
