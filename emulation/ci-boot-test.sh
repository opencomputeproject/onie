#!/bin/bash

#  Copyright (C) 2026 Brad House <bhouse@nexthop.ai>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# CI boot-validation harness for the kvm_x86_64 ONIE recovery image.
#
# Boots the recovery ISO headlessly under QEMU + OVMF (UEFI), captures the
# serial console, and asserts that ONIE boots PAST GRUB INTO THE OS.  ONIE
# routes GRUB, the kernel and userspace all to ttyS0, so a serial capture is
# sufficient -- no graphical/OCR interaction is needed.
#
# PASS  = all boot milestones observed AND no kernel panic.
# FAIL  = a milestone is missing or the kernel panicked (e.g. init died).
#
# Two modes (BOOT_MODE):
#   relaxed     (default) Secure-Boot-RELAXED: plain OVMF varstore, no keys
#               enrolled.  shim still chainloads grub->kernel, so it validates
#               "does it boot" independent of the SB signature chain.  Boots on
#               the default 'pc' machine (ONIE's onie-vm.sh reference machine).
#   secureboot  Secure-Boot-ENFORCED: enrolls the demonstration PK/KEK/db from
#               KEYS_DIR into an OVMF varstore (virt-fw-vars), boots the secboot
#               OVMF firmware on 'q35,smm=on' with the flash secure flag, and
#               asserts ONIE boots -- i.e. the shim/grub/kernel signing chain
#               verifies under enforcement.  Also runs a NEGATIVE control with
#               the db omitted, which MUST be rejected (proves SB is enforcing,
#               not merely permissive).
#
# Usage:  ci-boot-test.sh <recovery.iso> [timeout_secs]
# Env:    SERIAL_LOG=<path>   serial log path (default ./onie-boot-serial.log)
#         BOOT_MODE=relaxed|secureboot     (default relaxed)
#         KEYS_DIR=<dir>      encryption/machines/kvm_x86_64/keys (secureboot)
#
# Requires on the host: qemu-system-x86_64, ovmf (apt: qemu-system-x86 ovmf).
# secureboot mode additionally needs virt-fw-vars (apt: python3-virt-firmware).
# On GitHub Actions, add the kvm udev rule first so /dev/kvm is usable; QEMU
# falls back to TCG automatically via accel=kvm:tcg if KVM is unavailable.

set -uo pipefail

ISO="${1:?usage: ci-boot-test.sh <recovery.iso> [timeout_secs]}"
TIMEOUT="${2:-300}"
SERIAL_LOG="${SERIAL_LOG:-onie-boot-serial.log}"
BOOT_MODE="${BOOT_MODE:-relaxed}"

# Terminal-state markers run_qemu polls for (to stop QEMU as soon as the outcome
# is decided instead of waiting out the timeout):
#  READY_BOOT - a successful boot has reached the ONIE console/discovery prompt.
#  READY_NEG  - the SB negative control has resolved: either rejected (expected)
#               or, unexpectedly, reached GRUB/ONIE (caught by the assertions).
READY_BOOT='Please press Enter to activate this console|discover: (ONIE|Rescue)|Starting ONIE Service Discovery'
READY_NEG='Security Violation|Access Denied|verification failed|GNU GRUB|ONIE: (OS Install|Rescue) Mode'

[ -r "$ISO" ] || { echo "ERROR: ISO not readable: $ISO" >&2; exit 2; }

# A fixed owner GUID for the enrolled demo keys -- deterministic on purpose so
# runs are reproducible; the value is immaterial for boot verification.
SB_OWNER_GUID="a9b1c2d3-0011-4caf-8bad-f00d0c1e0001"

# --- locate OVMF firmware (Ubuntu 24.04 dropped the 2MB files -> probe _4M first) ---
OVMF_CODE=""; OVMF_CODE_SB=""; OVMF_VARS_SRC=""
for c in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd \
         /usr/share/edk2/ovmf/OVMF_CODE.fd; do
    [ -f "$c" ] && OVMF_CODE="$c" && break
done
for c in /usr/share/OVMF/OVMF_CODE_4M.secboot.fd /usr/share/OVMF/OVMF_CODE.secboot.fd \
         /usr/share/edk2/ovmf/OVMF_CODE.secboot.fd; do
    [ -f "$c" ] && OVMF_CODE_SB="$c" && break
done
for v in /usr/share/OVMF/OVMF_VARS_4M.fd /usr/share/OVMF/OVMF_VARS.fd \
         /usr/share/edk2/ovmf/OVMF_VARS.fd; do
    [ -f "$v" ] && OVMF_VARS_SRC="$v" && break
