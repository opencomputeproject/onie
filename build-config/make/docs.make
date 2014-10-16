#
#  Copyright (C) 2013-2014 Curt Brune <curt@cumulusnetworks.com>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#  Makefile for Sphinx documentation
#

# You can set these variables from the command line.
SPHINXOPTS    =
SPHINXBUILD   = sphinx-build
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

.PHONY: help clean html dirhtml singlehtml pickle pdf json htmlhelp qthelp devhelp epub latex latexpdf text man changes linkcheck doctest gettext

doc-help:
	@echo "Please use \`make <target>' where <target> is one of"
	@echo "  html       to make standalone HTML files"
	@echo "  dirhtml    to make HTML files named index.html in directories"
	@echo "  singlehtml to make a single large HTML file"
	@echo "  pdf        to make PDF files"
	@echo "  pickle     to make pickle files"
	@echo "  json       to make JSON files"
	@echo "  htmlhelp   to make HTML files and a HTML help project"
	@echo "  qthelp     to make HTML files and a qthelp project"
	@echo "  devhelp    to make HTML files and a Devhelp project"
	@echo "  epub       to make an epub"
	@echo "  latex      to make LaTeX files, you can set PAPER=a4 or PAPER=letter"
	@echo "  latexpdf   to make LaTeX files and run them through pdflatex"
	@echo "  text       to make text files"
	@echo "  man        to make manual pages"
	@echo "  texinfo    to make Texinfo files"
	@echo "  info       to make Texinfo files and run them through makeinfo"
	@echo "  gettext    to make PO message catalogs"
	@echo "  changes    to make an overview of all changed/added/deprecated items"
	@echo "  linkcheck  to check all external links for integrity"
	@echo "  doctest    to run all doctests embedded in the documentation (if enabled)"

