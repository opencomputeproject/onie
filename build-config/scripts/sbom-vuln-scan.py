#!/usr/bin/env python3
#
#  Copyright (C) 2026 Brad House <bhouse@nexthop.ai>
#
#  SPDX-License-Identifier:     GPL-2.0
#
# Scan a CycloneDX SBOM (see gen-sbom.py) for known vulnerabilities using
# grype, and suppress CVEs that ONIE has already fixed locally via a patch.
#
# ONIE has no package database -- it builds every component from an upstream
# source tarball and applies a series of local patches from patches/<pkg>/.
# When a patch fixes a CVE, the upstream version that grype keys off of is
# still "vulnerable" as far as the vulnerability database is concerned, even
# though the shipped binary is fixed.  To avoid drowning in false positives we
# mine the patch tree for CVE references, emit an OpenVEX document declaring
# those CVEs "fixed", and cross-reference grype's output against the mined set.
#
# Modeled on SONiC's sbom_vuln_scan.py + sbom_extract_vex_from_patches.py
# (sonic-buildimage PR #27455), adapted to ONIE's patches/ layout.
#
# Usage:
#   sbom-vuln-scan.py --sbom <cyclonedx.json> --output <report.json>
#                     [--vex-output <openvex.json>]
#
# This is a report generator: it always exits 0.  If grype is unavailable the
# VEX document is still written and the report records that grype was missing.

import argparse
import json
import os
import re
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
PATCHES_DIR = os.path.join(REPO_ROOT, "patches")

CVE_RE = re.compile(r"CVE-\d{4}-\d{4,}", re.IGNORECASE)


def mine_patched_cves(patches_dir=PATCHES_DIR):
    """Walk patches/<pkg>/ and patches/<pkg>/<version>/ looking for CVE ids in
    both patch filenames and patch file contents.

    Returns a list of dicts: {"cve_id", "patch_path", "package"} de-duplicated
    on (cve_id, patch_path).  cve_id is normalized to upper case.  patch_path is
    relative to the repo root.  package is the top-level patches/<pkg> dir name.
    """
    found = {}

    if not os.path.isdir(patches_dir):
        return []

    # Top-level packages: patches/<pkg>
    for pkg in sorted(os.listdir(patches_dir)):
        pkg_dir = os.path.join(patches_dir, pkg)
        if not os.path.isdir(pkg_dir):
            continue

        # Candidate dirs to scan files in: patches/<pkg> and patches/<pkg>/<sub>
        scan_dirs = [pkg_dir]
        for sub in sorted(os.listdir(pkg_dir)):
            sub_dir = os.path.join(pkg_dir, sub)
            if os.path.isdir(sub_dir):
                scan_dirs.append(sub_dir)

        for d in scan_dirs:
            for entry in sorted(os.listdir(d)):
                fpath = os.path.join(d, entry)
                if not os.path.isfile(fpath):
                    continue

                cves = set()

                # 1) CVE in the filename
                for m in CVE_RE.findall(entry):
                    cves.add(m.upper())

                # 2) CVE in the file contents
                try:
                    with open(fpath, "r", encoding="utf-8", errors="replace") as fh:
                        for m in CVE_RE.findall(fh.read()):
                            cves.add(m.upper())
                except (OSError, IOError):
                    pass

                rel = os.path.relpath(fpath, REPO_ROOT)
                for cve in cves:
                    key = (cve, rel)
                    if key not in found:
                        found[key] = {
                            "cve_id": cve,
                            "patch_path": rel,
                            "package": pkg,
                        }

    return list(found.values())


def load_sbom_components(sbom_path):
    """Return a map of lowercased component name -> purl from a CycloneDX SBOM."""
    name_to_purl = {}
    try:
        with open(sbom_path, "r", encoding="utf-8") as fh:
            doc = json.load(fh)
    except (OSError, IOError, ValueError):
        return name_to_purl

    for comp in doc.get("components", []) or []:
        name = comp.get("name")
        purl = comp.get("purl")
        if name and purl:
            name_to_purl.setdefault(name.lower(), purl)
    return name_to_purl


def build_vex(patched, name_to_purl):
    """Build an OpenVEX v0.2.0 document from the mined patched CVEs.

    One statement per mined (cve, patch) hit.  When the patched package name
    maps to an SBOM component PURL, a products[] entry is attached; otherwise
    products is omitted.
    """
    statements = []
    for idx, item in enumerate(patched):
        cve = item["cve_id"]
        pkg = item["package"]
        patch_path = item["patch_path"]

        stmt = {
            "@id": "https://openvex.dev/statements/onie/%s/%d" % (cve, idx),
            "vulnerability": {"name": cve},
            "status": "fixed",
            "impact_statement": "Fixed by ONIE patch %s" % patch_path,
        }

        purl = name_to_purl.get(pkg.lower())
        if purl:
            stmt["products"] = [{"@id": purl}]

        statements.append(stmt)

    return {
        "@context": "https://openvex.dev/ns/v0.2.0",
        "@id": "https://openvex.dev/docs/onie/patched-cves",
        "author": "ONIE build-config/scripts/sbom-vuln-scan.py",
        "version": 1,
        "statements": statements,
    }


