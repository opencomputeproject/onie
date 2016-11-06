#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of crosstool-NG
#

# Default GCC version to build for the toolchain
GCC_VERSION 			?= 4.9.2
XTOOLS_LIBC 			?= uClibc
XTOOLS_LIBC_VERSION 		?= 0.9.33.2

CROSSTOOL_NG_DESC		= crosstool-NG
CROSSTOOL_NG_COMMIT		= 11cb2ddd43fd1ff493f4b7cd63f1cf654294165f
CROSSTOOL_NG_TARBALL		= $(CROSSTOOL_NG_COMMIT).tar.gz
CROSSTOOL_NG_URLS		+= $(ONIE_MIRROR) https://github.com/crosstool-ng/crosstool-ng/archive
CROSSTOOL_NG_BUILD_DIR		= $(BUILDDIR)/crosstool-ng
CROSSTOOL_NG_STAMP_DIR		= $(CROSSTOOL_NG_BUILD_DIR)/stamp
CROSSTOOL_NG_DIR		= $(CROSSTOOL_NG_BUILD_DIR)/crosstool-ng-$(CROSSTOOL_NG_COMMIT)

CROSSTOOL_NG_SRCPATCHDIR	= $(PATCHDIR)/crosstool-NG
CROSSTOOL_NG_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/crosstool-ng-$(CROSSTOOL_NG_COMMIT)-download
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
export XTOOLS_LIBC_VERSION
export XTOOLS_LIBC
export GCC_VERSION

PHONY += crosstool-ng crosstool-ng-download crosstool-ng-source crosstool-ng-patch \
	 crosstool-ng-configure crosstool-ng-build crosstool-ng-clean \
	 crosstool-ng-download-clean

crosstool-ng: $(CROSSTOOL_NG_STAMP)

DOWNLOAD += $(CROSSTOOL_NG_DOWNLOAD_STAMP)
crosstool-ng-download: $(CROSSTOOL_NG_DOWNLOAD_STAMP)
$(CROSSTOOL_NG_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream $(CROSSTOOL_NG_DESC) ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(CROSSTOOL_NG_TARBALL) $(CROSSTOOL_NG_URLS)
	$(Q) touch $@

SOURCE += $(CROSSTOOL_NG_SOURCE_STAMP)
crosstool-ng-source: $(CROSSTOOL_NG_SOURCE_STAMP)
$(CROSSTOOL_NG_SOURCE_STAMP): $(CROSSTOOL_NG_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream $(CROSSTOOL_NG_DESC) ===="
	$(Q) $(SCRIPTDIR)/extract-package $(CROSSTOOL_NG_BUILD_DIR) $(DOWNLOADDIR)/$(CROSSTOOL_NG_TARBALL)
	$(Q) mkdir -p $(CROSSTOOL_NG_STAMP_DIR)
	$(Q) touch $@

crosstool-ng-patch: $(CROSSTOOL_NG_PATCH_STAMP)
$(CROSSTOOL_NG_PATCH_STAMP): $(CROSSTOOL_NG_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching Crosstool_Ng ===="
	$(Q) if test -s $(CROSSTOOL_NG_SRCPATCHDIR)/series; then \
		$(SCRIPTDIR)/apply-patch-series $(CROSSTOOL_NG_SRCPATCHDIR)/series $(CROSSTOOL_NG_DIR); \
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
	$(Q) echo "====  Building crosstool-ng-$(CROSSTOOL_NG_COMMIT) ===="
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
