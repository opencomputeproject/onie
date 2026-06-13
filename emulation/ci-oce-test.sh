#!/bin/bash

#  Copyright (C) 2026 Brad House <bhouse@nexthop.ai>
#
#  SPDX-License-Identifier:     GPL-2.0

#
# OCE (ONIE Compliance Environment) CI harness.
#
# Drives ONIE's own contrib/oce/test-onie.py compliance suite against the
# kvm_x86_64 image, headless under QEMU.  Where install-test hands ONIE the
# installer URL directly (install_url=), this exercises the REAL OCP discovery
# paths: for each selected OCE test, OCE generates the matching server set
# (isc-dhcp-server with the ONIE VIVSO option, nginx, tftpd-hpa, dnsmasq) and
# ONIE must discover + fetch the installer itself.  USB tests instead attach a
# USB mass-storage image carrying the installer.
#
# Each test runs a FULL install: ONIE discovers via the method, fetches the
# installer, and installs it -- the harness asserts "ONIE: NOS install
# successful".  To avoid re-embedding per test, ONIE is embedded onto a base
# disk ONCE up front; each test gets a fresh copy-on-write qcow2 overlay of that
# base (instant reset) as its install target.
#
# Tests run CHAINED (one VM at a time), ordered fast->slow, and the run STOPS on
# the first failure (fail-fast).  Each test is capped by a timeout so a method
# that never installs fails in bounded time instead of looping ONIE's
# retry/sleep waterfall forever.
#
# Usage:  ci-oce-test.sh <vmlinuz> <initrd> <demo-installer> <onie-updater> [scope]
#   scope: "default" (broad per-method installer+updater set, the per-PR sweep),
#          "full" (every feasible test 3-121), or an explicit space/comma list
#          of test numbers.  Default: "default".
# Env:    OCE_DIR=<contrib/oce>  OCE_PYTHON=<python3 w/ oce deps>
#         SERIAL_PREFIX=<path-prefix>  WORKDIR=<dir>  TAP=<ifname>
#         PER_TEST_TIMEOUT=<secs, default 180>
#
# Requires (install in the workflow): qemu-system-x86_64, qemu-utils, dosfstools,
# isc-dhcp-server, nginx, tftpd-hpa, dnsmasq, and python3 with
# jinja2/netifaces/psutil.  Needs sudo.  ONIE is serial end-to-end -> no OCR.

set -uo pipefail

VMLINUZ="${1:?usage: ci-oce-test.sh <vmlinuz> <initrd> <demo-installer> <onie-updater> [scope]}"
INITRD="${2:?need initrd}"
INSTALLER="${3:?need demo-installer.bin}"
UPDATER="${4:?need onie-updater}"
SCOPE="${5:-default}"
for f in "$VMLINUZ" "$INITRD" "$INSTALLER" "$UPDATER"; do
    [ -r "$f" ] || { echo "ERROR: not readable: $f" >&2; exit 2; }
done
VMLINUZ="$(realpath "$VMLINUZ")"; INITRD="$(realpath "$INITRD")"
INSTALLER="$(realpath "$INSTALLER")"; UPDATER="$(realpath "$UPDATER")"

OCE_DIR="${OCE_DIR:-$(cd "$(dirname "$0")/../contrib/oce" 2>/dev/null && pwd)}"
OCE_PYTHON="${OCE_PYTHON:-python3}"
[ -r "$OCE_DIR/test-onie.py" ] || { echo "ERROR: OCE not found at OCE_DIR=$OCE_DIR" >&2; exit 2; }