def run_grype(sbom_path):
    """Run grype against the SBOM.  Returns parsed JSON dict on success, or None
    if grype is missing or fails."""
    try:
        proc = subprocess.run(
            ["grype", "sbom:%s" % sbom_path, "-o", "json"],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
    except (OSError, FileNotFoundError):
        return None

    if proc.returncode != 0:
        return None

    try:
        return json.loads(proc.stdout.decode("utf-8", errors="replace"))
    except ValueError:
        return None


def parse_grype_matches(grype_json):
    """Normalize grype JSON into a list of match dicts."""
    out = []
    for match in grype_json.get("matches", []) or []:
        vuln = match.get("vulnerability", {}) or {}
        artifact = match.get("artifact", {}) or {}

        fix = vuln.get("fix", {}) or {}
        fix_versions = fix.get("versions", []) or []

        out.append({
            "id": vuln.get("id", ""),
            "package": artifact.get("name", ""),
            "severity": vuln.get("severity", ""),
            "installed_version": artifact.get("version", ""),
            "fixed_version": ", ".join(fix_versions) if fix_versions else "",
        })
    return out


# Most-severe first; unknown/blank sorts last.
SEVERITY_ORDER = {
    "critical": 0, "high": 1, "medium": 2, "low": 3, "negligible": 4,
}


def _sev_key(sev):
    return SEVERITY_ORDER.get((sev or "").lower(), 8)


def render_markdown(report, machine=None):
    """Render the vulnerability report as a GitHub-flavored Markdown table."""
    s = report.get("summary", {})
    out = []
    title = "SBOM Vulnerability Scan"
    if machine:
        title += " — %s" % machine
    out.append("## %s" % title)
    out.append("")
    if not report.get("grype_available", False):
        out.append("> :warning: grype was not available; no vulnerability scan "
                   "was performed.")
        out.append("")
    out.append("| Metric | Count |")
    out.append("| --- | ---: |")
    out.append("| Total findings | %d |" % s.get("total", 0))
    out.append("| Suppressed (fixed by ONIE patch) | %d |"
               % s.get("suppressed_by_vex", 0))
    out.append("| No fix available (won't-fix / disputed upstream) | %d |"
               % s.get("no_fix_available", 0))
    out.append("| **Actionable (fix available)** | **%d** |"
               % s.get("actionable", 0))
    out.append("")

    actionable = report.get("actionable", []) or []
    out.append("### Actionable vulnerabilities")
    out.append("")
    out.append("_Only findings with an upstream fix are listed; the "
               "%d without a published fix are counted above but omitted "
               "(no action available)._" % s.get("no_fix_available", 0))
    out.append("")
    if actionable:
        out.append("| Severity | ID | Package | Installed | Fixed in |")
        out.append("| --- | --- | --- | --- | --- |")
        for a in sorted(actionable,
                        key=lambda x: (_sev_key(x.get("severity")),
                                       x.get("package", ""))):
            out.append("| %s | %s | %s | %s | %s |" % (
                a.get("severity") or "-", a.get("id") or "-",
                a.get("package") or "-", a.get("installed_version") or "-",
                a.get("fixed_version") or "-"))
    else:
        out.append("None. :white_check_mark:")
    out.append("")

    suppressed = report.get("suppressed", []) or []
    if suppressed:
        out.append("<details><summary>Suppressed &mdash; already fixed by ONIE "
                   "patches (%d)</summary>" % len(suppressed))
        out.append("")
        out.append("| ID | Package | Fixed by patch |")
        out.append("| --- | --- | --- |")
        for sup in sorted(suppressed, key=lambda x: x.get("package", "")):
            patch = (sup.get("reason", "") or "").replace(
                "fixed by ONIE patch ", "")
            out.append("| %s | %s | %s |" % (
                sup.get("id") or "-", sup.get("package") or "-", patch or "-"))
        out.append("")
        out.append("</details>")
        out.append("")

    return "\n".join(out) + "\n"


def finalize(report, args):
    """Write the JSON report + a Markdown table, and echo the table to stdout."""
    with open(args.output, "w", encoding="utf-8") as fh:
        json.dump(report, fh, indent=2, sort_keys=False)
        fh.write("\n")

    md = render_markdown(report, machine=args.machine)
    if args.markdown:
        with open(args.markdown, "w", encoding="utf-8") as fh:
            fh.write(md)
    sys.stdout.write(md)


def main():
    ap = argparse.ArgumentParser(
        description="Scan a CycloneDX SBOM for vulnerabilities (grype) and "
                    "suppress CVEs already patched by ONIE (OpenVEX).")
    ap.add_argument("--sbom", required=True,
                    help="Path to the CycloneDX JSON SBOM to scan.")
    ap.add_argument("--output", required=True,
                    help="Path to write the vulnerability report JSON.")
    ap.add_argument("--vex-output", default=None,
                    help="Path to write the OpenVEX JSON (default: alongside "
                         "--output as <output-stem>.vex.json).")
    ap.add_argument("--markdown", default=None,
                    help="Path to write a Markdown vulnerability table (default: "
                         "alongside --output as <output-stem>.md).  The table is "
                         "always echoed to stdout regardless.")
    ap.add_argument("--machine", default=None,
                    help="Machine name, used only in the report title.")
    args = ap.parse_args()

    base = os.path.splitext(args.output)[0]
    if args.vex_output:
        vex_output = args.vex_output
    else:
        vex_output = base + ".vex.json"
    if not args.markdown:
        args.markdown = base + ".md"

    # 1) Mine patched CVEs from the patch tree.
    patched = mine_patched_cves()
    patched_cve_to_patch = {}
    for item in patched:
        patched_cve_to_patch.setdefault(item["cve_id"], item["patch_path"])

    # 2) Build + write the OpenVEX document.
    name_to_purl = load_sbom_components(args.sbom)
    vex = build_vex(patched, name_to_purl)
    with open(vex_output, "w", encoding="utf-8") as fh:
        json.dump(vex, fh, indent=2, sort_keys=False)
        fh.write("\n")

    # 3) Run grype.
    grype_json = run_grype(args.sbom)

    if grype_json is None:
        report = {
            "scanned": args.sbom,
            "grype_available": False,
            "note": "grype was not available or failed; no vulnerability "
                    "scan was performed. OpenVEX written to %s" % vex_output,
            "summary": {"total": 0, "suppressed_by_vex": 0, "actionable": 0},
            "suppressed": [],
            "actionable": [],
        }
        finalize(report, args)
        sys.stderr.write(
            "sbom-vuln-scan: grype unavailable; wrote VEX (%d patched CVEs) "
            "and empty report to %s\n" % (len(patched_cve_to_patch), args.output))
        return 0

    # 4) Cross-reference grype matches against the mined patched-CVE set, then
    #    split the rest by whether an upstream fix actually exists:
    #      * suppressed  -- already fixed by an ONIE patch (VEX)
    #      * actionable  -- a fixed version is available upstream -> we can act
    #      * no_fix      -- no fixed version published.  This usually means
    #                       upstream has triaged it as won't-fix / disputed /
    #                       not-exploitable, so there is nothing for us to do.
    #                       We report it as a statistic only, not as an
    #                       actionable item (listing it is noise).
    matches = parse_grype_matches(grype_json)
    suppressed = []
    actionable = []
    no_fix = []
    for m in matches:
        patch_path = patched_cve_to_patch.get((m["id"] or "").upper())
        if patch_path:
            entry = dict(m)
            entry["reason"] = "fixed by ONIE patch %s" % patch_path
            suppressed.append(entry)
        elif m["fixed_version"]:
            actionable.append(m)
        else:
            no_fix.append(m)

    def slim(items):
        return [{"id": x["id"], "package": x["package"], "severity": x["severity"],
                 "installed_version": x["installed_version"],
                 "fixed_version": x["fixed_version"]} for x in items]

    # 5) Write the report.
    report = {
        "scanned": args.sbom,
        "grype_available": True,
        "summary": {
            "total": len(matches),
            "suppressed_by_vex": len(suppressed),
            "no_fix_available": len(no_fix),
            "actionable": len(actionable),
        },
        "suppressed": suppressed,
        # Kept in the JSON for auditability; intentionally NOT listed in the
        # Markdown report (statistic only -- see no_fix_available above).
        "no_fix": slim(no_fix),
        "actionable": slim(actionable),
    }
    finalize(report, args)

    sys.stderr.write(
        "sbom-vuln-scan: %d findings, %d suppressed by VEX, %d no-fix, "
        "%d actionable (VEX: %s, report: %s)\n" % (
            len(matches), len(suppressed), len(no_fix), len(actionable),
            vex_output, args.output))
    return 0


if __name__ == "__main__":
    sys.exit(main())
