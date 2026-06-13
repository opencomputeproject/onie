#!/bin/bash

#  Copyright (C) 2026 Brad House <bhouse@nexthop.ai>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# Download, verify (sha256) and install the SBOM/license tooling (askalono,
# cyclonedx-cli, grype) used by scripts/gen-sbom.py.  Modeled after SONiC's
# install_sbom_tool.sh: versions are pinned and every download is verified
# against a hardcoded SHA-256 hash.  Any download failure or hash mismatch is
# fatal (exit 1).  Re-running is idempotent: a tool already present at the
# pinned version is skipped.
#
# The install directory defaults to /usr/local/bin (system-wide, needs root),
# but can be overridden so the build can provision the tools into a writable
# build-local prefix without root:
#
#     install-sbom-tools.sh [INSTALL_DIR]
#     SBOM_TOOLS_DIR=/path/to/bin install-sbom-tools.sh
#
# The ONIE build (make/sbom.make) invokes it this way automatically when the
# tools are not already on PATH.
#
# Requires: curl, unzip, tar.
#

set -euo pipefail

INSTALL_DIR="${1:-${SBOM_TOOLS_DIR:-/usr/local/bin}}"
mkdir -p "$INSTALL_DIR"

# -- Pinned versions ---------------------------------------------------------
ASKALONO_VERSION="0.5.0"
CYCLONEDX_VERSION="0.32.0"
GRYPE_VERSION="0.113.0"

# -- Pinned download URLs ----------------------------------------------------
ASKALONO_URL="https://github.com/jpeddicord/askalono/releases/download/${ASKALONO_VERSION}/askalono-Linux.zip"
CYCLONEDX_URL="https://github.com/CycloneDX/cyclonedx-cli/releases/download/v${CYCLONEDX_VERSION}/cyclonedx-linux-x64"
GRYPE_URL="https://github.com/anchore/grype/releases/download/v${GRYPE_VERSION}/grype_${GRYPE_VERSION}_linux_amd64.tar.gz"

# -- Pinned SHA-256 hashes ---------------------------------------------------
ASKALONO_SHA256="8a007355b700137b48e7e39aab5d083acb9a0926f20c064ab4476b1624390e52"
CYCLONEDX_SHA256="454879e6a4a405c8a13bff49b8982adcb0596f3019b26b0811c66e4d7f0783e1"
GRYPE_SHA256="d87059d11616446a5dd817a47c21823676b4b24bdaac529695ca404a32ba339d"

# verify_sha256 <file> <expected-sha256>
verify_sha256() {
    local file="$1"
    local expected="$2"
    local actual

    actual=$(sha256sum "$file" | awk '{print $1}')
    if [ "$actual" != "$expected" ]; then
        echo "Error: sha256 mismatch for $file" >&2
        echo "  expected: $expected" >&2
        echo "  actual:   $actual" >&2
        exit 1
    fi
}

# download <url> <dest>
download() {
    local url="$1"
    local dest="$2"

    echo "Downloading $url"
    if ! curl -fsSL -o "$dest" "$url"; then
        echo "Error: failed to download $url" >&2
        exit 1
    fi
}

install_askalono() {
    if [ -x "${INSTALL_DIR}/askalono" ] && \
       "${INSTALL_DIR}/askalono" --version 2>/dev/null | grep -q "${ASKALONO_VERSION}"; then
        echo "askalono ${ASKALONO_VERSION} already installed, skipping"
        return 0
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    download "$ASKALONO_URL" "${tmpdir}/askalono-Linux.zip"
    verify_sha256 "${tmpdir}/askalono-Linux.zip" "$ASKALONO_SHA256"
    unzip -o -q "${tmpdir}/askalono-Linux.zip" -d "$tmpdir"
    install -m 0755 "${tmpdir}/askalono" "${INSTALL_DIR}/askalono"
    rm -rf "$tmpdir"
    echo "Installed askalono ${ASKALONO_VERSION} to ${INSTALL_DIR}/askalono"
}

install_cyclonedx() {
    if [ -x "${INSTALL_DIR}/cyclonedx-cli" ] && \
       "${INSTALL_DIR}/cyclonedx-cli" --version 2>/dev/null | grep -q "${CYCLONEDX_VERSION}"; then
        echo "cyclonedx-cli ${CYCLONEDX_VERSION} already installed, skipping"
        return 0
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    download "$CYCLONEDX_URL" "${tmpdir}/cyclonedx-cli"
    verify_sha256 "${tmpdir}/cyclonedx-cli" "$CYCLONEDX_SHA256"
    install -m 0755 "${tmpdir}/cyclonedx-cli" "${INSTALL_DIR}/cyclonedx-cli"
    rm -rf "$tmpdir"
    echo "Installed cyclonedx-cli ${CYCLONEDX_VERSION} to ${INSTALL_DIR}/cyclonedx-cli"
}

install_grype() {
    if [ -x "${INSTALL_DIR}/grype" ] && \
       "${INSTALL_DIR}/grype" version 2>/dev/null | grep -q "${GRYPE_VERSION}"; then
        echo "grype ${GRYPE_VERSION} already installed, skipping"
        return 0
    fi

    local tmpdir
    tmpdir=$(mktemp -d)
    download "$GRYPE_URL" "${tmpdir}/grype.tar.gz"
    verify_sha256 "${tmpdir}/grype.tar.gz" "$GRYPE_SHA256"
    tar -xzf "${tmpdir}/grype.tar.gz" -C "$tmpdir" grype
    install -m 0755 "${tmpdir}/grype" "${INSTALL_DIR}/grype"
    rm -rf "$tmpdir"
    echo "Installed grype ${GRYPE_VERSION} to ${INSTALL_DIR}/grype"
}

install_askalono
install_cyclonedx
install_grype

echo "SBOM tooling installation complete"
