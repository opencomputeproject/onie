#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# The onie root file system is built using scripts and busybox.
#

ROOTCONFDIR		= $(CONFDIR)/onie
SYSROOT_INIT_STAMP	= $(STAMPDIR)/sysroot-init
SYSROOT_COMPLETE_STAMP	= $(STAMPDIR)/sysroot-complete
SYSROOT			= $(SYSROOT_COMPLETE_STAMP)

#-------------------------------------------------------------------------------

# the target for SYSROOT_COMPLETE is defined in make/images.make.

PHONY += sysroot-init
sysroot-init: $(SYSROOT_INIT_STAMP)
$(SYSROOT_INIT_STAMP): $(TREE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Preparing a new sysroot directory ===="
	$(Q) rm -rf $(SYSROOTDIR)
	$(Q) mkdir -p -v $(SYSROOTDIR)
	$(Q) mkdir -p -v -m 0755 $(SYSROOTDIR)/dev
	$(Q) mkdir -p -v $(SYSROOTDIR)/{sys,proc,tmp,etc,lib,mnt}
	$(Q) mkdir -p -v $(SYSROOTDIR)/{var/log,usr/lib,usr/bin,usr/sbin,lib,mnt}
	$(Q) touch $@

#---

CLEAN += sysroot-clean
sysroot-clean:
	$(Q) rm -rf $(SYSROOTDIR)
	$(Q) rm -f $(SYSROOT_INIT_STAMP) $(SYSROOT_COMPLETE_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#
# Local Variables:
# mode: makefile-gmake
# End:
