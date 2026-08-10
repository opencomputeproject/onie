#!/bin/sh
#
# build-onie-kvm.sh - Reproducible ONIE KVM build for DHCPv6 (RFC 5970) validation.
#
# This wraps the Docker `onie-build` container build of the patched ONIE tree
# (branch feature/dhcp6-boot-validation) with the two build-config overrides
# required to build the DHCPv6 network-boot feature on KVM with Secure Boot OFF.
#
# It runs in three phases:
#   (a) back up the two build-config files (.orig) and apply the overrides,
#   (b) build inside the container,
#   (c) restore the originals (unless --keep-overrides), leaving the tree pristine.
#
# A trap restores the .orig backups on ANY exit (including interrupt), so an
# aborted build never leaves the source tree dirty.
#
# The overrides applied (see build-config-overrides/*.patch):
#   * machine/kvm_x86_64/machine.make   - SECURE_BOOT_ENABLE/EXT, SECURE_GRUB -> no
#   * machine/kvm_x86_64/kernel/config  - disable module-signing / X.509 / PKCS /
#                                         trusted keyring; add CONFIG_IPV6_AUTOCONF=y
#
# NOT applied: the build-config/make/busybox.make .PHONY edit. That is an
# incremental-rebuild speed hack with no effect on a clean --rm container build,
# and it can silently skip re-applying an edited busybox patch. Excluded on purpose.
#
# POSIX sh. Idempotent (safe to re-run). Parameterized via env vars / flags.
#
# Usage:
#   ./build-onie-kvm.sh [--keep-overrides] [--no-build] [--jobs N]
#
# Env vars (all optional):
#   ONIE_TREE        Path to the ONIE source tree (default: two levels up from
#                    this script: contrib/dhcp6-emulation/.. -> repo root).
#   ONIE_BUILD_IMAGE Docker image tag for the build container (default onie-build).
#   MACHINE          ONIE machine target (default kvm_x86_64).
#   GIT_USER_EMAIL   git identity injected in the container (default onie-ci@example.com).
#   GIT_USER_NAME    git identity injected in the container (default "ONIE CI").
#   JOBS             parallel make jobs (default 4).
#
set -eu

# --------------------------------------------------------------------------
# Resolve paths
# --------------------------------------------------------------------------
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
OVERRIDE_DIR="$SCRIPT_DIR/build-config-overrides"

# repo root = contrib/dhcp6-emulation -> ../..
DEFAULT_TREE=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
ONIE_TREE=${ONIE_TREE:-$DEFAULT_TREE}

ONIE_BUILD_IMAGE=${ONIE_BUILD_IMAGE:-onie-build}
MACHINE=${MACHINE:-kvm_x86_64}
GIT_USER_EMAIL=${GIT_USER_EMAIL:-onie-ci@example.com}
GIT_USER_NAME=${GIT_USER_NAME:-ONIE CI}
JOBS=${JOBS:-4}
# Always use docker with --network host so the build container inherits the
# host's network stack. Required on IPv6-only hosts where the default docker
# bridge has no route to the outside world.
DOCKER=${DOCKER:-docker}
DOCKER_NETWORK=${DOCKER_NETWORK:-host}

KEEP_OVERRIDES=no
DO_BUILD=yes

while [ $# -gt 0 ]; do
    case "$1" in
        --keep-overrides) KEEP_OVERRIDES=yes ;;
        --no-build)       DO_BUILD=no ;;
        --jobs)           shift; JOBS=${1:?--jobs needs an argument} ;;
        -h|--help)
            sed -n '2,40p' "$0"
            exit 0 ;;
        *) echo "build-onie-kvm.sh: unknown argument: $1" >&2; exit 2 ;;
    esac
    shift
done

MACHINE_MAKE="$ONIE_TREE/machine/$MACHINE/machine.make"
KERNEL_CONFIG="$ONIE_TREE/machine/$MACHINE/kernel/config"

MACHINE_MAKE_PATCH="$OVERRIDE_DIR/machine.make.patch"
KERNEL_CONFIG_PATCH="$OVERRIDE_DIR/kernel-config.patch"

log()  { echo "[build-onie-kvm] $*"; }
die()  { echo "[build-onie-kvm] ERROR: $*" >&2; exit 1; }

[ -f "$MACHINE_MAKE" ]   || die "machine.make not found: $MACHINE_MAKE"
[ -f "$KERNEL_CONFIG" ]  || die "kernel/config not found: $KERNEL_CONFIG"
[ -f "$MACHINE_MAKE_PATCH" ]  || die "override patch missing: $MACHINE_MAKE_PATCH"
[ -f "$KERNEL_CONFIG_PATCH" ] || die "override patch missing: $KERNEL_CONFIG_PATCH"

