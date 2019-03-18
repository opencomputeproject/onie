#-------------------------------------------------------------------------------
#
#  Copyright (C) 2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the build of curl
#

CURL_VERSION		= 7.62.0
CURL_TARBALL		= curl.tar.gz
CURL_TARBALL_URLS		+= http://proxy.dev.drivenets.net/
CURL_BUILD_DIR		= $(USER_BUILDDIR)/curl
CURL_DIR			= $(CURL_BUILD_DIR)/curl-$(CURL_VERSION)

CURL_SRCPATCHDIR		= $(PATCHDIR)/curl
CURL_DOWNLOAD_STAMP		= $(DOWNLOADDIR)/curl-download
CURL_INSTALL_STAMP		= $(STAMPDIR)/curl-install
CURL_STAMP			= $(CURL_INSTALL_STAMP)

CURL_PROGRAMS		= curl

PHONY += curl curl-download  \
	 curl-install curl-clean curl-download-clean

curl: $(CURL_STAMP)

DOWNLOAD += $(CURL_DOWNLOAD_STAMP)
curl-download: $(CURL_DOWNLOAD_STAMP)
$(CURL_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream curl ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(CURL_TARBALL) $(CURL_TARBALL_URLS)
	$(Q) touch $@

curl-install: 
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Installing curl programs in $(SYSROOTDIR) ===="
	$(Q) cd ${DOWNLOADDIR} && tar xvf ${CURL_TARBALL} && \
		cp curl $(SYSROOTDIR)/usr/bin
	$(Q) touch $@

USER_CLEAN += curl-clean
curl-clean:
	$(Q) rm -rf $(CURL_BUILD_DIR)
	$(Q) rm -f $(CURL_STAMP)
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

DOWNLOAD_CLEAN += curl-download-clean
curl-download-clean:
	$(Q) rm -f $(CURL_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(CURL_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