done
[ -n "$OVMF_CODE" ] && [ -n "$OVMF_VARS_SRC" ] || {
    echo "ERROR: OVMF firmware not found (apt install ovmf)" >&2; exit 2; }

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# --- boot QEMU headless, serial(ttyS0) -> file, -no-reboot so a panic doesn't
#     loop.  Polls the serial log and stops QEMU as soon as the boot reaches a
#     terminal state (the <ready-regex>, e.g. the console prompt) or panics --
#     ONIE boots to an idle console and never exits, so without this we would
#     dead-wait the full timeout on every (successful) boot.  The timeout is now
#     only hit by a genuinely stuck boot.
#     Args:  <ready-regex> <code.fd> <vars.fd> <serial_log> [extra qemu args...]
run_qemu() {
    local ready_re="$1" code="$2" vars="$3" log="$4"; shift 4
    : >"$log"
    qemu-system-x86_64 \
        -m 2048 -smp 2 \
        -drive if=pflash,format=raw,readonly=on,file="$code" \
        -drive if=pflash,format=raw,file="$vars" \
        -cdrom "$ISO" -boot d \
        -netdev user,id=onienet -device virtio-net,netdev=onienet \
        -display none -serial "file:$log" -no-reboot \
        "$@" >/dev/null 2>&1 &
    local qpid=$! t=0
    while kill -0 "$qpid" 2>/dev/null; do
        if grep -Eaq "$ready_re" "$log" || grep -aq 'Kernel panic' "$log"; then break; fi
        [ "$t" -ge "$TIMEOUT" ] && break
        sleep 1; t=$((t + 1))
    done
    kill "$qpid" 2>/dev/null; sleep 1; kill -9 "$qpid" 2>/dev/null; wait "$qpid" 2>/dev/null
    if grep -aq 'Kernel panic' "$log"; then        echo "   (stopped at ${t}s: kernel panic)"
    elif grep -Eaq "$ready_re" "$log"; then         echo "   (stopped at ${t}s: reached terminal state)"
    else                                            echo "   (stopped at ${t}s: TIMEOUT, no terminal marker)"; fi
}

# --- assert the ONIE boot milestones in a captured serial log.  Sets `fail`. ---
fail=0
chk() {  # <logfile> <label> <extended-regex>
    if grep -Eaq "$3" "$1"; then echo "   PASS  $2"
    else echo "   FAIL  $2   (/$3/)"; fail=1; fi
}
assert_booted() {  # <logfile>
    local log="$1"
    [ -s "$log" ] || { echo "   FAIL  no serial output captured"; fail=1; return; }
    chk "$log" "GRUB reached"   'GNU GRUB|Booting .ONIE'
    chk "$log" "ONIE userspace" 'ONIE: (OS Install|Rescue) Mode|^Version   :'
    chk "$log" "console up"     'Please press Enter to activate this console|discover: (ONIE|Rescue)|Starting ONIE Service Discovery'
    if grep -aq 'Kernel panic' "$log"; then
        echo "   FAIL  kernel panicked:"; grep -a 'Kernel panic' "$log" | sed 's/^/         /'
        fail=1
    fi
}
dump_tail() {  # <logfile>
    echo "---- serial tail ($1) ----"
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\x1b[=>]//g; s/\r/\n/g' "$1" \
        | grep -avE '^\s*$' | tail -25
}

echo "== ONIE boot-test =="
echo "   ISO        : $ISO"
echo "   mode       : $BOOT_MODE"
echo "   serial log : $SERIAL_LOG"
echo "   timeout    : ${TIMEOUT}s"
echo "   accel      : kvm:tcg ($([ -w /dev/kvm ] && echo 'KVM' || echo 'TCG (no /dev/kvm)'))"

if [ "$BOOT_MODE" = "relaxed" ]; then
    echo "   OVMF code  : $OVMF_CODE (SB-relaxed)"
    cp "$OVMF_VARS_SRC" "$WORK/vars.fd"   # writable per-run varstore copy
    run_qemu "$READY_BOOT" "$OVMF_CODE" "$WORK/vars.fd" "$SERIAL_LOG" -machine accel=kvm:tcg
    echo "== milestones =="
    assert_booted "$SERIAL_LOG"