WORKDIR="${WORKDIR:-$(mktemp -d)}"; mkdir -p "$WORKDIR"
SERIAL_PREFIX="${SERIAL_PREFIX:-$WORKDIR/oce}"; mkdir -p "$(dirname "$SERIAL_PREFIX")"
TAP="${TAP:-onie-oce0}"
HOST_V4="192.168.1.1"; DUT_V4="192.168.1.100"; CIDR="24"; DUT_MAC="52:54:00:0c:e0:01"
PER_TEST_TIMEOUT="${PER_TEST_TIMEOUT:-180}"
EMBED_PORT=8920
ACCEL="accel=kvm:tcg"; CONSOLE="console=tty0 console=ttyS0,115200n8"
BASE_DISK="$WORKDIR/onie-base.qcow2"

# ---- test sets (ordered fast->slow: USB/DHCP-direct, then DHCP+server, then no-DHCP/fallback) ----
DEFAULT_TESTS="3 9 10 69 70 11 12 13 14 20 26 32 71 72 73 74 80 86 92 44 50 56 104 110 116"
FULL_TESTS="$(seq 3 121)"
case "$SCOPE" in
    default) TESTS="$DEFAULT_TESTS" ;;
    full)    TESTS="$FULL_TESTS" ;;
    *)       TESTS="$(echo "$SCOPE" | tr ',' ' ')" ;;
esac

echo "== ONIE OCE compliance sweep (full install) =="
echo "   scope     : $SCOPE  ($(echo $TESTS | wc -w) tests)"
echo "   tap iface : $TAP ($HOST_V4/$CIDR, DUT $DUT_V4 mac $DUT_MAC)"
echo "   accel     : kvm:tcg ($([ -w /dev/kvm ] && echo KVM || echo TCG))"
echo "   per-test  : ${PER_TEST_TIMEOUT}s cap"

stop_services() {
    sudo pkill -f "dhcpd.leases.oce" 2>/dev/null
    sudo pkill -f "nginx.*$WORKDIR" 2>/dev/null
    sudo pkill -x in.tftpd 2>/dev/null
    sudo pkill -f "dnsmasq.*$WORKDIR" 2>/dev/null
    true
}
cleanup() {
    stop_services
    sudo ip link del "$TAP" 2>/dev/null
    [ -n "${KEEP:-}" ] || rm -rf "$WORKDIR"
}
trap cleanup EXIT

# ---- poll a serial log until a marker (regex) or panic or timeout; kill QEMU; echo elapsed ----
wait_marker() {  # <log> <success-regex> <timeout>
    local log="$1" ok_re="$2" tmo="$3" qpid=$! t=0
    while kill -0 "$qpid" 2>/dev/null; do
        grep -Eaq "$ok_re" "$log" && break
        grep -aq 'Kernel panic' "$log" && break
        [ "$t" -ge "$tmo" ] && break
        sleep 1; t=$((t + 1))
    done
    kill "$qpid" 2>/dev/null; sleep 1; kill -9 "$qpid" 2>/dev/null; wait "$qpid" 2>/dev/null
    echo "$t"
}

# ---- one-time setup: stop conflicting services, set up the tap ----
echo "== setup =="
sudo systemctl stop nginx isc-dhcp-server dnsmasq tftpd-hpa 2>/dev/null
sudo pkill -x nginx 2>/dev/null; sudo pkill -x dnsmasq 2>/dev/null; sudo pkill -x dhcpd 2>/dev/null
sudo ip link del "$TAP" 2>/dev/null
sudo ip tuntap add dev "$TAP" mode tap user "$(id -un)"
sudo ip addr add "$HOST_V4/$CIDR" dev "$TAP"
sudo ip -6 addr add fd00:ce::1/64 dev "$TAP" 2>/dev/null
sudo ip link set "$TAP" up