CLEAN += doc-clean
doc-clean:
	$(Q) rm -rf $(DOCBUILDDIR)/*

html:
	$(SPHINXBUILD) -b html $(ALLSPHINXOPTS) $(DOCBUILDDIR)/html
	@echo
	@echo "Build finished. The HTML pages are in $(DOCBUILDDIR)/html."

dirhtml:
	$(SPHINXBUILD) -b dirhtml $(ALLSPHINXOPTS) $(DOCBUILDDIR)/dirhtml
	@echo
	@echo "Build finished. The HTML pages are in $(DOCBUILDDIR)/dirhtml."

singlehtml:
	$(SPHINXBUILD) -b singlehtml $(ALLSPHINXOPTS) $(DOCBUILDDIR)/singlehtml
	@echo
	@echo "Build finished. The HTML page is in $(DOCBUILDDIR)/singlehtml."

pickle:
	$(SPHINXBUILD) -b pickle $(ALLSPHINXOPTS) $(DOCBUILDDIR)/pickle
	@echo
	@echo "Build finished; now you can process the pickle files."

pdf:
	$(SPHINXBUILD) -b pdf $(ALLSPHINXOPTS) $(DOCBUILDDIR)/pdf
	@echo
	@echo "Build finished. The PDF files are in _build/pdf."

json:
	$(SPHINXBUILD) -b json $(ALLSPHINXOPTS) $(DOCBUILDDIR)/json
	@echo
	@echo "Build finished; now you can process the JSON files."

htmlhelp:
	$(SPHINXBUILD) -b htmlhelp $(ALLSPHINXOPTS) $(DOCBUILDDIR)/htmlhelp
	@echo
	@echo "Build finished; now you can run HTML Help Workshop with the" \
	      ".hhp project file in $(DOCBUILDDIR)/htmlhelp."

qthelp:
	$(SPHINXBUILD) -b qthelp $(ALLSPHINXOPTS) $(DOCBUILDDIR)/qthelp
	@echo
	@echo "Build finished; now you can run "qcollectiongenerator" with the" \
	      ".qhcp project file in $(DOCBUILDDIR)/qthelp, like this:"
	@echo "# qcollectiongenerator $(DOCBUILDDIR)/qthelp/CumulusNetworks-HardwareCompatibilityList.qhcp"
	@echo "To view the help file:"
	@echo "# assistant -collectionFile $(DOCBUILDDIR)/qthelp/CumulusNetworks-HardwareCompatibilityList.qhc"

devhelp:
	$(SPHINXBUILD) -b devhelp $(ALLSPHINXOPTS) $(DOCBUILDDIR)/devhelp
	@echo
	@echo "Build finished."
	@echo "To view the help file:"
	@echo "# mkdir -p $$HOME/.local/share/devhelp/CumulusNetworks-HardwareCompatibilityList"
	@echo "# ln -s $(DOCBUILDDIR)/devhelp $$HOME/.local/share/devhelp/CumulusNetworks-HardwareCompatibilityList"
	@echo "# devhelp"

epub:
	$(SPHINXBUILD) -b epub $(ALLSPHINXOPTS) $(DOCBUILDDIR)/epub
	@echo
	@echo "Build finished. The epub file is in $(DOCBUILDDIR)/epub."

latex:
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(DOCBUILDDIR)/latex
	@echo
	@echo "Build finished; the LaTeX files are in $(DOCBUILDDIR)/latex."
	@echo "Run \`make' in that directory to run these through (pdf)latex" \
	      "(use \`make latexpdf' here to do that automatically)."

latexpdf:
	$(SPHINXBUILD) -b latex $(ALLSPHINXOPTS) $(DOCBUILDDIR)/latex
	@echo "Running LaTeX files through pdflatex..."
	$(MAKE) -C $(DOCBUILDDIR)/latex all-pdf
	@echo "pdflatex finished; the PDF files are in $(DOCBUILDDIR)/latex."

text:
	$(SPHINXBUILD) -b text $(ALLSPHINXOPTS) $(DOCBUILDDIR)/text
	@echo
	@echo "Build finished. The text files are in $(DOCBUILDDIR)/text."

man:
	$(SPHINXBUILD) -b man $(ALLSPHINXOPTS) $(DOCBUILDDIR)/man
	@echo
	@echo "Build finished. The manual pages are in $(DOCBUILDDIR)/man."

texinfo:
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(DOCBUILDDIR)/texinfo
	@echo
	@echo "Build finished. The Texinfo files are in $(DOCBUILDDIR)/texinfo."
	@echo "Run \`make' in that directory to run these through makeinfo" \
	      "(use \`make info' here to do that automatically)."

info:
	$(SPHINXBUILD) -b texinfo $(ALLSPHINXOPTS) $(DOCBUILDDIR)/texinfo
	@echo "Running Texinfo files through makeinfo..."
	make -C $(DOCBUILDDIR)/texinfo info
	@echo "makeinfo finished; the Info files are in $(DOCBUILDDIR)/texinfo."

gettext:
	$(SPHINXBUILD) -b gettext $(I18NSPHINXOPTS) $(DOCBUILDDIR)/locale
	@echo
	@echo "Build finished. The message catalogs are in $(DOCBUILDDIR)/locale."

changes:
	$(SPHINXBUILD) -b changes $(ALLSPHINXOPTS) $(DOCBUILDDIR)/changes
	@echo
	@echo "The overview file is in $(DOCBUILDDIR)/changes."

linkcheck:
	$(SPHINXBUILD) -b linkcheck $(ALLSPHINXOPTS) $(DOCBUILDDIR)/linkcheck
	@echo
	@echo "Link check complete; look for any errors in the above output " \
	      "or in $(DOCBUILDDIR)/linkcheck/output.txt."

doctest:
	$(SPHINXBUILD) -b doctest $(ALLSPHINXOPTS) $(DOCBUILDDIR)/doctest
	@echo "Testing of doctests in the sources finished, look at the " \
	      "results in $(DOCBUILDDIR)/doctest/output.txt."

################################################################################
#
# Local Variables:
# mode: makefile-gmake
# End:
