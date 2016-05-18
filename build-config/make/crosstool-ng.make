#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of crosstool-NG
#

CROSSTOOL_NG_DESC		= crosstool-NG
CROSSTOOL_NG_VERSION		?= 1.21.0
CROSSTOOL_NG_TARBALL		= crosstool-ng-$(CROSSTOOL_NG_VERSION).tar.xz
CROSSTOOL_NG_URLS		+= $(ONIE_MIRROR) https://crosstool-ng.org/download/crosstool-ng
CROSSTOOL_NG_BUILD_DIR		= $(BUILDDIR)/crosstool-ng
CROSSTOOL_NG_STAMP_DIR		= $(CROSSTOOL_NG_BUILD_DIR)/stamp
CROSSTOOL_NG_DIR		= $(CROSSTOOL_NG_BUILD_DIR)/crosstool-ng-$(CROSSTOOL_NG_VERSION)

CROSSTOOL_NG_SRCPATCHDIR	= $(PATCHDIR)/crosstool-NG/$(CROSSTOOL_NG_VERSION)
CROSSTOOL_NG_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/crosstool-ng-download
CROSSTOOL_NG_SOURCE_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-source
CROSSTOOL_NG_PATCH_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-patch
CROSSTOOL_NG_CONFIGURE_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-configure
CROSSTOOL_NG_BUILD_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-build
CROSSTOOL_NG_STAMP		= $(CROSSTOOL_NG_SOURCE_STAMP) \
				  $(CROSSTOOL_NG_PATCH_STAMP) \
				  $(CROSSTOOL_NG_CONFIGURE_STAMP) \
				  $(CROSSTOOL_NG_BUILD_STAMP) 

# Setup a mirror to use for packages needed by crosstool-NG
CROSSTOOL_ONIE_MIRROR  ?= $(ONIE_MIRROR)/crosstool-NG
export CROSSTOOL_ONIE_MIRROR

PHONY += crosstool-ng crosstool-ng-download crosstool-ng-source crosstool-ng-patch \
	 crosstool-ng-configure crosstool-ng-build crosstool-ng-clean \
	 crosstool-ng-download-clean

crosstool-ng: $(CROSSTOOL_NG_STAMP)

DOWNLOAD += $(CROSSTOOL_NG_DOWNLOAD_STAMP)
crosstool-ng-download: $(CROSSTOOL_NG_DOWNLOAD_STAMP)
$(CROSSTOOL_NG_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream $(CROSSTOOL_NG_DESC) ===="
	$(Q) if [ $(awk 'BEGIN{ print "'$(CROSSTOOL_NG_VERSION)'"<="'1.22.0'" }') -eq 1 ]; then \
			$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
			$(CROSSTOOL_NG_TARBALL) $(CROSSTOOL_NG_URLS); \
		 fi
	$(Q) touch $@

SOURCE += $(CROSSTOOL_NG_SOURCE_STAMP)
crosstool-ng-source: $(CROSSTOOL_NG_SOURCE_STAMP)
$(CROSSTOOL_NG_SOURCE_STAMP): $(CROSSTOOL_NG_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream $(CROSSTOOL_NG_DESC) ===="
	$(Q) if [ $(awk 'BEGIN{ print "'$(CROSSTOOL_NG_VERSION)'"<="'1.22.0'" }') -eq 1 ]; then \
			$(Q) $(SCRIPTDIR)/extract-package $(CROSSTOOL_NG_BUILD_DIR) \
			$(DOWNLOADDIR)/$(CROSSTOOL_NG_TARBALL); \
	     else \
			git clone https://github.com/crosstool-ng/crosstool-ng \
			$(CROSSTOOL_NG_DIR); \
	     fi	
	$(Q) mkdir -p $(CROSSTOOL_NG_STAMP_DIR)
	$(Q) touch $@

crosstool-ng-patch: $(CROSSTOOL_NG_PATCH_STAMP)
$(CROSSTOOL_NG_PATCH_STAMP): $(CROSSTOOL_NG_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching Crosstool_Ng ===="
	$(Q) if [ -a $(CROSSTOOL_NG_SRCPATCHDIR)/series]; then \
			$(Q) $(SCRIPTDIR)/apply-patch-series $(CROSSTOOL_NG_SRCPATCHDIR)/series $(CROSSTOOL_NG_DIR); \
	     fi
	$(Q) touch $@

crosstool-ng-configure: $(CROSSTOOL_NG_CONFIGURE_STAMP)
$(CROSSTOOL_NG_CONFIGURE_STAMP): $(CROSSTOOL_NG_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Configuring $(CROSSTOOL_NG_DESC) ===="
	$(Q) cd $(CROSSTOOL_NG_DIR) && \
		./bootstrap && \
		./configure --enable-local
	$(Q) touch $@

crosstool-ng-build: $(CROSSTOOL_NG_BUILD_STAMP)
$(CROSSTOOL_NG_BUILD_STAMP): $(CROSSTOOL_NG_CONFIGURE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building crosstool-ng-$(CROSSTOOL_NG_VERSION) ===="
	$(Q) $(MAKE) -C $(CROSSTOOL_NG_DIR) MAKELEVEL=0
	$(Q) touch $@

DIST_CLEAN += crosstool-ng-clean
crosstool-ng-clean:
	$(Q) rm -rf $(CROSSTOOL_NG_BUILD_DIR)
	$(Q) rm -f $(CROSSTOOL_NG_STAMP)
	$(Q) echo "=== Finished making $@ ==="

DOWNLOAD_CLEAN += crosstool-ng-download-clean
crosstool-ng-download-clean:
	$(Q) rm -f $(CROSSTOOL_NG_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(CROSSTOOL_NG_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