# ---- embed ONIE onto the base disk ONCE (reused via overlays); via SLIRP + a temp HTTP updater ----
echo "== embed ONIE onto base disk (one-time) =="
qemu-img create -f qcow2 "$BASE_DISK" 4G >/dev/null 2>&1
python3 -m http.server "$EMBED_PORT" --directory "$(dirname "$UPDATER")" >"$WORKDIR/embed-http.log" 2>&1 &
EHP=$!; sleep 1
: > "$WORKDIR/embed.log"
qemu-system-x86_64 \
    -machine pc,${ACCEL} -m 2048 -smp 2 \
    -kernel "$VMLINUZ" -initrd "$INITRD" \
    -append "quiet ${CONSOLE} boot_env=recovery boot_reason=embed install_url=http://10.0.2.2:${EMBED_PORT}/$(basename "$UPDATER")" \
    -drive file="$BASE_DISK",if=virtio,format=qcow2 \
    -netdev user,id=n0 -device virtio-net,netdev=n0 \
    -display none -serial "file:$WORKDIR/embed.log" -no-reboot >/dev/null 2>&1 &
esecs="$(wait_marker "$WORKDIR/embed.log" 'ONIE: NOS install successful|ONIE: Rebooting' 240)"
kill "$EHP" 2>/dev/null
if ! grep -aqE 'ONIE: NOS install successful|ONIE: Rebooting|Installing ONIE on' "$WORKDIR/embed.log"; then
    echo "ERROR: embed failed (${esecs}s) -- cannot run install tests"
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\r/\n/g' "$WORKDIR/embed.log" | grep -avE '^\s*$' | tail -20
    exit 1
fi
echo "   embedded in ${esecs}s -> $BASE_DISK (cached; tests overlay this)"

# ---- build a vfat USB image carrying the installer under ONIE's default names ----
build_usb_image() {  # <out.img>
    local img="$1"
    # The vfat must hold the installer under all 4 names below; size it to fit
    # (installer size x4) plus slack for FAT overhead, so a >16MB installer does
    # not overflow a fixed 64MB image partway through the copies.
    local mb=$(( ($(stat -c%s "$INSTALLER") / 1048576 + 1) * 4 + 32 ))
    qemu-img create -f raw "$img" "${mb}M" >/dev/null 2>&1
    mkfs.vfat -n ONIE-USB "$img" >/dev/null 2>&1
    local mnt; mnt="$(mktemp -d)"
    sudo mount -o loop "$img" "$mnt"
    for n in onie-installer-x86_64-kvm_x86_64-r0 onie-installer-kvm_x86_64 \
             onie-installer-x86_64 onie-installer; do
        sudo cp "$INSTALLER" "$mnt/$n"
    done
    sudo sync; sudo umount "$mnt"; rmdir "$mnt"
}

