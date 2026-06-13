#!/bin/bash

#  Copyright (C) 2026 Brad House <bhouse@nexthop.ai>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# CI harness: functional discovery-install of the demo OS.
#
# Drives a full ONIE OS-install end to end, headlessly under QEMU:
#   Stage A (install): boot ONIE in OS-install mode pointing discovery at a
#     locally-served demo installer (install_url= on the kernel cmdline; ONIE's
#     sd_static() short-circuits discovery straight to it), install onto a blank
#     virtio disk, and assert "NOS install successful".
#   Stage B (boot NOS): boot the now-installed disk and assert the demo OS
#     comes up ("Welcome to ... DEMO ... platform").
#
# This validates the real installer path -- download, exec_installer, the demo
# installer writing GRUB + the demo OS to disk, and the demo OS booting -- which
# the build/boot-smoke gates do not exercise.
#
# Usage:  ci-install-test.sh <vmlinuz> <initrd> <demo-installer.bin> [timeout]
# Env:    WORKDIR=<dir>  (default mktemp)   SERIAL_PREFIX=<path-prefix>
#
# Requires: qemu-system-x86_64, qemu-img, python3 (http.server).  Bypasses
# GRUB/shim (direct -kernel boot) on purpose -- this phase tests the INSTALLER,
# not the boot chain (the boot chain is covered by ci-boot-test.sh).

set -uo pipefail

VMLINUZ="${1:?usage: ci-install-test.sh <vmlinuz> <initrd> <demo-installer.bin> [timeout]}"
INITRD="${2:?need initrd}"
INSTALLER="${3:?need demo-installer.bin}"
TIMEOUT="${4:-600}"
for f in "$VMLINUZ" "$INITRD" "$INSTALLER"; do
    [ -r "$f" ] || { echo "ERROR: not readable: $f" >&2; exit 2; }
done

WORKDIR="${WORKDIR:-$(mktemp -d)}"; mkdir -p "$WORKDIR"
SERIAL_PREFIX="${SERIAL_PREFIX:-$WORKDIR/install}"
mkdir -p "$(dirname "$SERIAL_PREFIX")"
INSTALL_LOG="${SERIAL_PREFIX}-install.log"
NOS_LOG="${SERIAL_PREFIX}-nos.log"
DISK="$WORKDIR/nos-disk.qcow2"
HTTP_PORT=8919
ACCEL="accel=kvm:tcg"
CONSOLE="console=tty0 console=ttyS0,115200n8"
INSTALLER_NAME="$(basename "$INSTALLER")"

echo "== ONIE install-test =="
echo "   vmlinuz   : $VMLINUZ"
echo "   initrd    : $INITRD"
echo "   installer : $INSTALLER ($INSTALLER_NAME)"
echo "   workdir   : $WORKDIR"
echo "   accel     : kvm:tcg ($([ -w /dev/kvm ] && echo KVM || echo TCG))"

# --- serve the installer over HTTP (guest reaches host at 10.0.2.2 via SLIRP) ---
SERVE_DIR="$(cd "$(dirname "$INSTALLER")" && pwd)"
python3 -m http.server "$HTTP_PORT" --directory "$SERVE_DIR" >"$WORKDIR/http.log" 2>&1 &
HTTP_PID=$!
trap 'kill "$HTTP_PID" 2>/dev/null; [ -n "${KEEP:-}" ] || rm -rf "$WORKDIR"' EXIT
sleep 1
kill -0 "$HTTP_PID" 2>/dev/null || { echo "ERROR: http.server failed"; cat "$WORKDIR/http.log"; exit 2; }
echo "   http      : serving $SERVE_DIR on :$HTTP_PORT (pid $HTTP_PID)"

# --- blank install target disk ---
qemu-img create -f qcow2 "$DISK" 4G >/dev/null 2>&1

INSTALL_URL="http://10.0.2.2:${HTTP_PORT}/${INSTALLER_NAME}"
EMBED_LOG="${SERIAL_PREFIX}-embed.log"

# Boot ONIE (direct -kernel, legacy BIOS, the target disk, user-net) and stop
# QEMU as soon as the serial log hits <ready-regex> or a panic -- ONIE idles at
# a console and never exits, so polling avoids dead-waiting the whole timeout.
# Args:  <serial_log> <boot_reason> <install_url> <ready-regex>
run_onie() {
    local log="$1" reason="$2" url="$3" ready_re="$4"
    : > "$log"
    qemu-system-x86_64 \
        -machine pc,${ACCEL} -m 2048 -smp 2 \
        -kernel "$VMLINUZ" -initrd "$INITRD" \
        -append "quiet ${CONSOLE} boot_env=recovery boot_reason=${reason} install_url=${url}" \
        -drive file="$DISK",if=virtio,format=qcow2 \
        -netdev user,id=n0 -device virtio-net,netdev=n0 \
        -display none -serial "file:$log" -no-reboot \
        >/dev/null 2>&1 &
    wait_serial "$log" "$ready_re"
}

# Poll <log> until <ready-regex> or 'Kernel panic' appears, or TIMEOUT; then
# stop the most recent background QEMU.  Used by every boot in this harness.
wait_serial() {
    local log="$1" ready_re="$2" qpid=$! t=0
    while kill -0 "$qpid" 2>/dev/null; do
        if grep -Eaq "$ready_re" "$log" || grep -aq 'Kernel panic' "$log"; then break; fi
        [ "$t" -ge "$TIMEOUT" ] && break
        sleep 1; t=$((t + 1))
    done
    kill "$qpid" 2>/dev/null; sleep 1; kill -9 "$qpid" 2>/dev/null; wait "$qpid" 2>/dev/null
    echo "   (stopped at ${t}s)"
}

fail=0

# ===================== Stage 0: EMBED ONIE to the disk =====================
# The demo installer installs the NOS onto the disk that already holds ONIE
# (uninstall-arch -> onie_get_boot_dev = `blkid | grep ONIE-BOOT`).  A direct
# -kernel boot has no on-disk ONIE, so embed it first: ONIE's own updater
# (file:///lib/onie/onie-updater, shipped in the recovery initrd) writes ONIE +
# the ONIE-BOOT partition to /dev/vda.  Then the install stage can find it.
echo
echo "== Stage 0: embed ONIE onto the disk =="
# The recovery ISO embeds via file:///lib/onie/onie-updater, but a direct
# -kernel boot's initrd has no onie-updater on a local path -- so serve the
# updater (onie-updater-<platform>, alongside the demo installer in build/images)
# over the same HTTP server and embed from there.
UPDATER_PATH="$(ls "$SERVE_DIR"/onie-updater-* 2>/dev/null | grep -v '\.sig$' | head -1)"
[ -n "$UPDATER_PATH" ] || { echo "ERROR: no onie-updater-* in $SERVE_DIR (run 'make ... all')" >&2; exit 2; }
EMBED_URL="http://10.0.2.2:${HTTP_PORT}/$(basename "$UPDATER_PATH")"
echo "   embed via: $EMBED_URL"
run_onie "$EMBED_LOG" embed "$EMBED_URL" 'ONIE: NOS install successful|ONIE: Rebooting'
echo "== Stage 0 assertions =="
s0_chk() { if grep -Eaq "$2" "$EMBED_LOG"; then echo "   PASS  $1"; else echo "   FAIL  $1  (/$2/)"; fail=1; fi; }
s0_chk "embed ran"        'Embedding ONIE|Installing ONIE|ONIE: Executing installer'
s0_chk "ONIE installed"   'ONIE: NOS install successful|Installed ONIE|ONIE-BOOT|Rebooting'
if grep -aq 'Kernel panic' "$EMBED_LOG"; then echo "   FAIL  panic during embed"; fail=1; fi
if [ "$fail" -ne 0 ]; then
    echo "RESULT: FAIL (embed stage)"
    echo "---- embed serial tail ----"
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\x1b[=>]//g; s/\r/\n/g' "$EMBED_LOG" | grep -avE '^\s*$' | tail -30
    exit 1
fi

# ============================ Stage A: INSTALL ============================
echo
echo "== Stage A: install demo OS (install_url=$INSTALL_URL) =="
run_onie "$INSTALL_LOG" install "$INSTALL_URL" 'NOS install successful|Failure: Unable to install'
echo "== Stage A assertions =="
sa_chk() { if grep -Eaq "$2" "$INSTALL_LOG"; then echo "   PASS  $1"; else echo "   FAIL  $1  (/$2/)"; fail=1; fi; }
sa_chk "discovery started"   'Starting ONIE Service Discovery|ONIE: OS Install Mode'
sa_chk "installer executed"  'Executing installer:|Demo Installer:'
sa_chk "NOS install success"  'NOS install successful'
if grep -aq 'Kernel panic' "$INSTALL_LOG"; then echo "   FAIL  kernel panic during install"; fail=1; fi

if [ "$fail" -ne 0 ]; then
    echo "RESULT: FAIL (install stage)"
    echo "---- install serial tail ----"
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\x1b[=>]//g; s/\r/\n/g' "$INSTALL_LOG" | grep -avE '^\s*$' | tail -40
    exit 1
fi

# ============================ Stage B: BOOT NOS ============================
echo
echo "== Stage B: boot installed demo OS from disk =="
: > "$NOS_LOG"
qemu-system-x86_64 \
    -machine pc,${ACCEL} -m 2048 -smp 2 \
    -drive file="$DISK",if=virtio,format=qcow2 \
    -netdev user,id=n0 -device virtio-net,netdev=n0 \
    -boot c \
    -display none -serial "file:$NOS_LOG" -no-reboot \
    >/dev/null 2>&1 &
wait_serial "$NOS_LOG" 'Welcome to the .*DEMO.*platform|DEMO GNU/Linux|demo login:'

echo "== Stage B assertions =="
sb_chk() { if grep -Eaq "$2" "$NOS_LOG"; then echo "   PASS  $1"; else echo "   FAIL  $1  (/$2/)"; fail=1; fi; }
sb_chk "demo OS booted"  'Welcome to the .*DEMO.*platform|DEMO GNU/Linux|demo login:'
if grep -aq 'Kernel panic' "$NOS_LOG"; then echo "   FAIL  kernel panic booting NOS"; fail=1; fi

if [ "$fail" -eq 0 ]; then
    echo "RESULT: PASS (demo OS installed via discovery and booted)"; exit 0
else
    echo "RESULT: FAIL (NOS boot stage)"
    echo "---- nos serial tail ----"
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\x1b[=>]//g; s/\r/\n/g' "$NOS_LOG" | grep -avE '^\s*$' | tail -40
    exit 1
fi
