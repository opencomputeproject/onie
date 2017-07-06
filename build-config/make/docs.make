#
#  Copyright (C) 2013,2014,2017 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#  Makefile for Sphinx documentation
#

PHONY += help clean html dirhtml singlehtml pdf text \
	guzzle-download guzzle-source guzzle-build guzzle-clean guzzle-download-clean

GUZZLE_DESC		= guzzle_sphinx_theme
GUZZLE_VERSION		= 0.7.11
GUZZLE_TARBALL		= $(GUZZLE_VERSION).tar.gz
GUZZLE_TARBALL_URLS	+= $(ONIE_MIRROR) https://github.com/guzzle/guzzle_sphinx_theme/archive
GUZZLE_BUILD_DIR	= $(BUILDDIR)/guzzle
GUZZLE_STAMP_DIR	= $(GUZZLE_BUILD_DIR)/stamp
GUZZLE_DIR		= $(GUZZLE_BUILD_DIR)/$(GUZZLE_DESC)-$(GUZZLE_VERSION)

GUZZLE_SRCPATCHDIR	= $(PATCHDIR)/guzzle
GUZZLE_DOWNLOAD_STAMP	= $(DOWNLOADDIR)/guzzle-download
GUZZLE_SOURCE_STAMP	= $(GUZZLE_STAMP_DIR)/guzzle-source
GUZZLE_PATCH_STAMP	= $(GUZZLE_STAMP_DIR)/guzzle-patch
GUZZLE_BUILD_STAMP	= $(GUZZLE_STAMP_DIR)/guzzle-build
GUZZLE_PYTHONPATH	= $(GUZZLE_BUILD_DIR)/install

DOWNLOAD += $(GUZZLE_DOWNLOAD_STAMP)
guzzle-download: $(GUZZLE_DOWNLOAD_STAMP)
$(GUZZLE_DOWNLOAD_STAMP): $(PROJECT_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Getting upstream $(GUZZLE_DESC) theme ===="
	$(Q) $(SCRIPTDIR)/fetch-package $(DOWNLOADDIR) $(UPSTREAMDIR) \
		$(GUZZLE_TARBALL) $(GUZZLE_TARBALL_URLS)
	$(Q) touch $@

SOURCE += $(GUZZLE_SOURCE_STAMP)
guzzle-source: $(GUZZLE_SOURCE_STAMP)
$(GUZZLE_SOURCE_STAMP): $(GUZZLE_DOWNLOAD_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Extracting upstream $(GUZZLE_DESC) ===="
	$(Q) $(SCRIPTDIR)/extract-package $(GUZZLE_BUILD_DIR) $(DOWNLOADDIR)/$(GUZZLE_TARBALL)
	$(Q) mkdir -p $(GUZZLE_STAMP_DIR)
	$(Q) touch $@

guzzle-patch: $(GUZZLE_PATCH_STAMP)
$(GUZZLE_PATCH_STAMP): $(GUZZLE_SOURCE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Patching upstream $(GUZZLE_DESC) ===="
	$(Q) $(SCRIPTDIR)/apply-patch-series $(GUZZLE_SRCPATCHDIR)/series $(GUZZLE_DIR)
	$(Q) touch $@

guzzle-build: $(GUZZLE_BUILD_STAMP)
$(GUZZLE_BUILD_STAMP): $(GUZZLE_PATCH_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Building upstream $(GUZZLE_DESC) ===="
	$(Q) mkdir -p $(GUZZLE_PYTHONPATH)/lib/python
	$(Q) cd $(GUZZLE_DIR) && PYTHONPATH=$(GUZZLE_PYTHONPATH)/lib/python python \
		setup.py install --home=$(GUZZLE_PYTHONPATH)
	$(Q) touch $@

DIST_CLEAN += guzzle-clean
guzzle-clean:
	$(Q) rm -rf $(GUZZLE_BUILD_DIR)
	$(Q) rm -f $(GUZZLE_STAMP)
	$(Q) echo "=== Finished making $@ ==="

DOWNLOAD_CLEAN += guzzle-download-clean
guzzle-download-clean:
	$(Q) rm -f $(GUZZLE_DOWNLOAD_STAMP) $(DOWNLOADDIR)/$(GUZZLE_TARBALL)

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = PYTHONPATH=$(GUZZLE_PYTHONPATH)/lib/python sphinx-build
PAPER         =
DOCSRCDIR     = $(PROJECTDIR)/docs
DOCBUILDDIR   ?= $(BUILDDIR)/docs

# Internal variables.
PAPEROPT_a4     = -D latex_paper_size=a4
PAPEROPT_letter = -D latex_paper_size=letter
DOCVERSIONOPTS  = -D release=$(LSB_RELEASE_TAG) -D version="$(shell date --rfc-3339='seconds')"
ALLSPHINXOPTS   = -W -n -E -d $(DOCBUILDDIR)/doctrees $(DOCVERSIONOPTS) $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) $(DOCSRCDIR)
# the i18n builder cannot share the environment and doctrees with the others
I18NSPHINXOPTS  = $(PAPEROPT_$(PAPER)) $(SPHINXOPTS) $(DOCSRCDIR)

doc-help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  html       to make standalone HTML files"
	@echo "  dirhtml    to make HTML files named index.html in directories"
	@echo "  singlehtml to make a single large HTML file"
	@echo "  pdf        to make PDF files"
	@echo "  text       to make text files"

CLEAN += doc-clean
doc-clean:
	$(Q) rm -rf $(DOCBUILDDIR)/*

html: $(GUZZLE_BUILD_STAMP)
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(DOCBUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(DOCBUILDDIR)/html."

dirhtml: $(GUZZLE_BUILD_STAMP)
	$(SPHINXBUILD) -b dirhtml $(ALLSPHINXOPTS) $(DOCBUILDDIR)/dirhtml
	@echo
	@echo "Build finished. The HTML pages are in $(DOCBUILDDIR)/dirhtml."

singlehtml: $(GUZZLE_BUILD_STAMP)
	$(SPHINXBUILD) -b singlehtml $(ALLSPHINXOPTS) $(DOCBUILDDIR)/singlehtml
	@echo
	@echo "Build finished. The HTML page is in $(DOCBUILDDIR)/singlehtml."

pdf: $(GUZZLE_BUILD_STAMP)
	$(SPHINXBUILD) -b pdf $(ALLSPHINXOPTS) $(DOCBUILDDIR)/pdf
	@echo
	@echo "Build finished. The PDF files are in _build/pdf."

text: $(GUZZLE_BUILD_STAMP)
	$(SPHINXBUILD) -b text $(ALLSPHINXOPTS) $(DOCBUILDDIR)/text
	@echo
	@echo "Build finished. The text files are in $(DOCBUILDDIR)/text."
