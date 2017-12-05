#-------------------------------------------------------------------------------
#
#  Copyright (C) 2013,2014,2017 Curt Brune <curt@cumulusnetworks.com>
#  Copyright (C) 2016 Pankaj Bansal <pankajbansal3073@gmail.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the download of uClibc
#

UCLIBC_TARBALL		= uClibc-ng-$(XTOOLS_LIBC_VERSION).tar.xz
UCLIBC_TARBALL_URLS	+= $(ONIE_MIRROR) http://downloads.uclibc-ng.org/releases/$(XTOOLS_LIBC_VERSION)
UCLIBC_CONFIG		= $(realpath conf)/uclibc/$(XTOOLS_LIBC_VERSION)/uclibc.$(ONIE_ARCH).config

UCLIBC_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/uclibc-$(XTOOLS_LIBC_VERSION)-download

# The exported variables are used by the crosstool-NG configuration
# file.
export UCLIBC_TARBALL
export UCLIBC_CONFIG

PHONY += uclibc uclibc-download uclibc-download-clean

DOWNLOAD += $(UCLIBC_DOWNLOAD_STAMP)
uclibc-download: $(UCLIBC_DOWNLOAD_STAMP)
$(UCLIBC_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream uClibc ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(UCLIBC_TARBALL) $(UCLIBC_TARBALL_URLS)
	$(Q) touch $@

DOWNLOAD_CLEAN += uclibc-download-clean
uclibc-download-clean:
	$(Q) rm -f $(UCLIBC_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(UCLIBC_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
