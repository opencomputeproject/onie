#-------------------------------------------------------------------------------
#
#  Copyright (C) 2015 Carlos Cardenas <carlos@cumulusnetworks.com>
#  Copyright (C) 2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of acpica-tools
#

ACPICA_TOOLS_VERSION	= 20150410
ACPICA_TOOLS_TARBALL	= acpica-unix-$(ACPICA_TOOLS_VERSION).tar.gz
ACPICA_TOOLS_TARBALL_URLS	+= $(ONIE_MIRROR) https://acpica.org/sites/acpica/files/
ACPICA_TOOLS_BUILD_DIR	= $(USER_BUILDDIR)/acpica-tools
ACPICA_TOOLS_DIR		= $(ACPICA_TOOLS_BUILD_DIR)/acpica-unix-$(ACPICA_TOOLS_VERSION)

ACPICA_TOOLS_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/acpica-tools-download
ACPICA_TOOLS_SOURCE_STAMP	= $(USER_STAMPDIR)/acpica-tools-source
ACPICA_TOOLS_BUILD_STAMP	= $(USER_STAMPDIR)/acpica-tools-build
ACPICA_TOOLS_INSTALL_STAMP	= $(STAMPDIR)/acpica-tools-install
ACPICA_TOOLS_STAMP		= $(ACPICA_TOOLS_SOURCE_STAMP) \
			  $(ACPICA_TOOLS_BUILD_STAMP) \
			  $(ACPICA_TOOLS_INSTALL_STAMP)

ACPIBINS = acpibin acpidump acpiexec acpihelp acpinames acpisrc acpixtract

PHONY += acpica-tools acpica-tools-download acpica-tools-source acpica-tools-build \
	 acpica-tools-install acpica-tools-clean acpica-tools-download-clean

acpica-tools: $(ACPICA_TOOLS_STAMP)

DOWNLOAD += $(ACPICA_TOOLS_DOWNLOAD_STAMP)
acpica-tools-download: $(ACPICA_TOOLS_DOWNLOAD_STAMP)
$(ACPICA_TOOLS_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream acpica-tools ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(ACPICA_TOOLS_TARBALL) $(ACPICA_TOOLS_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(ACPICA_TOOLS_SOURCE_STAMP)
acpica-tools-source: $(ACPICA_TOOLS_SOURCE_STAMP)
$(ACPICA_TOOLS_SOURCE_STAMP): $(USER_TREE_STAMP) | $(ACPICA_TOOLS_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream acpica-tools ===="
	$(Q) $(SCRIPTDIR)/extract-package $(ACPICA_TOOLS_BUILD_DIR) $(DOWNLOADDIR)/$(ACPICA_TOOLS_TARBALL)
	$(Q) touch $@

ifndef MAKE_CLEAN
ACPICA_TOOLS_NEW_FILES = $(shell test -d $(ACPICA_TOOLS_DIR) && test -f $(ACPICA_TOOLS_BUILD_STAMP) && \
	              find -L $(ACPICA_TOOLS_DIR) -newer $(ACPICA_TOOLS_BUILD_STAMP) -type f -print -quit)
endif

acpica-tools-build: $(ACPICA_TOOLS_BUILD_STAMP)
$(ACPICA_TOOLS_BUILD_STAMP): $(ACPICA_TOOLS_NEW_FILES) \
			 $(ACPICA_TOOLS_SOURCE_STAMP) | $(DEV_SYSROOT_INIT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(ACPICA_TOOLS_DIR)			\
		PREFIX=$(DEV_SYSROOT)/usr			\
		HOST=_LINUX             			\
		PROGS="$(ACPIBINS)"                             \
		CC=$(CROSSPREFIX)gcc
	$(Q) PATH='$(CROSSBIN):$(PATH)'				\
	    $(MAKE) -C $(ACPICA_TOOLS_DIR)			\
		DESTDIR=$(DEV_SYSROOT)  			\
		HOST=_LINUX             			\
		INSTALLFLAGS="-m 755 -s"        		\
		PROGS="$(ACPIBINS)"                             \
		install
	$(Q) touch $@

acpica-tools-install: $(ACPICA_TOOLS_INSTALL_STAMP)
$(ACPICA_TOOLS_INSTALL_STAMP): $(SYSROOT_INIT_STAMP) $(ACPICA_TOOLS_BUILD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing acpica-tools in $(SYSROOTDIR) ===="
	$(Q) for file in $(ACPIBINS) ; do \
		cp -av $(DEV_SYSROOT)/usr/bin/$$file $(SYSROOTDIR)/usr/bin/ ; \
	done
	$(Q) touch $@

USER_CLEAN += acpica-tools-clean
acpica-tools-clean:
	$(Q) rm -rf $(ACPICA_TOOLS_BUILD_DIR)
	$(Q) rm -f $(ACPICA_TOOLS_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += acpica-tools-download-clean
acpica-tools-download-clean:
	$(Q) rm -f $(ACPICA_TOOLS_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(ACPICA_TOOLS_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
