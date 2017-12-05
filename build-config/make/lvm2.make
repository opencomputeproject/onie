#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of lvm2
#

LVM2_VERSION		?= 2_02_105
LVM2_TARBALL		= lvm2-$(LVM2_VERSION).tar.xz
LVM2_TARBALL_URLS	+= $(ONIE_MIRROR) https://git.fedorahosted.org/cgit/lvm2.git/snapshot/
LVM2_BUILD_DIR		= $(USER_BUILDDIR)/lvm2
LVM2_DIR		= $(LVM2_BUILD_DIR)/lvm2-$(LVM2_VERSION)

LVM2_SRCPATCHDIR	= $(PATCHDIR)/lvm2/$(LVM2_VERSION)
LVM2_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/lvm2-$(LVM2_VERSION)-download
LVM2_SOURCE_STAMP	= $(USER_STAMPDIR)/lvm2-source
LVM2_PATCH_STAMP	= $(USER_STAMPDIR)/lvm2-patch
LVM2_CONFIGURE_STAMP	= $(USER_STAMPDIR)/lvm2-configure
LVM2_BUILD_STAMP	= $(USER_STAMPDIR)/lvm2-build
LVM2_INSTALL_STAMP	= $(STAMPDIR)/lvm2-install
LVM2_STAMP		= $(LVM2_SOURCE_STAMP) \
			  $(LVM2_PATCH_STAMP) \
			  $(LVM2_CONFIGURE_STAMP) \
			  $(LVM2_BUILD_STAMP) \
			  $(LVM2_INSTALL_STAMP)

PHONY += lvm2 lvm2-download lvm2-source lvm2-patch lvm2-configure \
	lvm2-build lvm2-install lvm2-clean lvm2-download-clean

# List of libraries and programs to install in the final sysroot for
# lvm2.  All the paths are relative to $(DEV_SYSROOT)/usr.

LVM2_PROGS = \
  lib/libdevmapper.so lib/libdevmapper.so.1.02 \
  sbin/lvm	   \
  sbin/lvchange	   \
  sbin/lvconvert   \
  sbin/lvcreate	   \
  sbin/lvdisplay   \
  sbin/lvextend	   \
  sbin/lvmchange   \
  sbin/lvmdiskscan \
  sbin/lvmsadc	   \
  sbin/lvmsar	   \
  sbin/lvreduce	   \
  sbin/lvremove	   \
  sbin/lvrename	   \
  sbin/lvresize	   \
  sbin/lvs	   \
  sbin/lvscan	   \
  sbin/pvchange	   \
  sbin/pvresize	   \
  sbin/pvck	   \
  sbin/pvcreate	   \
  sbin/pvdisplay   \
  sbin/pvmove	   \
  sbin/pvremove	   \
  sbin/pvs	   \
  sbin/pvscan	   \
  sbin/vgcfgbackup   \
  sbin/vgcfgrestore  \
  sbin/vgchange	   \
  sbin/vgck	   \
  sbin/vgconvert   \
  sbin/vgcreate	   \
  sbin/vgdisplay   \
  sbin/vgexport	   \
  sbin/vgextend	   \
  sbin/vgimport	   \
  sbin/vgmerge	   \
  sbin/vgmknodes   \
  sbin/vgreduce	   \
  sbin/vgremove	   \
  sbin/vgrename	   \
  sbin/vgs	   \
  sbin/vgscan	   \
  sbin/vgsplit	   \
  sbin/dmsetup	   

lvm2: $(LVM2_STAMP)

DOWNLOAD += $(LVM2_DOWNLOAD_STAMP)
lvm2-download: $(LVM2_DOWNLOAD_STAMP)
$(LVM2_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream lvm2 ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(LVM2_TARBALL) $(LVM2_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(LVM2_SOURCE_STAMP)
lvm2-source: $(LVM2_SOURCE_STAMP)
$(LVM2_SOURCE_STAMP): $(USER_TREE_STAMP) | $(LVM2_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream lvm2 ===="
	$(Q) $(SCRIPTDIR)/extract-package $(LVM2_BUILD_DIR) $(DOWNLOADDIR)/$(LVM2_TARBALL)
	$(Q) touch $@

lvm2-patch: $(LVM2_PATCH_STAMP)
$(LVM2_PATCH_STAMP): $(LVM2_SRCPATCHDIR)/* $(LVM2_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching lvm2 ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(LVM2_SRCPATCHDIR)/series $(LVM2_DIR)
	$(Q) touch $@

ifndef MAKE_CLEAN
LVM2_NEW_FILES = $(shell test -d $(LVM2_DIR) && test -f $(LVM2_BUILD_STAMP) && \
	              find -L $(LVM2_DIR) -newer $(LVM2_BUILD_STAMP) -type f -print -quit)
endif

# The lvm2 configure script is a bit pessimistic about a few things
# while cross compiling.  Let it know things are fine...
LVM2_CONFIGURE_OVERRIDES	= \
  ac_cv_func_malloc_0_nonnull=yes \
  ac_cv_func_memcmp_working=yes \
  ac_cv_func_mmap_fixed_mapped=yes \
  ac_cv_func_realloc_0_nonnull=yes \
  ac_cv_func_strtod=yes \
  ac_cv_func_chown_works=yes \


lvm2-configure: $(LVM2_CONFIGURE_STAMP)
$(LVM2_CONFIGURE_STAMP): $(LVM2_PATCH_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Configure lvm2-$(LVM2_VERSION) ===="
	$(Q) cd $(LVM2_DIR) && PATH='$(CROSSBIN):$(PATH)'	\
		$(LVM2_CONFIGURE_OVERRIDES)			\
		$(LVM2_DIR)/configure				\
		--prefix=$(DEV_SYSROOT)/usr			\
		--host=$(TARGET)				\
		--with-clvmd=none				\
		--disable-nls					\
		--disable-selinux				\
		CC=$(CROSSPREFIX)gcc				\
		CFLAGS="$(ONIE_CFLAGS)"				\
		LDFLAGS="$(ONIE_LDFLAGS)"
	$(Q) touch $@

lvm2-build: $(LVM2_BUILD_STAMP)
$(LVM2_BUILD_STAMP): $(LVM2_CONFIGURE_STAMP) $(UTILLINUX_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "====  Building lvm2-$(LVM2_VERSION) ===="
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(LVM2_DIR) \
		CROSS_COMPILE=$(CROSSPREFIX) all
	$(Q) PATH='$(CROSSBIN):$(PATH)'	$(MAKE) -C $(LVM2_DIR) \
		CROSS_COMPILE=$(CROSSPREFIX) install
	$(Q) touch $@

lvm2-install: $(LVM2_INSTALL_STAMP)
$(LVM2_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(LVM2_BUILD_STAMP) $(UTILLINUX_INSTALL_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing lvm2 programs in $(SYSROOTDIR) ===="
	$(Q) for file in $(LVM2_PROGS) ; do \
		cp -afv $(DEV_SYSROOT)/usr/$$file $(SYSROOTDIR)/usr/$$file ; \
		chmod +w $(SYSROOTDIR)/usr/$$file ; \
	     done
	$(Q) touch $@

USER_CLEAN += lvm2-clean
lvm2-clean:
	$(Q) rm -rf $(LVM2_BUILD_DIR)
	$(Q) rm -f $(LVM2_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += lvm2-download-clean
lvm2-download-clean:
	$(Q) rm -f $(LVM2_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(LVM2_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
