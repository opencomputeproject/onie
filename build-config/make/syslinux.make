#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013-2014 Mandeep Sandhu <mandeep.sandhu@cyaninc.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# makefile fragment that defines the download of a specific syslinux version
#
#-------------------------------------------------------------------------------

SYSLINUX_VERSION		?= 4.07
SYSLINUX_TARBALL		?= syslinux-$(SYSLINUX_VERSION).tar.xz
SYSLINUX_TARBALL_URLS	+= $(ONIE_MIRROR) https://www.kernel.org/pub/linux/utils/boot/syslinux/
SYSLINUX_BUILD_DIR		= $(MBUILDDIR)/syslinux
SYSLINUX_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/syslinux-download
SYSLINUX_SOURCE_STAMP	= $(STAMPDIR)/syslinux-source
SYSLINUX_DIR            = $(SYSLINUX_BUILD_DIR)/syslinux-$(SYSLINUX_VERSION)

export SYSLINUX_TARBALL
export SYSLINUX_VERSION
export SYSLINUX_DIR

SYSLINUX_STAMP          = $(SYSLINUX_DOWNLOAD_STAMP) \
                          $(SYSLINUX_SOURCE_STAMP)

PHONY += syslinux-download syslinux-source syslinux-download-clean

syslinux: $(SYSLINUX_STAMP)

DOWNLOAD += $(SYSLINUX_DOWNLOAD_STAMP)
syslinux-download: $(SYSLINUX_DOWNLOAD_STAMP)
$(SYSLINUX_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting syslinux ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(SYSLINUX_TARBALL) $(SYSLINUX_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(SYSLINUX_SOURCE_STAMP)
syslinux-source: $(SYSLINUX_SOURCE_STAMP)
$(SYSLINUX_SOURCE_STAMP): $(TREE_STAMP) | $(SYSLINUX_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream syslinux ===="
	$(Q) $(SCRIPTDIR)/extract-package $(SYSLINUX_BUILD_DIR) $(DOWNLOADDIR)/$(SYSLINUX_TARBALL)
	$(Q) touch $@

DOWNLOAD_CLEAN += syslinux-download-clean
syslinux-download-clean:
	$(Q) rm -f $(SYSLINUX_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(SYSLINUX_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
