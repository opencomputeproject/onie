#!/bin/sh
#
# run-onie-vm.sh - Direct-boot the built ONIE kernel+initrd in QEMU on the
# tap network created by setup-dhcp6-test.sh.
#
# Boots with -kernel/-initrd (like onie-vm.sh's rk-onie): bypasses the
# UEFI/ISO/shim path entirely, so no signing keys and no Secure-Boot
# build overrides are needed to validate DHCPv6 installer discovery.
# For the full firmware/ISO flow (Secure Boot, install-to-disk), use
# emulation/onie-vm.sh instead.
#
# Console goes to stdout/stderr; capture with:
#   ./run-onie-vm.sh 2>&1 | tee console.log
# Exit QEMU with: Ctrl-a x   (from -nographic)
#
# Usage:
#   ./run-onie-vm.sh [--with-disk [PATH]]
#
# Flags:
#   --with-disk [PATH]  Create a fresh qcow2 (default
#                       /tmp/onie-disk-<MACHINE>.qcow2, size DISK_SIZE,
#                       default 4G) with GRUB-BOOT (2 MiB) and
#                       ONIE-BOOT (128 MiB ext4) partitions, populate
#                       ONIE-BOOT with the minimal grub scaffolding
#                       needed by the demo installer, then boot with
#                       the disk attached.  ANY EXISTING FILE AT PATH
#                       IS DELETED.  Requires the script to run as
#                       root (qemu-nbd, modprobe, mount).
#                       Without this flag the harness boots diskless
#                       (fetch + checksum only, sufficient to validate
#                       the DHCPv6 discovery path).
#
# POSIX sh. Env vars (all optional; defaults shown):
#   ONIE_TREE    repo root (default: two levels up from this script)
#   MACHINE      kvm_x86_64
#   MACHINE_REV  r0
#   IMAGES       $ONIE_TREE/build/images
#   KERNEL       $IMAGES/$MACHINE-$MACHINE_REV.vmlinuz
#   INITRD       $IMAGES/$MACHINE-$MACHINE_REV.initrd
#   TAP          tap-onie   (created by setup-dhcp6-test.sh)
#   MEM          1024       (MB)
#   DISK         (unset)    same effect as --with-disk PATH; kept for
#                back-compat.  Flag takes precedence when both are set.
#   DISK_SIZE    4G         qcow2 size when the disk is created.
#   ONIE_DHCP_TYPE ipv6_only  kernel cmdline dhcp_type= value; override
#                             to exercise ipv4_ipv6 / ipv4_only / no.
#
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_TREE=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)

ONIE_TREE=${ONIE_TREE:-$DEFAULT_TREE}
MACHINE=${MACHINE:-kvm_x86_64}
MACHINE_REV=${MACHINE_REV:-r0}
IMAGES=${IMAGES:-$ONIE_TREE/build/images}
KERNEL=${KERNEL:-$IMAGES/$MACHINE-$MACHINE_REV.vmlinuz}
INITRD=${INITRD:-$IMAGES/$MACHINE-$MACHINE_REV.initrd}
TAP=${TAP:-tap-onie}
MEM=${MEM:-1024}
DISK=${DISK:-}
DISK_SIZE=${DISK_SIZE:-4G}

log() { echo "[run-onie-vm] $*"; }
die() { echo "[run-onie-vm] ERROR: $*" >&2; exit 1; }

