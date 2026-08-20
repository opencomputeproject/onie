#!/bin/sh
#
# setup-dhcp6-test.sh - Bring up a deterministic DHCPv6 test network for ONIE.
#
# Creates an isolated Linux network namespace with a bridge + veth + tap, runs
# dnsmasq as a DHCPv6 server that hands out the RFC 5970 Boot File URL
# (option 59), AND runs a plain HTTP server that actually serves the installer
# payload at that URL. The ONIE guest VM attaches to the tap (see onie-vm.xml.in).
#
# WHY netns + bridge + tap and NOT QEMU user-mode (-netdev user / SLIRP):
#   QEMU's built-in user-mode NAT stack cannot serve DHCPv6 option 59 (and its
#   DHCP is v4-only), so emulation/onie-vm.sh is unusable for this test. We need
#   a real L2 segment with a real DHCPv6 server, hence the tap on a bridge.
#
# This script is idempotent: it tears down any prior instance first, so re-runs
# never hit "error binding DHCP socket to device veth-ns".
#
# *** RUNS ON A LINUX HOST WITH root (ip netns), dnsmasq, and python3. ***
# It cannot run on macOS. Intended for the remote bench (tli@wdf4f-cn-1 / dell-3).
#
# POSIX sh.
#
# Env vars (all optional; defaults shown):
#   NETNS         onie-test
#   BRIDGE        br-onie
#   TAP           tap-onie
#   VETH_NS       veth-ns      (namespace side, carries the server IPv6)
#   VETH_BR       veth-br      (bridge side)
#   V6_PREFIX     2001:db8::/64
#   V6_SERVER     2001:db8::1  (dnsmasq / HTTP server address, no prefixlen)
#   DHCP_RANGE    2001:db8::100,2001:db8::200,64,1h
#   HTTP_PORT     8080
#   PAYLOAD_DIR   ./payload   (served over HTTP; put the onie-updater/installer here)
#   INSTALLER_URL http://[2001:db8::1]:8080/onie-installer   (advertised in opt 59)
#   MTU           1400
#   RUN_DIR       /tmp/onie-dhcp6  (logs + generated dnsmasq.conf live here)
#
# Usage:
#   sudo ./setup-dhcp6-test.sh up      # bring the network up (default)
#   sudo ./setup-dhcp6-test.sh down    # tear it all down
#
set -eu

ACTION=${1:-up}

