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
# the patch series the build applies (the package's own, version-specific
# where it keeps them that way, and the MACHINE's), and the SPDX license
# detected from the already-extracted source tree (askalono) with a curated
# override map for the genuinely multi-license packages.
#
# The dependency graph is rooted at the image: the image holds the kernel,
# the bootloader and the rootfs; the rootfs holds every userspace package;
# and a package depends on each package its fragment builds against (a
# $(<PKG>_BUILD_STAMP) or $(<PKG>_INSTALL_STAMP) prerequisite).  A patch that
# names a CVE in its filename, or in a 'Fixes:' or 'Subject:' header, records
# it in pedigree.patches[].resolves[]; a CVE mentioned anywhere else is not a
# claim to fix it.

import argparse
import json
import hashlib
import uuid
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


# NAME=VALUE pairs every make query passes on, so a MACHINE that lives
# under a vendor directory (MACHINEROOT) or varies by MACHINE_REV resolves
# exactly as the build that made the image did.
MAKE_VARS = []


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
    out = run(["make", "MACHINE=%s" % machine] + MAKE_VARS + [ "--eval=" + eval_expr,
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
    out = run(["make", "MACHINE=%s" % machine] + MAKE_VARS + [
               "--eval=onie-sbom-var: ; @echo $(%s)" % var,
               "onie-sbom-var"], cwd=BUILD_CONFIG, env=env).stdout
    return out.strip()


def make_vars(machine, patterns):
    """{name: value} for every make variable matching one of the % patterns."""
    sep = "\x1f"
    eval_expr = ("onie-sbom-vars: ; @$(foreach v,$(sort $(filter %s,$(.VARIABLES))),"
                 "$(info $(v)%s$($(v))))" % (" ".join(patterns), sep))
    env = {k: v for k, v in os.environ.items()
           if k not in ("MAKEFLAGS", "MFLAGS", "MAKELEVEL")}
    out = run(["make", "MACHINE=%s" % machine] + MAKE_VARS + [ "--eval=" + eval_expr,
               "onie-sbom-vars"], cwd=BUILD_CONFIG, env=env).stdout
    return dict(l.split(sep, 1) for l in out.splitlines() if sep in l)


def series_entries(series):
    """Patch names a series file lists, in order."""
    if not series or not os.path.isfile(series):
        return []
    out = []
    for line in open(series, encoding="utf-8", errors="replace"):
        line = line.split("#", 1)[0].strip()
        if line:
            out.append(line.split()[0])
    return out


_CVE = r"CVE-\d{4}-\d{4,7}"
_FIXES_RE = re.compile(r"^\s*Fixes:\s*(%s)" % _CVE, re.I | re.M)
_SUBJECT_RE = re.compile(r"^Subject:.*?(%s)" % _CVE, re.I | re.M)


def cves_fixed(name, path):
    """CVEs a patch declares it fixes: in its filename, or in a 'Fixes:' or
    'Subject:' header.  The same rule SONiC's SBOM applies -- a CVE named
    anywhere else in a patch is often a passing reference, not a claim."""
    found = set(m.upper() for m in re.findall(_CVE, name, re.I))
    if path and os.path.isfile(path):
        text = open(path, encoding="utf-8", errors="replace").read(65536)
        end = min([i for i in (text.find("\n---\n"), text.find("\ndiff --git"))
                   if i >= 0] or [4000])
        head = text[:end]
        found |= set(m.upper() for m in _FIXES_RE.findall(head))
        found |= set(m.upper() for m in _SUBJECT_RE.findall(head))
    return sorted(found)


def patch_series(fragment, patchvars, machinevars):
    """The series the build applies to a package, base first, then MACHINE:
    [(series file, directory a patch is otherwise looked up in)].

    The package's own series is where its fragment says (<X>_SRCPATCHDIR,
    plus u-boot's <X>_CMNPATCHDIR), which is version-specific for the kernel,
    grub and u-boot.  The MACHINE's is MACHINE_<X>_PATCHDIR (u-boot hard-codes
    $(MACHINEDIR)/u-boot); its entries may live in the vendor-wide
    $(MACHINEROOT)/<pkg> directory, as cp-machine-patches resolves them."""
    out = []
    path = os.path.join(MAKEDIR, fragment + ".make")
    if not os.path.isfile(path):
        return out
    text = open(path, encoding="utf-8", errors="replace").read()
    for kind in ("CMNPATCHDIR", "SRCPATCHDIR"):
        for var in re.findall(r"^([A-Z0-9_]+_%s)\b" % kind, text, re.M):
            d = patchvars.get(var, "")
            if d:
                out.append((os.path.join(d, "series"), ""))
    mdirs = [patchvars.get(v, "") for v in
             re.findall(r"^(MACHINE_[A-Z0-9_]+_PATCHDIR)\b", text, re.M)]
    if fragment == "u-boot" and machinevars.get("MACHINEDIR"):
        mdirs.append(os.path.join(machinevars["MACHINEDIR"], "u-boot"))
    vendor = os.path.join(machinevars.get("MACHINEROOT", ""), fragment)
    for d in mdirs:
        if d:
            out.append((os.path.join(d, "series"), vendor))
    return out


def pedigree_patches(fragment, patchvars, machinevars):
    """CycloneDX pedigree.patches[] for every patch the build applies."""
    patches = []
    for series, fallback in patch_series(fragment, patchvars, machinevars):
        sdir = os.path.dirname(series)
        for name in series_entries(series):
            path = os.path.join(sdir, name)
            if not os.path.isfile(path) and fallback:
                path = os.path.join(fallback, name)
            rel = os.path.relpath(path, ONIE_ROOT) if os.path.isfile(path) else name
            patch = {"type": "unofficial", "diff": {"url": rel}}
            fixes = cves_fixed(name, path)
            if fixes:
                patch["resolves"] = [{"type": "security", "id": c,
                                      "source": {"name": "NVD",
                                                 "url": "https://nvd.nist.gov/vuln/detail/" + c}}
                                     for c in fixes]
            patches.append(patch)
    return patches


# Prerequisites that order an install rather than state a dependency:
# e2fsprogs installs after busybox so its tools replace busybox's applets,
# and nothing links against busybox.
ORDER_ONLY = {"BUSYBOX"}


def fragment_deps(fragment):
    """Package prefixes a fragment builds against: the $(<PKG>_BUILD_STAMP)
    and $(<PKG>_INSTALL_STAMP) prerequisites it names."""
    path = os.path.join(MAKEDIR, fragment + ".make")
    if not os.path.isfile(path):
        return set()
    text = open(path, encoding="utf-8", errors="replace").read()
    return set(re.findall(r"\$\(([A-Z0-9_]+)_(?:BUILD|INSTALL)_STAMP\)", text)) - ORDER_ONLY


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


def git_revision():
    """The commit the tree was built from, or None outside a checkout."""
    try:
        return run(["git", "rev-parse", "HEAD"], cwd=ONIE_ROOT).stdout.strip() or None
    except (OSError, subprocess.CalledProcessError):
        return None


def git_dirty():
    """True when the tree has uncommitted changes (untracked files count:
    a machine or patch set added without committing it changes what is
    built), so HEAD does not describe what was built."""
    try:
        return bool(run(["git", "status", "--porcelain"], cwd=ONIE_ROOT).stdout.strip())
    except (OSError, subprocess.CalledProcessError):
        return False


def git_repository():
    """OWNER/NAME of the GitHub repository HEAD's commit was fetched from:
    the remote the current branch tracks, else "origin", else the only
    remote.  None when that is not a GitHub repository."""
    def out(*cmd):
        try:
            return run(["git"] + list(cmd), cwd=ONIE_ROOT).stdout.strip()
        except (OSError, subprocess.CalledProcessError):
            return ""
    remote = out("rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}")
    remote = remote.split("/", 1)[0] if "/" in remote else ""
    if not remote:
        remotes = out("remote").split()
        remote = "origin" if "origin" in remotes else (
            remotes[0] if len(remotes) == 1 else "")
    url = out("remote", "get-url", remote) if remote else ""
    m = re.match(r"(?:https?://|ssh://)?(?:[^@/]+@)?github\.com[:/]"
                 r"([^/]+)/([^/]+?)(?:\.git)?/?$", url)
    return "%s/%s" % m.groups() if m else None


def build_timestamp(dirty):
    """When the image's sources were made, so a rebuild is not a new date:
    SOURCE_DATE_EPOCH if set, else the commit's date, else now.  A dirty
    tree is not described by the commit, so it uses now: two different
    builds from one commit must not share a build time, or anything that
    orders SBOMs by it takes the later one for a repeat of the first."""
    import datetime
    sde = os.environ.get("SOURCE_DATE_EPOCH")
    if sde and sde.isdigit():
        t = datetime.datetime.fromtimestamp(int(sde), datetime.timezone.utc)
    elif dirty:
        t = datetime.datetime.now(datetime.timezone.utc)
    else:
        try:
            t = datetime.datetime.fromtimestamp(int(run(
                ["git", "log", "-1", "--format=%ct"], cwd=ONIE_ROOT).stdout.strip()),
                datetime.timezone.utc)
        except (OSError, ValueError, subprocess.CalledProcessError):
            t = datetime.datetime.now(datetime.timezone.utc)
    return t.strftime("%Y-%m-%dT%H:%M:%SZ")


def main():
    ap = argparse.ArgumentParser(description="Generate an ONIE image SBOM (CycloneDX 1.6)")
    ap.add_argument("--machine", required=True)
    ap.add_argument("--output", required=True, help="output CycloneDX 1.6 JSON path")
    ap.add_argument("--spdx-output", help="also emit SPDX 2.3 JSON here (cyclonedx-cli)")
    ap.add_argument("--make-var", action="append", default=[], metavar="NAME=VALUE",
                    help="pass to every make query, e.g. MACHINEROOT=../machine/<vendor>")
    ap.add_argument("--repository", metavar="OWNER/NAME",
                    help="GitHub repository the commit is in, for the root purl "
                         "(default: derived from the git remote)")
    args = ap.parse_args()
    MAKE_VARS.extend(args.make_var)

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
    patchvars = make_vars(args.machine, ["%_SRCPATCHDIR", "%_CMNPATCHDIR",
                                         "MACHINE_%_PATCHDIR"])
    machinevars = make_vars(args.machine, ["MACHINEDIR", "MACHINEROOT",
                                           "LSB_RELEASE_TAG"])

    components = []
    warnings = []
    by_prefix = {}           # make prefix -> component
    parent_of = {}           # bom-ref -> "kernel" | "boot" | "rootfs"

    def add(prefix, fragment, name, version, tarball, url,
            ctype="library", place="rootfs"):
        sha = sha256_for(tarball, downloaddir) if tarball else None
        src = canonical_source_url(url, tarball)
        lic, how = detect_license(fragment, enabled.get(prefix, {}).get("dir", ""), overrides)
        if lic == "NOASSERTION":
            warnings.append("license undetermined: %s" % name)
        comp = {
            "type": ctype,
            "bom-ref": "%s@%s" % (name, version),
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
        pats = pedigree_patches(fragment, patchvars, machinevars)
        if pats:
            comp["pedigree"] = {"patches": pats}
        components.append(comp)
        by_prefix[prefix] = comp
        parent_of[comp["bom-ref"]] = place

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
        add("LINUX", "kernel", "linux", ver, t, enabled["LINUX"]["url"],
            ctype="operating-system", place="image")
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
            add(boot, frag, frag, e["version"], e["tarball"], e["url"],
                ctype="firmware", place="image")
    # grub installs its tools into the rootfs, but what it is in the image is
    # the bootloader.
    if "grub@%s" % enabled.get("GRUB", {}).get("version") in parent_of:
        g = by_prefix["GRUB"]
        g["type"] = "firmware"
        parent_of[g["bom-ref"]] = "image"

    # The image, and the rootfs (initramfs) it boots into.
    release = machinevars.get("LSB_RELEASE_TAG", "")
    root = {"type": "operating-system", "bom-ref": "onie-%s" % args.machine,
            "name": "onie-%s" % args.machine}
    if release:
        root["version"] = release
    # The purl names the commit, and is what a VEX document matches the
    # image by, so it is left out when it would point at the wrong thing: a
    # dirty tree (the commit is not what was built) or no known repository.
    rev = git_revision()
    dirty = git_dirty()
    repo = args.repository or git_repository()
    if rev and repo and not dirty:
        root["purl"] = "pkg:github/%s@%s" % (repo, rev)
    if rev:
        root["properties"] = [{"name": "onie:git-commit", "value": rev},
                              {"name": "onie:git-dirty",
                               "value": "true" if dirty else "false"}]
    rootfs = {"type": "operating-system", "bom-ref": "onie-rootfs",
              "name": "onie-rootfs",
              "description": "The ONIE initramfs root filesystem"}
    if release:
        rootfs["version"] = release

    # Containment: image -> kernel, bootloader, rootfs; rootfs -> userspace.
    # Use: a package -> each package its fragment builds against.
    edges = {root["bom-ref"]: set(), rootfs["bom-ref"]: set()}
    for c in components:
        edges[c["bom-ref"]] = set()
        top = root["bom-ref"] if parent_of[c["bom-ref"]] == "image" else rootfs["bom-ref"]
        edges[top].add(c["bom-ref"])
    edges[root["bom-ref"]].add(rootfs["bom-ref"])
    for prefix, comp in by_prefix.items():
        frag = next((c["value"] for c in comp["properties"]
                     if c["name"] == "onie:fragment"), "")
        for dep in fragment_deps(frag):
            if dep != prefix and dep in by_prefix:
                edges[comp["bom-ref"]].add(by_prefix[dep]["bom-ref"])

    sbom = {
        "bomFormat": "CycloneDX",
        "specVersion": "1.6",
        "version": 1,
        "metadata": {
            "timestamp": build_timestamp(dirty),
            "component": root,
            "tools": [{"name": "gen-sbom.py", "vendor": "ONIE"}],
        },
        "components": [rootfs] + sorted(components, key=lambda c: c["name"]),
        "dependencies": [{"ref": r, "dependsOn": sorted(d)}
                         for r, d in sorted(edges.items())],
    }
    # A serial derived from the contents: identical builds describe
    # themselves identically.
    body = json.dumps(sbom, sort_keys=True).encode()
    sbom["serialNumber"] = "urn:uuid:%s" % uuid.uuid5(
        uuid.NAMESPACE_URL, "onie-sbom:" + hashlib.sha256(body).hexdigest())
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
