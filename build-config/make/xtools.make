#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2015 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of a particular
# toolchain using crosstool-NG.
#

# Note: To help debug problems with building a toolchain enable these
# options in $(XTOOLS_CONFIG)
#
#   CT_DEBUG_CT=y
#   CT_DEBUG_CT_SAVE_STEPS=y
#   CT_DEBUG_CT_SAVE_STEPS_GZIP=y
#

XTOOLS_CONFIG		?= conf/crosstool/gcc-$(GCC_VERSION)/$(XTOOLS_LIBC)-$(XTOOLS_LIBC_VERSION)/crosstool.$(ONIE_ARCH).config
XTOOLS_ROOT		= $(BUILDDIR)/x-tools
XTOOLS_VERSION		= $(ONIE_ARCH)-g$(GCC_VERSION)-lnx$(LINUX_RELEASE)-$(XTOOLS_LIBC)-$(XTOOLS_LIBC_VERSION)
XTOOLS_DIR		= $(XTOOLS_ROOT)/$(XTOOLS_VERSION)
XTOOLS_BUILD_DIR	= $(XTOOLS_DIR)/build
XTOOLS_INSTALL_DIR	= $(XTOOLS_DIR)/install
XTOOLS_DEBUG_ROOT	= $(XTOOLS_INSTALL_DIR)/$(TARGET)/$(TARGET)/debug-root
XTOOLS_STAMP_DIR	= $(XTOOLS_DIR)/stamp
XTOOLS_PREP_STAMP	= $(XTOOLS_STAMP_DIR)/xtools-prep
XTOOLS_DOWNLOAD_STAMP	= $(XTOOLS_STAMP_DIR)/xtools-download
XTOOLS_BUILD_STAMP	?= $(XTOOLS_STAMP_DIR)/xtools-build
XTOOLS_STAMP		= $(XTOOLS_PREP_STAMP) \
			  $(XTOOLS_DOWNLOAD_STAMP) \
			  $(XTOOLS_BUILD_STAMP) 

# The exported variables are used by the crosstool-NG configuration
# file.
export XTOOLS_INSTALL_DIR

PHONY += xtools xtools-prep xtools-download xtools-config \
	 xtools-build xtools-clean xtools-distclean

# List of common packages needed by crosstool-NG

CT_NG_COMPONENTS		=	\
	make-3.81.tar.bz2		\
	m4-1.4.13.tar.xz		\
	autoconf-2.65.tar.xz		\
	automake-1.11.1.tar.bz2		\
	libelf-0.8.13.tar.gz		\
	duma_2_5_15.tar.gz		\
	libtool-2.4.6.tar.gz

ifeq ($(GCC_VERSION),4.9.2)
CT_NG_COMPONENTS +=	\
	cloog-0.18.1.tar.gz		\
	gmp-6.0.0a.tar.xz		\
	isl-0.12.2.tar.bz2		\
	mpfr-3.1.2.tar.xz		\
	mpc-1.0.2.tar.gz		\
	binutils-2.25.tar.bz2		\
	binutils-2.24.tar.bz2		\
	gcc-4.9.2.tar.bz2		\
	gdb-7.11.tar.xz			\
	ltrace_0.7.3.orig.tar.bz2	\
	strace-4.9.tar.xz		\
	ncurses-6.0.tar.gz		\
	libiconv-1.14.tar.gz		\
	gettext-0.19.6.tar.xz		\
	expat-2.1.0.tar.gz
       ifeq ($(XTOOLS_LIBC),glibc)
	CT_NG_COMPONENTS += glibc-2.24.tar.xz
       endif
else ifeq ($(GCC_VERSION),4.7.3)
CT_NG_COMPONENTS +=	\
        gmp-4.3.2.tar.bz2               \
        mpfr-2.4.2.tar.bz2              \
        ppl-0.11.2.tar.lzma             \
        cloog-ppl-0.15.10.tar.gz        \
        mpc-1.0.1.tar.gz                \
        binutils-2.22.tar.bz2           \
        gcc-4.7.3.tar.bz2               \
        gdb-7.4.1.tar.bz2               \
        ltrace_0.5.3.orig.tar.gz        \
        strace-4.6.tar.xz
else
  $(error CT_NG_COMPONENTS download: Unsupported GCC version: $(GCC_VERSION))
endif

xtools: $(XTOOLS_STAMP)

xtools-prep: $(XTOOLS_PREP_STAMP)
$(XTOOLS_PREP_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Preparing xtools for $(XTOOLS_VERSION) ===="
	$(Q) mkdir -p $(XTOOLS_BUILD_DIR) $(XTOOLS_INSTALL_DIR) $(XTOOLS_STAMP_DIR)
	$(Q) touch $@

DOWNLOAD += $(XTOOLS_DOWNLOAD_STAMP)
xtools-download: $(XTOOLS_DOWNLOAD_STAMP)
$(XTOOLS_DOWNLOAD_STAMP): $(XTOOLS_PREP_STAMP) | $(KERNEL_DOWNLOAD_STAMP) $(UCLIBC_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream crosstool-NG component libraries ===="
	$(Q) for F in ${CT_NG_COMPONENTS} ; do	echo "==== Getting upstream $${F} ====" ;\
		$(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$${F} $(CROSSTOOL_ONIE_MIRROR) || exit 1 ; \
		done
	$(Q) touch $@

$(XTOOLS_BUILD_DIR)/.config: $(XTOOLS_CONFIG) $(XTOOLS_PREP_STAMP)
	$(Q) echo "==== Copying $(XTOOLS_CONFIG) to $@ ===="
	$(Q) cp -v $< $@

xtools-config: $(XTOOLS_BUILD_DIR)/.config $(CROSSTOOL_NG_BUILD_STAMP)
	$(Q) cd $(XTOOLS_BUILD_DIR) && $(CROSSTOOL_NG_DIR)/ct-ng menuconfig

xtools-old-config: $(XTOOLS_BUILD_DIR)/.config $(CROSSTOOL_NG_BUILD_STAMP)
	$(Q) cd $(XTOOLS_BUILD_DIR) && $(CROSSTOOL_NG_DIR)/ct-ng oldconfig

xtools-download-only: $(XTOOLS_BUILD_DIR)/.config $(CROSSTOOL_NG_BUILD_STAMP)
	$(Q) cd $(XTOOLS_BUILD_DIR) && $(CROSSTOOL_NG_DIR)/ct-ng build STOP=libc_check_config

xtools-build: $(XTOOLS_BUILD_STAMP)
$(XTOOLS_BUILD_STAMP): $(XTOOLS_BUILD_DIR)/.config $(XTOOLS_DOWNLOAD_STAMP) $(CROSSTOOL_NG_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building xtools for $(XTOOLS_VERSION) ===="
	$(Q) cd $(XTOOLS_BUILD_DIR) && \
		$(CROSSTOOL_NG_DIR)/ct-ng build || (rm $(XTOOLS_BUILD_DIR)/.config.2 && false)
	$(Q) touch $@

xtools-clean:
	$(Q) ( [ -d $(XTOOLS_DIR) ] && chmod +w -R $(XTOOLS_DIR) ) || true
	$(Q) rm -rf $(XTOOLS_DIR) 
	$(Q) echo "=== Finished making $@ ==="

DIST_CLEAN += xtools-distclean
xtools-distclean:
	$(Q) ( [ -d $(XTOOLS_ROOT) ] && chmod +w -R $(XTOOLS_ROOT) ) || true
	$(Q) rm -rf $(XTOOLS_ROOT)
	$(Q) echo "=== Finished making $@ ==="

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