# ---- run one OCE test (full install); return 0 on "NOS install successful" ----
run_one() {  # <test_num>
    local t="$1"
    local tdir="$WORKDIR/oce-out/test-$t"
    local log="${SERIAL_PREFIX}-test${t}.log"
    local disk="$WORKDIR/target-$t.qcow2"
    rm -rf "$tdir"; : > "$log"
    stop_services; sleep 1

    # installer tests = 3-61, updater tests = 63-121 (onie-tests.json).  An
    # updater is discovered/run only under boot_reason=update and reports a
    # different success line than an installer.
    local reason ok_re
    if [ "$t" -ge 62 ]; then reason=update;  ok_re='ONIE: Success: Firmware update|Firmware update install successful'
    else                     reason=install; ok_re='ONIE: NOS install successful'; fi

    # fresh CoW overlay of the embedded base = this test's install target (instant reset)
    qemu-img create -f qcow2 -b "$BASE_DISK" -F qcow2 "$disk" >/dev/null 2>&1

    ( cd "$OCE_DIR" && "$OCE_PYTHON" test-onie.py -D \
        -I "$TAP" -m "$DUT_MAC" -i "$DUT_V4/$CIDR" -t "$t" \
        -o onie_installer "$INSTALLER" onie_updater "$UPDATER" \
           onie_arch x86_64 onie_vendor kvm onie_machine x86_64 onie_machine_rev 0 \
           onie_switch_asic qemu \
        -O "$WORKDIR/oce-out" ) >"$WORKDIR/oce-gen-$t.log" 2>&1

    chmod -R o+rX "$WORKDIR" 2>/dev/null   # nginx/tftpd/dnsmasq workers run as nobody/tftp

    local is_usb=no; local -a qemu_src
    if [ -f "$tdir/dhcpd.conf" ] || [ -f "$tdir/nginx.conf" ] || [ -f "$tdir/tftp.sh" ] || [ -f "$tdir/dnsmasq.conf" ]; then
        if [ -f "$tdir/dhcpd.conf" ]; then   # dhcpd is AppArmor-confined -> use allowed paths
            sudo cp "$tdir/dhcpd.conf" /etc/dhcp/oce-ci.conf
            sudo sh -c ': > /var/lib/dhcp/dhcpd.leases.oce'
            sudo dhcpd -f --no-pid -cf /etc/dhcp/oce-ci.conf -lf /var/lib/dhcp/dhcpd.leases.oce "$TAP" \
                >"$WORKDIR/dhcpd-$t.out" 2>&1 &
        fi
        [ -f "$tdir/nginx.conf" ]   && sudo nginx -c "$tdir/nginx.conf"        >"$WORKDIR/nginx-$t.out" 2>&1 &
        [ -f "$tdir/tftp.sh" ]      && ( cd "$tdir" && sudo bash tftp.sh       >"$WORKDIR/tftp-$t.out" 2>&1 & )
        [ -f "$tdir/dnsmasq.conf" ] && sudo dnsmasq -k -C "$tdir/dnsmasq.conf" >"$WORKDIR/dnsmasq-$t.out" 2>&1 &
        sleep 3
        qemu_src=(-netdev tap,id=n0,ifname="$TAP",script=no,downscript=no
                  -device virtio-net,netdev=n0,mac="$DUT_MAC")
    else
        is_usb=yes
        build_usb_image "$WORKDIR/usb-$t.img"
        qemu_src=(-device qemu-xhci -device usb-storage,drive=ud
                  -drive id=ud,if=none,format=raw,file="$WORKDIR/usb-$t.img"
                  -netdev user,id=n0 -device virtio-net,netdev=n0)
    fi

    qemu-system-x86_64 \
        -machine pc,${ACCEL} -m 2048 -smp 2 \
        -kernel "$VMLINUZ" -initrd "$INITRD" \
        -append "quiet ${CONSOLE} boot_env=recovery boot_reason=${reason}" \
        -drive file="$disk",if=virtio,format=qcow2 \
        "${qemu_src[@]}" \
        -display none -serial "file:$log" -no-reboot >/dev/null 2>&1 &
    local secs; secs="$(wait_marker "$log" "$ok_re" "$PER_TEST_TIMEOUT")"
    stop_services
    rm -f "$disk"

    local kind; kind="$([ "$is_usb" = yes ] && echo USB || echo net)"
    if grep -Eaq "$ok_re" "$log"; then
        printf '   PASS  test %-3s [%s/%s] %ss  ok\n' "$t" "$kind" "$reason" "$secs"
        return 0
    fi
    printf '   FAIL  test %-3s [%s/%s] %ss  did NOT reach "%s"\n' "$t" "$kind" "$reason" "$secs" "$ok_re"
    echo "---- serial tail (test $t) ----"
    sed 's/\x1b\[[0-9;?]*[A-Za-z]//g; s/\x1b[=>]//g; s/\r/\n/g' "$log" 2>/dev/null | grep -avE '^\s*$' | tail -25
    return 1
}

# ---- chained, fail-fast ----
echo "== running '$SCOPE' sweep ($(echo $TESTS | wc -w) tests), full install, fail-fast =="
pass=0
for t in $TESTS; do
    if run_one "$t"; then pass=$((pass + 1)); else
        echo "RESULT: FAIL (OCE sweep stopped at test $t; $pass passed before it)"; exit 1
    fi
done
echo "RESULT: PASS (OCE sweep: all $pass tests installed via discovery)"
exit 0