# --------------------------------------------------------------------------
# Restore trap: put the .orig backups back on ANY exit unless --keep-overrides.
# --------------------------------------------------------------------------
restore_overrides() {
    [ "$KEEP_OVERRIDES" = yes ] && { log "--keep-overrides: leaving overrides in place"; return; }
    if [ -f "$MACHINE_MAKE.orig" ]; then
        mv -f "$MACHINE_MAKE.orig" "$MACHINE_MAKE"
        log "restored $MACHINE_MAKE"
    fi
    if [ -f "$KERNEL_CONFIG.orig" ]; then
        mv -f "$KERNEL_CONFIG.orig" "$KERNEL_CONFIG"
        log "restored $KERNEL_CONFIG"
    fi
}
trap restore_overrides EXIT INT TERM

# --------------------------------------------------------------------------
# (a) Back up originals and apply overrides.
# --------------------------------------------------------------------------
apply_override() {
    # $1 = target file, $2 = patch file
    target=$1; patch=$2
    if [ -f "$target.orig" ]; then
        # A prior run left a backup: restore it first so re-apply is clean (idempotent).
        cp -f "$target.orig" "$target"
    else
        cp -f "$target" "$target.orig"
    fi
    if git -C "$ONIE_TREE" apply --check "$patch" 2>/dev/null; then
        git -C "$ONIE_TREE" apply "$patch"
        log "applied override: $(basename "$patch")"
    else
        die "override patch does not apply cleanly: $patch
     The source file may already differ from the captured baseline. Inspect manually."
    fi
}

log "ONIE tree:      $ONIE_TREE"
log "machine:        $MACHINE"
log "build image:    $ONIE_BUILD_IMAGE"
log "applying build-config overrides (Secure Boot off + CONFIG_IPV6_AUTOCONF=y) ..."
apply_override "$MACHINE_MAKE"  "$MACHINE_MAKE_PATCH"
apply_override "$KERNEL_CONFIG" "$KERNEL_CONFIG_PATCH"

# --------------------------------------------------------------------------
# (b) Container build.
# --------------------------------------------------------------------------
if [ "$DO_BUILD" = no ]; then
    log "--no-build: overrides applied; skipping container build."
    log "Remember the tree will be restored on exit unless --keep-overrides."
    exit 0
fi

command -v "$DOCKER" >/dev/null 2>&1 || die "docker not found on PATH (this step must run on a Docker-capable host)."

# Build the build container if it is not present yet.
if ! "$DOCKER" image inspect "$ONIE_BUILD_IMAGE" >/dev/null 2>&1; then
    log "build container image '$ONIE_BUILD_IMAGE' not found; building from contrib/dhcp6-emulation/Dockerfile.build ..."
    log "(Using local Dockerfile.build which fixes debian:9/stretch EOL archive redirect)"
    "$DOCKER" build --network "$DOCKER_NETWORK" \
        -t "$ONIE_BUILD_IMAGE" \
        -f "$SCRIPT_DIR/Dockerfile.build" \
        "$SCRIPT_DIR"
fi

# Why the in-container `git config`:
#   under `--user $(id -u):$(id -g)` + HOME=/tmp the container's baked-in
#   .gitconfig is bypassed, and busybox patch application (git/stgit) aborts
#   without *some* identity. So we inject one.
log "running container build: make -j$JOBS MACHINE=$MACHINE all recovery-iso demo  (using $DOCKER --network $DOCKER_NETWORK)"
"$DOCKER" run --user "$(id -u):$(id -g)" --rm \
    --network "$DOCKER_NETWORK" \
    -v "$ONIE_TREE":/home/build/src/onie \
    -w /home/build/src/onie/build-config \
    -e HOME=/tmp \
    "$ONIE_BUILD_IMAGE" \
    sh -c "git config --global user.email '$GIT_USER_EMAIL' && \
           git config --global user.name '$GIT_USER_NAME' && \
           make -j$JOBS MACHINE=$MACHINE all recovery-iso demo"

# --------------------------------------------------------------------------
# Artifact listing.
# --------------------------------------------------------------------------
IMAGES_DIR="$ONIE_TREE/build/images"
log "build complete. Artifacts in $IMAGES_DIR:"
if [ -d "$IMAGES_DIR" ]; then
    ls -l "$IMAGES_DIR" || true
    echo
    log "Expected artifacts:"
    for f in \
        "$MACHINE-r0.vmlinuz" \
        "$MACHINE-r0.initrd" \
        "onie-updater-x86_64-$MACHINE-r0" \
        "onie-recovery-x86_64-$MACHINE-r0.iso" \
        "demo-installer-x86_64-$MACHINE-r0.bin"
    do
        if [ -e "$IMAGES_DIR/$f" ]; then echo "  [ok]      $f"; else echo "  [MISSING] $f"; fi
    done
else
    die "no build/images directory produced - build likely failed."
fi

# (c) restore happens via the EXIT trap.
log "done."