elif [ "$BOOT_MODE" = "secureboot" ]; then
    # --- Secure-Boot-ENFORCED validation ---
    KEYS_DIR="${KEYS_DIR:?secureboot mode requires KEYS_DIR=.../keys}"
    [ -d "$KEYS_DIR" ] || { echo "ERROR: KEYS_DIR not a directory: $KEYS_DIR" >&2; exit 2; }
    [ -n "$OVMF_CODE_SB" ] || { echo "ERROR: secboot OVMF not found (OVMF_CODE_4M.secboot.fd)" >&2; exit 2; }
    command -v virt-fw-vars >/dev/null || { echo "ERROR: virt-fw-vars missing (apt install python3-virt-firmware)" >&2; exit 2; }

    PK="$KEYS_DIR/HW/efi-keys/HW-platform-key-cert.pem"
    KEK_SW="$KEYS_DIR/SW/efi-keys/SW-key-exchange-key-cert.pem"
    KEK_HW="$KEYS_DIR/HW/efi-keys/HW-key-exchange-key-cert.pem"
    DB_SW="$KEYS_DIR/SW/efi-keys/SW-database-key-cert.pem"   # this verifies shim
    DB_HW="$KEYS_DIR/HW/efi-keys/HW-database-key-cert.pem"
    for f in "$PK" "$KEK_SW" "$KEK_HW" "$DB_SW" "$DB_HW"; do
        [ -r "$f" ] || { echo "ERROR: missing demo key: $f" >&2; exit 2; }
    done

    SB_QEMU_ARGS=(-machine q35,smm=on,accel=kvm:tcg
                  -global driver=cfi.pflash01,property=secure,value=on)
    echo "   OVMF code  : $OVMF_CODE_SB (SB-enforced, q35,smm=on)"

    # Positive: PK + KEK + db (incl. the SW-database key that signs shim).
    echo "== [secureboot] enrolling PK/KEK/db (positive) =="
    virt-fw-vars --input "$OVMF_VARS_SRC" --output "$WORK/vars.pos.fd" \
        --set-pk  "$SB_OWNER_GUID" "$PK" \
        --add-kek "$SB_OWNER_GUID" "$KEK_SW" --add-kek "$SB_OWNER_GUID" "$KEK_HW" \
        --add-db  "$SB_OWNER_GUID" "$DB_SW"  --add-db  "$SB_OWNER_GUID" "$DB_HW" \
        --secure-boot 2>&1 | sed 's/^/   /' | grep -Ei 'error|fail|add (pk|kek|db)|secure' || true

    echo "== [secureboot] booting SB-ENFORCED (must boot) =="
    run_qemu "$READY_BOOT" "$OVMF_CODE_SB" "$WORK/vars.pos.fd" "$SERIAL_LOG" "${SB_QEMU_ARGS[@]}"
    echo "== milestones =="
    assert_booted "$SERIAL_LOG"
    # An SB rejection of our own signed chain is a hard fail (chain broke).
    if grep -Eaiq 'Security Violation|Access Denied|verification failed|image (failed|did not pass)' "$SERIAL_LOG"; then
        echo "   FAIL  secure-boot rejected the signed image (chain broken):"
        grep -Eai 'Security Violation|Access Denied|verification failed' "$SERIAL_LOG" | sed 's/^/         /' | head
        fail=1
    fi

    # Negative control: enroll PK + KEK but OMIT db.  The ONIE shim is now
    # untrusted, so an *enforcing* firmware MUST refuse to load it.  If ONIE
    # boots anyway, SB is not actually being enforced -> the positive result
    # is meaningless, so this is a hard fail.
    NEG_LOG="${SERIAL_LOG%.log}-negative.log"; [ "$NEG_LOG" = "$SERIAL_LOG" ] && NEG_LOG="$SERIAL_LOG.negative"
    echo "== [secureboot] enrolling PK/KEK, NO db (negative control) =="
    virt-fw-vars --input "$OVMF_VARS_SRC" --output "$WORK/vars.neg.fd" \
        --set-pk  "$SB_OWNER_GUID" "$PK" \
        --add-kek "$SB_OWNER_GUID" "$KEK_SW" \
        --secure-boot 2>&1 | sed 's/^/   /' | grep -Ei 'error|fail|secure' || true
    echo "== [secureboot] booting NEGATIVE (must be REJECTED) =="
    # Negative boot rejects fast; cap its wait so it doesn't burn the full timeout.
    ( TIMEOUT=$(( TIMEOUT < 90 ? TIMEOUT : 90 )); run_qemu "$READY_NEG" "$OVMF_CODE_SB" "$WORK/vars.neg.fd" "$NEG_LOG" "${SB_QEMU_ARGS[@]}" )
    echo "== negative assertions =="
    if grep -Eaq 'GNU GRUB|ONIE: (OS Install|Rescue) Mode|Please press Enter to activate this console' "$NEG_LOG"; then
        echo "   FAIL  ONIE booted with db absent -> secure boot is NOT being enforced"
        fail=1
    else
        echo "   PASS  ONIE did not boot without db (as required)"
    fi
    if grep -Eaiq 'Security Violation|Access Denied|verification failed|image (failed|did not pass)' "$NEG_LOG"; then
        echo "   PASS  firmware rejected the untrusted image:"
        grep -Eai 'Security Violation|Access Denied|verification failed' "$NEG_LOG" | sed 's/^/         /' | head -3
    else
        # No explicit rejection string AND it didn't boot -- acceptable, but note it.
        echo "   NOTE  no explicit rejection string; relying on absence-of-boot above"
    fi
    [ -f "$NEG_LOG" ] && [ "$fail" -ne 0 ] && dump_tail "$NEG_LOG"

else
    echo "ERROR: unknown BOOT_MODE '$BOOT_MODE' (expected relaxed|secureboot)" >&2
    exit 2
fi

if [ "$fail" -eq 0 ]; then
    echo "RESULT: PASS ($BOOT_MODE -- ONIE booted past GRUB into the OS)"; exit 0
else
    echo "RESULT: FAIL ($BOOT_MODE)"
    dump_tail "$SERIAL_LOG"
    exit 1
fi
