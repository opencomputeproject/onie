#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of crosstool-NG
#

CROSSTOOL_NG_DESC		= crosstool-NG
CROSSTOOL_NG_VERSION		= 1.19.0
CROSSTOOL_NG_TARBALL		= crosstool-ng-$(CROSSTOOL_NG_VERSION).tar.bz2
CROSSTOOL_NG_URLS		+= $(ONIE_MIRROR) http://crosstool-ng.org/download/crosstool-ng
CROSSTOOL_NG_BUILD_DIR		= $(BUILDDIR)/crosstool-ng
CROSSTOOL_NG_STAMP_DIR		= $(CROSSTOOL_NG_BUILD_DIR)/stamp
CROSSTOOL_NG_DIR		= $(CROSSTOOL_NG_BUILD_DIR)/crosstool-ng-$(CROSSTOOL_NG_VERSION)

CROSSTOOL_NG_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/crosstool-ng-download
CROSSTOOL_NG_SOURCE_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-source
CROSSTOOL_NG_CONFIGURE_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-configure
CROSSTOOL_NG_BUILD_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-build
CROSSTOOL_NG_STAMP		= $(CROSSTOOL_NG_SOURCE_STAMP) \
				  $(CROSSTOOL_NG_CONFIGURE_STAMP) \
				  $(CROSSTOOL_NG_BUILD_STAMP) 

# Setup a mirror to use for packages needed by crosstool-NG
CROSSTOOL_ONIE_MIRROR  ?= http://dev.cumulusnetworks.com/~curt/mirror/onie/crosstool-NG
export CROSSTOOL_ONIE_MIRROR

PHONY += crosstool-ng crosstool-ng-download crosstool-ng-source crosstool-ng-configure \
	crosstool-ng-build crosstool-ng-clean crosstool-ng-download-clean

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
	$(Q) cp $(PATCHDIR)/$(CROSSTOOL_NG_DESC)/100-gcc-4.7.2-powerpc-uclibc-math-library.patch \
		$(CROSSTOOL_NG_DIR)/patches/gcc/4.7.2
	$(Q) touch $@

crosstool-ng-configure: $(CROSSTOOL_NG_CONFIGURE_STAMP)
$(CROSSTOOL_NG_CONFIGURE_STAMP): $(CROSSTOOL_NG_SOURCE_STAMP)
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
