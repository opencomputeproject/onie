#-------------------------------------------------------------------------------
#
#
#-------------------------------------------------------------------------------
#
# This is a makefile fragment that defines the download of uClibc
#

UCLIBC_VERSION		= 0.9.32.1
UCLIBC_TARBALL		= uClibc-$(UCLIBC_VERSION).tar.xz
UCLIBC_TARBALL_URLS	+= $(ONIE_MIRROR) http://www.uclibc.org/downloads
UCLIBC_CONFIG		= $(realpath conf/uclibc.$(ONIE_ARCH).config)

UCLIBC_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/uclibc-download

# The exported variables are used by the crosstool-NG configuration
# file.
export UCLIBC_VERSION
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

CLEAN_DOWNLOAD += uclibc-download-clean
uclibc-download-clean:
	$(Q) rm -f $(UCLIBC_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(UCLIBC_TARBALL)

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
