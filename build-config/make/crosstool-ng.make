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

CROSSTOOL_NG_SRCPATCHDIR	= $(PATCHDIR)/crosstool-NG
CROSSTOOL_NG_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/crosstool-ng-download
CROSSTOOL_NG_SOURCE_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-source
CROSSTOOL_NG_PATCH_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-patch
CROSSTOOL_NG_CONFIGURE_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-configure
CROSSTOOL_NG_BUILD_STAMP	= $(CROSSTOOL_NG_STAMP_DIR)/crosstool-ng-build
CROSSTOOL_NG_STAMP		= $(CROSSTOOL_NG_SOURCE_STAMP) \
				  $(CROSSTOOL_NG_PATCH_STAMP) \
				  $(CROSSTOOL_NG_CONFIGURE_STAMP) \
				  $(CROSSTOOL_NG_BUILD_STAMP) 

# List of packages needed by crosstool-NG
CT_NG_COMPONENTS		=	\
	make-3.81.tar.bz2		\
	m4-1.4.13.tar.xz		\
	autoconf-2.65.tar.xz		\
	automake-1.11.1.tar.bz2		\
	libtool-2.2.6b.tar.lzma		\
	gmp-4.3.2.tar.bz2		\
	mpfr-2.4.2.tar.bz2		\
	ppl-0.11.2.tar.lzma		\
	cloog-ppl-0.15.10.tar.gz	\
	mpc-1.0.1.tar.gz		\
	libelf-0.8.13.tar.gz		\
	binutils-2.22.tar.bz2		\
	gcc-4.7.3.tar.bz2		\
	duma_2_5_15.tar.gz		\
	gdb-7.4.1.tar.bz2		\
	ltrace_0.5.3.orig.tar.gz	\
	strace-4.6.tar.xz

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
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(CROSSTOOL_NG_TARBALL) $(CROSSTOOL_NG_URLS)
	$(Q) for F in ${CT_NG_COMPONENTS} ; do  echo "==== Getting upstream $${F} ====" ;\
		$(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$${F} $(CROSSTOOL_ONIE_MIRROR) || exit 1 ; \
		done
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
$(CROSSTOOL_NG_PATCH_STAMP): $(CROSSTOOL_NG_SRCPATCHDIR)/* $(CROSSTOOL_NG_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching Crosstool_Ng ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(CROSSTOOL_NG_SRCPATCHDIR)/series $(CROSSTOOL_NG_DIR)
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
