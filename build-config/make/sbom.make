#-------------------------------------------------------------------------------
#
#  Copyright (C) 2026 Brad House <bhouse@nexthop.ai>
#
#  SPDX-License-Identifier:     GPL-2.0
#
#-------------------------------------------------------------------------------
#
# Generate a Software Bill of Materials (SBOM) for the image.
#
# scripts/gen-sbom.py derives the third-party software COMPILED FROM SOURCE and
# INSTALLED INTO this MACHINE's image (the SYSROOTDIR-installed packages plus the
# kernel / uClibc-ng / GCC runtime / bootloader) from the build system, and emits
# CycloneDX 1.6 (then SPDX 2.3 via cyclonedx-cli).  It depends on the assembled
# sysroot so every package source is already extracted (for license detection)
# and every version is final.  The SBOM is built as part of `all`, so it is
# always produced alongside the image.
#
# The generator relies on a few external tools (askalono for license
# detection, cyclonedx-cli for the SPDX conversion, grype for the optional
# vulnerability scan).  If they are not already on PATH, the build provisions
# them -- pinned + sha256-verified -- into a build-local prefix
# ($(SBOM_TOOLS_DIR)) without needing root, so a full-fidelity SBOM is
# produced in any environment.  If provisioning fails (e.g. no network), the
# generator degrades gracefully (NOASSERTION licenses, CycloneDX-only).

SBOM_CDX		= $(IMAGEDIR)/$(MACHINE_PREFIX).sbom.cdx.json
SBOM_SPDX		= $(IMAGEDIR)/$(MACHINE_PREFIX).sbom.spdx.json
SBOM_STAMP		= $(STAMPDIR)/sbom
SBOM_TOOLS_DIR		= $(BUILDDIR)/sbom-tools/bin
SBOM_INSTALL_TOOLS	= $(SCRIPTDIR)/install-sbom-tools.sh

PHONY += sbom sbom-clean sbom-vuln-scan

sbom: $(SBOM_STAMP)
$(SBOM_STAMP): $(SYSROOT_COMPLETE_STAMP)
	$(Q) rm -f $@ && eval $(PROFILE_STAMP)
	$(Q) echo "==== Generating SBOM for $(MACHINE) ===="
	$(Q) export PATH="$(SBOM_TOOLS_DIR):$$PATH" ; \
	     command -v askalono >/dev/null 2>&1 && command -v cyclonedx-cli >/dev/null 2>&1 || { \
	         echo "==== Provisioning SBOM tools into $(SBOM_TOOLS_DIR) ====" ; \
	         "$(SBOM_INSTALL_TOOLS)" "$(SBOM_TOOLS_DIR)" || \
	             echo "  WARNING: SBOM tool provisioning failed; SBOM will be degraded (NOASSERTION licenses, CycloneDX only)" ; } ; \
	     python3 $(SCRIPTDIR)/gen-sbom.py \
	         --machine $(MACHINE) \
	         --output $(SBOM_CDX) \
	         --spdx-output $(SBOM_SPDX)
	$(Q) touch $@

# Optional: scan the already-generated SBOM for known vulnerabilities (grype),
# with CVEs already fixed by ONIE patches suppressed via OpenVEX.
#
# This is pure post-processing of the SBOM artifact, so it deliberately does NOT
# depend on $(SBOM_STAMP) (and therefore not on $(SYSROOT_COMPLETE_STAMP)).
# Depending on the stamp made a standalone `make sbom-vuln-scan` re-assemble the
# whole rootfs: the sysroot stamp is invalidated on every parse by the rootconf
# -cnewer guard in images.make, so a second invocation (e.g. the CI scan step,
# run after `make all` already produced the SBOM) rebuilt busybox/e2fsprogs/...
# before scanning.  Decoupled, the scan just consumes $(SBOM_CDX); if it is
# missing we fail with a clear message instead of silently rebuilding the image.
sbom-vuln-scan:
	$(Q) test -f $(SBOM_CDX) || { \
	         echo "ERROR: SBOM not found: $(SBOM_CDX)" >&2 ; \
	         echo "       Generate it first: make MACHINE=$(MACHINE) sbom   (or 'make all')." >&2 ; \
	         exit 1 ; }
	$(Q) export PATH="$(SBOM_TOOLS_DIR):$$PATH" ; \
	     command -v grype >/dev/null 2>&1 || "$(SBOM_INSTALL_TOOLS)" "$(SBOM_TOOLS_DIR)" || true ; \
	     python3 $(SCRIPTDIR)/sbom-vuln-scan.py \
	         --machine $(MACHINE) \
	         --sbom $(SBOM_CDX) \
	         --output $(IMAGEDIR)/$(MACHINE_PREFIX).sbom.vulns.json

sbom-clean:
	$(Q) rm -f $(SBOM_STAMP) $(SBOM_CDX) $(SBOM_SPDX) \
		$(IMAGEDIR)/$(MACHINE_PREFIX).sbom.vulns.json \
		$(IMAGEDIR)/$(MACHINE_PREFIX).sbom.vulns.vex.json \
		$(IMAGEDIR)/$(MACHINE_PREFIX).sbom.vulns.md
	$(Q) echo "=== Finished making $@ for $(PLATFORM)"

#-------------------------------------------------------------------------------
#
# Local Variables:
# mode: makefile-gmake
# End:
