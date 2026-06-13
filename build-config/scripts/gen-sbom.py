#!/usr/bin/env python3
#
#  Copyright (C) 2026 Brad House <bhouse@nexthop.ai>
#
#  SPDX-License-Identifier:     GPL-2.0
#
# Generate a CycloneDX 1.6 SBOM describing the third-party software that is
# COMPILED FROM SOURCE and INSTALLED INTO an ONIE image for a given MACHINE.
#
# ONIE has no package database -- every component is built from an upstream
# source tarball pinned in build-config/make/<pkg>.make.  This tool therefore
# derives the component list and metadata from the build system itself:
#
#   * "enabled for this MACHINE" == the *_VERSION make variables that are
#     defined, because build-config/Makefile only `include`s a package
#     fragment when its *_ENABLE is yes (so undefined => not built).
#   * "installed into the image" == the package's fragment writes into
#     $(SYSROOTDIR) (the rootfs that becomes the ONIE initramfs).  Pure
#     build-time tooling (the crosstool-NG toolchain + its companions, the
#     host pesign, ...) never touches SYSROOTDIR and is excluded.
#   * boot/runtime components that live in the image but install outside
#     SYSROOTDIR -- the kernel, uClibc-ng, the GCC runtime libs, and the
#     bootloader (shim/grub or u-boot) -- are added explicitly.
#
# Per-component metadata comes from the .make variables (version, tarball,
# source URL), the SHA-256 of the actual downloaded tarball (so the SBOM
# attests the built artifact regardless of the repo's integrity-pin format),
# the applied patch series (patches/<pkg>/series), and the SPDX license
# detected from the already-extracted source tree (askalono) with a curated
# override map for the genuinely multi-license packages.

import argparse
import json
import hashlib
import os
import re
import shutil
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
BUILD_CONFIG = os.path.dirname(HERE)                 # build-config/
ONIE_ROOT = os.path.dirname(BUILD_CONFIG)            # repo root
MAKEDIR = os.path.join(BUILD_CONFIG, "make")
UPSTREAMDIR = os.path.join(ONIE_ROOT, "upstream")
PATCHDIR = os.path.join(ONIE_ROOT, "patches")
OVERRIDES = os.path.join(BUILD_CONFIG, "conf", "sbom", "license-overrides.json")
CPE_OVERRIDES = os.path.join(BUILD_CONFIG, "conf", "sbom", "cpe-overrides.json")

# Make-variable prefixes that have a _VERSION/_TARBALL but are build-time only
# (the cross toolchain and its companion tools) -- never shipped in the image.
BUILD_ONLY_PREFIXES = {
    "CROSSTOOL_NG", "GCC", "BINUTILS", "GDB", "GMP", "ISL", "MPFR", "MPC",
    "MAKE", "M4", "AUTOCONF", "AUTOMAKE", "LIBTOOL", "NCURSES", "GETTEXT",
    "LIBICONV", "DUMA", "LTRACE", "STRACE", "PESIGN", "GNU_EFI",
    "XTOOLS", "XTOOLS_LINUX",
}


def run(cmd, **kw):
    return subprocess.run(cmd, check=True, capture_output=True, text=True, **kw)


def make_dump(machine):
    """Return {PREFIX: {version, tarball, urls[]}} for every *_VERSION the
    build defines for MACHINE (i.e. every enabled package + toolchain bit)."""
    sep = "\x1f"
    eval_expr = (
        "onie-sbom-dump: ; @$(foreach v,$(sort $(filter %%_VERSION,$(.VARIABLES))),"
        "$(info $(v:_VERSION=)%s$($(v))%s$($(v:_VERSION=_TARBALL))%s"
        "$($(v:_VERSION=_TARBALL_URLS))%s$($(v:_VERSION=_DIR))))"
        % (sep, sep, sep, sep)
    )
    # Drop parent make's jobserver env so this introspection sub-make is clean.
    env = {k: v for k, v in os.environ.items()
           if k not in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL")}
    out = run(["make", "MACHINE=%s" % machine, "--eval=" + eval_expr,
               "onie-sbom-dump"], cwd=BUILD_CONFIG, env=env).stdout
    pkgs = {}
    for line in out.splitlines():
        if sep not in line:
            continue
        parts = line.split(sep)
        prefix = parts[0].strip()
        if not prefix:
            continue
        pkgs[prefix] = {
            "version": parts[1].strip() if len(parts) > 1 else "",
            "tarball": parts[2].strip() if len(parts) > 2 else "",
            "url": parts[3].strip() if len(parts) > 3 else "",
            "dir": parts[4].strip() if len(parts) > 4 else "",
        }
    return pkgs


def shipped_fragment_prefixes():
    """Prefixes of packages whose fragment installs into $(SYSROOTDIR) (the
    shipped rootfs).  Prefix is taken from the fragment's *_TARBALL variable
    (disambiguates e.g. UTILLINUX vs UTILLINUX_MAJOR)."""
    infra = {"sysroot", "images", "signing-keys", "demo"}
    prefixes = {}
    for fn in os.listdir(MAKEDIR):
        if not fn.endswith(".make") or fn[:-5] in infra:
            continue
        path = os.path.join(MAKEDIR, fn)
        text = open(path, encoding="utf-8", errors="replace").read()
        if "SYSROOTDIR" not in text:
            continue
        m = re.search(r"^([A-Z][A-Z0-9_]*)_TARBALL\b", text, re.MULTILINE)
        if m:
            prefixes[m.group(1)] = fn[:-5]
    return prefixes


def sha256_for(tarball, downloaddir=None):
    """SHA-256 of the source tarball.

    Hash the actual downloaded artifact so the SBOM attests what was really
    built, independent of the repo's integrity-pin format (the build verifies
    downloads against upstream/<tarball>.sha1 or .sha256 depending on the tree
    state; the SBOM should not care which).  Fall back to the upstream/.sha256
    pin file if the artifact is not on disk, then give up.
    """
    if downloaddir:
        path = os.path.join(downloaddir, tarball)
        if os.path.isfile(path):
            h = hashlib.sha256()
            with open(path, "rb") as fh:
                for chunk in iter(lambda: fh.read(1 << 20), b""):
                    h.update(chunk)
            return h.hexdigest()
    f = os.path.join(UPSTREAMDIR, tarball + ".sha256")
    if os.path.isfile(f):
        return open(f).read().split()[0]
    return None


def make_var(machine, var):
    """Resolve a single make variable's value for MACHINE."""
    env = {k: v for k, v in os.environ.items()
           if k not in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL")}
    out = run(["make", "MACHINE=%s" % machine,
               "--eval=onie-sbom-var: ; @echo $(%s)" % var,
               "onie-sbom-var"], cwd=BUILD_CONFIG, env=env).stdout
    return out.strip()


def patches_for(fragment):
    """Applied patch filenames from patches/<fragment>/series (pedigree)."""
    series = os.path.join(PATCHDIR, fragment, "series")
    if not os.path.isfile(series):
        return []
    pats = []
    for line in open(series):
        line = line.strip()
        if line and not line.startswith("#"):
            pats.append(line.split()[0])
    return pats


def detect_license(fragment, srcdir, overrides):
    """SPDX id for a component: curated override wins; else askalono run over
    the license files in the package's extracted source dir; else NOASSERTION."""
    if fragment in overrides:
        return overrides[fragment], "override"
    if not srcdir or not shutil.which("askalono"):
        return "NOASSERTION", "undetermined"
    if not os.path.isabs(srcdir):
        srcdir = os.path.normpath(os.path.join(BUILD_CONFIG, srcdir))
    if not os.path.isdir(srcdir):
        return "NOASSERTION", "no-source"
    best, score = None, 0.0
    for root, dirs, files in os.walk(srcdir):
        if root[len(srcdir):].count(os.sep) > 1:   # top-level + one subdir (LICENSES/)
            dirs[:] = []
            continue
        for fn in files:
            if not re.match(r"(?i)(copying|licen[cs]e|copyright)", fn):
                continue
            p = subprocess.run(["askalono", "--format", "json", "id",
                                os.path.join(root, fn)], capture_output=True, text=True)
            try:
                res = json.loads(p.stdout).get("result")
            except ValueError:
                res = None
            if res:
                lic = res.get("license", {}).get("name")
                sc = res.get("score", 0.0)
                if lic and sc > score:
                    best, score = lic, sc
    if best and score >= 0.9:
        return best, "askalono(%.2f)" % score
    return "NOASSERTION", "low-confidence"


def license_entry(lic):
    """A CycloneDX licenses[] entry: SPDX expression, single id, or name."""
    if lic == "NOASSERTION":
        return {"license": {"name": "NOASSERTION"}}
    if any(op in lic for op in (" AND ", " OR ", " WITH ")):
        return {"expression": lic}
    return {"license": {"id": lic}}


def canonical_source_url(urls, tarball):
    """Pick the canonical upstream base URL (not the ONIE mirror cache) from a
    space-separated _TARBALL_URLS list and join it with the tarball name."""
    words = [u for u in urls.split() if u]
    bases = [u for u in words if "mirror.opencompute.org" not in u] or words
    if not bases:
        return ""
    base = bases[0]
    return base.rstrip("/") + "/" + tarball if tarball else base


def purl(name, version, url, sha256):
    q = []
    if url:
        q.append("download_url=" + url)
    if sha256:
        q.append("checksum=sha256:" + sha256)
    p = "pkg:generic/%s@%s" % (name, version)
    if q:
        p += "?" + "&".join(q)
    return p


def cpe_version(v):
    """Normalize an ONIE version to an NVD-CPE-comparable form: drop a leading
    'v' and turn underscore separators into dots (e.g. lvm2 '2_02_105' ->
    '2.02.105', btrfs-progs 'v4.9.1' -> '4.9.1')."""
    v = (v or "").strip()
    if v[:1].lower() == "v" and v[1:2].isdigit():
        v = v[1:]
    v = v.replace("_", ".")
    return v or "*"


def cpe_for(name, version, overrides):
    """CPE 2.3 string for a component.

    Our components carry only a pkg:generic PURL, which grype cannot map to a
    CVE -- it matches source-built packages to NVD via CPE.  Without a CPE the
    scan silently finds *nothing* (a false-clean report).  The NVD vendor:product
    rarely equals the ONIE package name (linux -> linux:linux_kernel, grub ->
    gnu:grub2, util-linux -> kernel:util-linux, dropbear ->
    dropbear_ssh_project:dropbear_ssh, ...), so a curated 'part:vendor:product'
    override map (conf/sbom/cpe-overrides.json) wins; otherwise we emit the
    syft-style default 'a:<name>:<name>'."""
    key = name.lower()
    pvp = overrides.get(key) or "a:%s:%s" % (key, key)
    part, vendor, product = pvp.split(":")
    return "cpe:2.3:%s:%s:%s:%s:*:*:*:*:*:*:*" % (
        part, vendor, product, cpe_version(version))


def main():
    ap = argparse.ArgumentParser(description="Generate an ONIE image SBOM (CycloneDX 1.6)")
    ap.add_argument("--machine", required=True)
    ap.add_argument("--output", required=True, help="output CycloneDX 1.6 JSON path")
    ap.add_argument("--spdx-output", help="also emit SPDX 2.3 JSON here (cyclonedx-cli)")
    args = ap.parse_args()

    overrides = {}
    if os.path.isfile(OVERRIDES):
        overrides = json.load(open(OVERRIDES))

    cpe_overrides = {}
    if os.path.isfile(CPE_OVERRIDES):
        cpe_overrides = {k.lower(): v for k, v in json.load(open(CPE_OVERRIDES)).items()
                         if not k.startswith("_")}

    enabled = make_dump(args.machine)
    shipped_pref = shipped_fragment_prefixes()
    downloaddir = make_var(args.machine, "DOWNLOADDIR")

    components = []
    warnings = []

    def add(prefix, fragment, name, version, tarball, url):
        sha = sha256_for(tarball, downloaddir) if tarball else None
        src = canonical_source_url(url, tarball)
        lic, how = detect_license(fragment, enabled.get(prefix, {}).get("dir", ""), overrides)
        if lic == "NOASSERTION":
            warnings.append("license undetermined: %s" % name)
        comp = {
            "type": "library",
            "name": name,
            "version": version,
            "purl": purl(name, version, src, sha),
            "cpe": cpe_for(name, version, cpe_overrides),
            "licenses": [license_entry(lic)],
            "properties": [{"name": "onie:fragment", "value": fragment},
                           {"name": "onie:license_source", "value": how}],
        }
        if tarball and src:
            ext = {"url": src, "type": "distribution", "comment": tarball}
            if sha:
                ext["hashes"] = [{"alg": "SHA-256", "content": sha}]
            comp["externalReferences"] = [ext]
        pats = patches_for(fragment)
        if pats:
            comp["pedigree"] = {"patches": [{"type": "unofficial",
                                "diff": {"url": "patches/%s/%s" % (fragment, p)}}
                                for p in pats]}
        components.append(comp)

    # 1) shipped rootfs packages = enabled prefixes that install to SYSROOTDIR
    for prefix, frag in sorted(shipped_pref.items()):
        if prefix in enabled and enabled[prefix]["tarball"]:
            e = enabled[prefix]
            add(prefix, frag, frag, e["version"], e["tarball"], e["url"])

    # 2) boot/runtime components (in the image, installed outside SYSROOTDIR)
    if "LINUX" in enabled:
        # kernel: tarball encodes LINUX_RELEASE (e.g. linux-6.18.34.tar.xz)
        t = enabled["LINUX"]["tarball"]
        ver = re.sub(r"^linux-|\.tar\..*$", "", t) or enabled["LINUX"]["version"]
        add("LINUX", "kernel", "linux", ver, t, enabled["LINUX"]["url"])
    if "XTOOLS_LIBC" in enabled:
        v = enabled["XTOOLS_LIBC"]["version"]
        add("XTOOLS_LIBC", "uclibc-ng", "uClibc-ng", v,
            "uClibc-ng-%s.tar.xz" % v, "")
    if "GCC" in enabled:                 # GCC runtime libs (libgcc/libstdc++) ship
        add("GCC", "gcc-runtime", "gcc-runtime", enabled["GCC"]["version"], "", "")
    for boot in ("SHIM", "UBOOT"):
        if boot in enabled and enabled[boot]["tarball"]:
            e = enabled[boot]
            frag = "shim" if boot == "SHIM" else "u-boot"
            add(boot, frag, frag, e["version"], e["tarball"], e["url"])

    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.6",
        "version": 1,
        "metadata": {
            "component": {
                "type": "operating-system",
                "name": "onie-%s" % args.machine,
            },
            "tools": [{"name": "gen-sbom.py", "vendor": "ONIE"}],
        },
        "components": sorted(components, key=lambda c: c["name"]),
    }
    with open(args.output, "w") as f:
        json.dump(sbom, f, indent=2)
        f.write("\n")
    sys.stderr.write("Wrote %s: %d components\n" % (args.output, len(components)))
    if args.spdx_output:
        if shutil.which("cyclonedx-cli"):
            # cyclonedx-cli is a .NET tool; run it in invariant-globalization
            # mode so it does not require an ICU package to be installed (the
            # JSON conversion is locale-independent).
            cdx_env = dict(os.environ, DOTNET_SYSTEM_GLOBALIZATION_INVARIANT="1")
            subprocess.run(["cyclonedx-cli", "convert", "--input-file", args.output,
                            "--output-file", args.spdx_output,
                            "--output-format", "spdxjson"], check=True, env=cdx_env)
            sys.stderr.write("Wrote %s (SPDX 2.3)\n" % args.spdx_output)
        else:
            sys.stderr.write("  WARN: cyclonedx-cli not found; skipped SPDX output\n")
    for w in warnings:
        sys.stderr.write("  WARN: %s\n" % w)


if __name__ == "__main__":
    main()