NETNS=${NETNS:-onie-test}
BRIDGE=${BRIDGE:-br-onie}
TAP=${TAP:-tap-onie}
VETH_NS=${VETH_NS:-veth-ns}
VETH_BR=${VETH_BR:-veth-br}
V6_PREFIX=${V6_PREFIX:-2001:db8::/64}
V6_SERVER=${V6_SERVER:-2001:db8::1}
DHCP_RANGE=${DHCP_RANGE:-2001:db8::100,2001:db8::200,64,1h}
HTTP_PORT=${HTTP_PORT:-8080}
PAYLOAD_DIR=${PAYLOAD_DIR:-./payload}
INSTALLER_URL=${INSTALLER_URL:-http://[2001:db8::1]:8080/onie-installer}
MTU=${MTU:-1400}
RUN_DIR=${RUN_DIR:-/tmp/onie-dhcp6}

DNSMASQ_CONF="$RUN_DIR/dnsmasq.conf"
DNSMASQ_LOG="$RUN_DIR/dnsmasq.log"
DNSMASQ_PID="$RUN_DIR/dnsmasq.pid"
HTTP_LOG="$RUN_DIR/http.log"
HTTP_PID="$RUN_DIR/http.pid"

log() { echo "[setup-dhcp6-test] $*"; }
die() { echo "[setup-dhcp6-test] ERROR: $*" >&2; exit 1; }

need_root() {
    [ "$(id -u)" = 0 ] || die "must run as root (ip netns / dnsmasq bind). Use sudo."
}

# --------------------------------------------------------------------------
# Teardown (also the idempotent pre-step for `up`).
# --------------------------------------------------------------------------
teardown() {
    # Kill dnsmasq / http server if we have pidfiles.
    for pf in "$DNSMASQ_PID" "$HTTP_PID"; do
        if [ -f "$pf" ]; then
            pid=$(cat "$pf" 2>/dev/null || true)
            [ -n "${pid:-}" ] && kill "$pid" 2>/dev/null || true
            rm -f "$pf"
        fi
    done
    # Best-effort kill of anything left inside the netns.
    if ip netns list 2>/dev/null | grep -q "^$NETNS\b"; then
        ip netns pids "$NETNS" 2>/dev/null | while read -r p; do kill "$p" 2>/dev/null || true; done
        ip netns del "$NETNS" 2>/dev/null || true
    fi
    # Remove tap + bridge + veth (veth is auto-removed with its peer/netns).
    ip link del "$TAP" 2>/dev/null || true
    ip link del "$VETH_BR" 2>/dev/null || true
    ip link set "$BRIDGE" down 2>/dev/null || true
    ip link del "$BRIDGE" 2>/dev/null || true
    log "teardown complete"
}

if [ "$ACTION" = down ]; then
    need_root
    teardown
    exit 0
fi

[ "$ACTION" = up ] || die "unknown action '$ACTION' (use 'up' or 'down')"

need_root
command -v dnsmasq >/dev/null 2>&1 || die "dnsmasq not found on PATH"
command -v python3 >/dev/null 2>&1 || die "python3 not found on PATH"
command -v ip      >/dev/null 2>&1 || die "iproute2 (ip) not found on PATH"

log "idempotent pre-teardown ..."
teardown

mkdir -p "$RUN_DIR"
# Resolve PAYLOAD_DIR to an absolute path and make sure it exists.
mkdir -p "$PAYLOAD_DIR"
PAYLOAD_DIR=$(CDPATH= cd -- "$PAYLOAD_DIR" && pwd)
log "HTTP payload dir: $PAYLOAD_DIR"
[ -e "$PAYLOAD_DIR/onie-installer" ] || log "note: no 'onie-installer' file in payload dir yet (place the installer/updater there)."

# --------------------------------------------------------------------------
# Build the L2 topology:
#
#   [ netns: onie-test ]                 [ host root netns ]
#     veth-ns (2001:db8::1/64) <--veth--> veth-br --+
#                                                    |
#                                                 br-onie --- tap-onie --- (ONIE guest VM)
#
# dnsmasq + http.server run INSIDE the netns, bound to 2001:db8::1.
# The guest reaches them across the bridge via the tap.
# --------------------------------------------------------------------------
log "creating netns $NETNS, bridge $BRIDGE, tap $TAP, veth $VETH_NS<->$VETH_BR"

ip netns add "$NETNS"

# Bridge in the host root netns.
ip link add name "$BRIDGE" type bridge
ip link set "$BRIDGE" mtu "$MTU"
ip link set "$BRIDGE" up

# Tap for the VM, enslaved to the bridge.
ip tuntap add dev "$TAP" mode tap
ip link set "$TAP" mtu "$MTU"
ip link set "$TAP" master "$BRIDGE"
ip link set "$TAP" up

# veth pair: one end in the netns (server side), other on the bridge.
ip link add "$VETH_NS" mtu "$MTU" type veth peer name "$VETH_BR" mtu "$MTU"
ip link set "$VETH_NS" netns "$NETNS"
ip link set "$VETH_BR" master "$BRIDGE"
ip link set "$VETH_BR" up

# Configure the server side inside the netns.
ip netns exec "$NETNS" ip link set lo up
ip netns exec "$NETNS" ip link set "$VETH_NS" up
ip netns exec "$NETNS" ip -6 addr add "$V6_SERVER/64" dev "$VETH_NS"

# Allow IPv6 forwarding across the bridge.
ip6tables -C FORWARD -i "$BRIDGE" -j ACCEPT 2>/dev/null || ip6tables -A FORWARD -i "$BRIDGE" -j ACCEPT || true
ip6tables -C FORWARD -o "$BRIDGE" -j ACCEPT 2>/dev/null || ip6tables -A FORWARD -o "$BRIDGE" -j ACCEPT || true

# --------------------------------------------------------------------------
# dnsmasq config: DHCPv6 range + RA + option 59 Boot File URL.
# --------------------------------------------------------------------------
cat > "$DNSMASQ_CONF" <<EOF
# Generated by setup-dhcp6-test.sh - DHCPv6 server for ONIE RFC 5970 validation.
interface=$VETH_NS
bind-interfaces
port=0
dhcp-range=$DHCP_RANGE
enable-ra
# RFC 5970 option 59 = OPT_BOOTFILE_URL. dnsmasq alias: option6:59.
dhcp-option=option6:59,"$INSTALLER_URL"
log-dhcp
log-queries
log-facility=$DNSMASQ_LOG
dhcp-leasefile=$RUN_DIR/dnsmasq.leases
EOF

log "starting dnsmasq inside netns (log: $DNSMASQ_LOG)"
# -k keeps it in the foreground; we background it ourselves and record the pid.
ip netns exec "$NETNS" dnsmasq --conf-file="$DNSMASQ_CONF" --keep-in-foreground &
echo $! > "$DNSMASQ_PID"

# --------------------------------------------------------------------------
# HTTP server inside the netns (THE fix for the bench's commented-out server:
# without it, option 59 points at a dead URL and the boot never fetches).
# --------------------------------------------------------------------------
log "starting HTTP server inside netns on [$V6_SERVER]:$HTTP_PORT serving $PAYLOAD_DIR (log: $HTTP_LOG)"
ip netns exec "$NETNS" python3 -m http.server "$HTTP_PORT" \
    --bind "$V6_SERVER" --directory "$PAYLOAD_DIR" >"$HTTP_LOG" 2>&1 &
echo $! > "$HTTP_PID"

log "network is UP."
log "  netns=$NETNS bridge=$BRIDGE tap=$TAP server=$V6_SERVER"
log "  option 59 advertises: $INSTALLER_URL"
log "  dnsmasq log: $DNSMASQ_LOG"
log "  http    log: $HTTP_LOG"
log "Attach the ONIE VM to $TAP (see onie-vm.xml.in), then run verify-dhcp6-boot.sh."