bootstrap_disk() {
    disk_path=$1
    grub_src="$ONIE_TREE/installer/grub-arch/grub.d/50_onie_grub"

    [ "$(id -u)" -eq 0 ] || die "--with-disk needs root (qemu-nbd, modprobe, mount); re-run under sudo"
    for cmd in qemu-img qemu-nbd sgdisk mkfs.ext4 modprobe partx mount umount blockdev; do
        command -v "$cmd" >/dev/null 2>&1 || die "$cmd not on PATH (--with-disk needs it)"
    done
    [ -r "$grub_src" ] || die "grub source not found: $grub_src"

    mnt=$(mktemp -d -t onie-boot.XXXXXX)
    nbd_dev=
    nbd_connected=
    cleanup() {
        umount "$mnt" 2>/dev/null || true
        # Only disconnect the device WE connected -- never touch one
        # another user or a parallel run owns.
        [ -n "$nbd_connected" ] && qemu-nbd --disconnect "$nbd_connected" 2>/dev/null || true
        rmdir "$mnt" 2>/dev/null || true
    }
    trap cleanup EXIT INT TERM

    # Ensure the nbd module is loaded BEFORE scanning for /dev/nbd*,
    # otherwise the block devices don't exist yet.
    modprobe nbd max_part=8

    for d in /dev/nbd0 /dev/nbd1 /dev/nbd2 /dev/nbd3 /dev/nbd4 /dev/nbd5 /dev/nbd6 /dev/nbd7; do
        [ -b "$d" ] || continue
        if [ "$(blockdev --getsize64 "$d" 2>/dev/null || echo x)" = "0" ]; then
            nbd_dev=$d
            break
        fi
    done
    [ -n "$nbd_dev" ] || die "no available nbd device found"
    log "bootstrapping fresh disk: $disk_path ($DISK_SIZE) on $nbd_dev"
    rm -f "$disk_path"
    qemu-img create -f qcow2 "$disk_path" "$DISK_SIZE" >/dev/null
    qemu-nbd --connect="$nbd_dev" --format=qcow2 "$disk_path"
    nbd_connected=$nbd_dev
    # qemu-nbd --connect returns before the kernel has finished
    # attaching the backing; poll until the block device reports a
    # non-zero size, otherwise sgdisk hits EINVAL on the first read.
    for _ in $(seq 50); do
        [ "$(blockdev --getsize64 "$nbd_dev" 2>/dev/null || echo 0)" -gt 0 ] && break
        sleep 0.1
    done
    [ "$(blockdev --getsize64 "$nbd_dev" 2>/dev/null || echo 0)" -gt 0 ] \
        || die "nbd device $nbd_dev did not come online after connect"

    sgdisk -Z "$nbd_dev" >/dev/null
    sgdisk -n 1:2048:+2M -t 1:ef02 -c 1:GRUB-BOOT "$nbd_dev" >/dev/null
    sgdisk -n 2:0:+128M  -t 2:3000 -c 2:ONIE-BOOT "$nbd_dev" >/dev/null
    partx -a "$nbd_dev" 2>/dev/null || true
    sleep 1

    mkfs.ext4 -F -L ONIE-BOOT \
        -O ^orphan_file,^metadata_csum_seed,^casefold \
        "$nbd_dev"p2 >/dev/null
    mount "$nbd_dev"p2 "$mnt"
    mkdir -p "$mnt/onie/grub" "$mnt/onie/grub.d"
    cp "$grub_src" "$mnt/onie/grub.d/"
    for f in grub-variables grub-machine.cfg grub-extra.cfg grub-common.cfg; do
        echo "# minimal ONIE $f" > "$mnt/onie/grub/$f"
    done
    umount "$mnt"
    qemu-nbd --disconnect "$nbd_dev"
    nbd_connected=

    trap - EXIT INT TERM
    rmdir "$mnt" 2>/dev/null || true

    log "disk bootstrap complete"
}

while [ $# -gt 0 ]; do
    case "$1" in
        --with-disk)
            # Optional path argument.  A leading '-' means the next
            # token is another flag, not our path.
            if [ $# -ge 2 ] && [ -n "${2:-}" ] && [ "${2#-}" = "$2" ]; then
                DISK=$2
                shift
            else
                DISK="/tmp/onie-disk-${MACHINE}.qcow2"
            fi
            ;;
        -h|--help)
            sed -n '2,40p' "$0"; exit 0 ;;
        *)
            die "unknown argument: $1" ;;
    esac
    shift
done

[ -r "$KERNEL" ] || die "kernel not found: $KERNEL (build: make MACHINE=$MACHINE all demo, or set KERNEL=)"
[ -r "$INITRD" ] || die "initrd not found: $INITRD"
command -v qemu-system-x86_64 >/dev/null 2>&1 || die "qemu-system-x86_64 not on PATH"
ip link show "$TAP" >/dev/null 2>&1 || die "tap $TAP not found (run: sudo ./setup-dhcp6-test.sh up)"

# Use KVM when permitted; plain emulation also works, just slower.
kvm=
[ -w /dev/kvm ] && kvm="--enable-kvm -cpu host"

log "kernel: $KERNEL"
log "initrd: $INITRD"
log "tap:    $TAP   mem: ${MEM}M   kvm: ${kvm:-disabled}   disk: ${DISK:-none}"

# Optional target disk: onie-install needs a block device to install
# the demo OS onto.  --with-disk bootstraps a fresh qcow2 with the
# GRUB-BOOT and ONIE-BOOT partitions the demo installer expects.
disk=
if [ -n "$DISK" ]; then
    bootstrap_disk "$DISK"
    disk="-drive file=$DISK,if=virtio,format=qcow2"
fi

# boot_reason=install starts the installer-mode discovery loop
# (including DHCPv6) -- same mechanism machine/kvm_x86_64 install.ipxe
# uses for net-booting ONIE.  See rootconf/default/etc/init.d/discover.sh.
exec qemu-system-x86_64 $kvm \
    -kernel "$KERNEL" \
    -initrd "$INITRD" \
    -append "console=tty0 console=ttyS0,115200n8 boot_reason=install dhcp_type=${ONIE_DHCP_TYPE:-ipv6_only}" \
    -m "$MEM" \
    -nographic \
    -netdev tap,id=net0,ifname="$TAP",script=no,downscript=no \
    -device virtio-net-pci,netdev=net0 $disk
