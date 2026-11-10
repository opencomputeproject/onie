#!/bin/sh
#
# verify-dhcp6-boot.sh - Objective PASS/FAIL gate for the DHCPv6 boot test.
#
# Inspects the logs produced by setup-dhcp6-test.sh (and optionally an ONIE
# serial-console capture) and asserts the end-to-end evidence chain:
#
#   1. dnsmasq sent RFC 5970 option 59 (Boot File URL) in a DHCPv6 reply.
#   2. The HTTP server logged a GET for the installer/updater (the guest fetched it).
#   3. (optional) The ONIE console shows the discovered `onie_disco_bootfile`.
#
# Exit 0 = PASS (all required checks passed), non-zero = FAIL. Suitable for CI.
#
# POSIX sh.
#
# Env vars (optional; defaults match setup-dhcp6-test.sh RUN_DIR):
#   RUN_DIR       /tmp/onie-dhcp6
#   DNSMASQ_LOG   $RUN_DIR/dnsmasq.log
#   HTTP_LOG      $RUN_DIR/http.log
#   CONSOLE_LOG   (unset) - optional path to a captured ONIE serial console log.
#
set -eu

RUN_DIR=${RUN_DIR:-/tmp/onie-dhcp6}
DNSMASQ_LOG=${DNSMASQ_LOG:-$RUN_DIR/dnsmasq.log}
HTTP_LOG=${HTTP_LOG:-$RUN_DIR/http.log}
CONSOLE_LOG=${CONSOLE_LOG:-}

pass_count=0
fail_count=0

ok()   { echo "[verify] PASS: $*"; pass_count=$((pass_count+1)); }
bad()  { echo "[verify] FAIL: $*" >&2; fail_count=$((fail_count+1)); }

echo "[verify] dnsmasq log : $DNSMASQ_LOG"
echo "[verify] http    log : $HTTP_LOG"
[ -n "$CONSOLE_LOG" ] && echo "[verify] console log : $CONSOLE_LOG"
echo

# --- Check 1: dnsmasq sent option 59 -------------------------------------
if [ ! -r "$DNSMASQ_LOG" ]; then
    bad "dnsmasq log not readable: $DNSMASQ_LOG (was setup-dhcp6-test.sh run?)"
else
    # dnsmasq logs the sent option as e.g.:
    #   "sent size: 38 option: 59 bootfile-url http://[2001:db8::1]:8080/..."
    if grep -Eq 'option:? *59 *bootfile-url' "$DNSMASQ_LOG"; then
        ok "dnsmasq sent option 59 (bootfile-url)"
        grep -E 'option:? *59 *bootfile-url' "$DNSMASQ_LOG" | tail -1 | sed 's/^/       /'
    else
        bad "no 'option 59 bootfile-url' found in dnsmasq log"
    fi
fi

# --- Check 2: HTTP server served the installer ---------------------------
if [ ! -r "$HTTP_LOG" ]; then
    bad "http log not readable: $HTTP_LOG"
else
    # python http.server logs: '... "GET /onie-installer HTTP/1.1" 200 -'
    if grep -Eq 'GET /onie-(updater|installer)' "$HTTP_LOG"; then
        ok "HTTP server served an installer/updater GET"
        grep -E 'GET /onie-(updater|installer)' "$HTTP_LOG" | tail -1 | sed 's/^/       /'
    else
        bad "no installer/updater GET found in http log"
    fi
fi

# --- Check 3 (optional): ONIE console shows onie_disco_bootfile -----------
if [ -n "$CONSOLE_LOG" ]; then
    if [ ! -r "$CONSOLE_LOG" ]; then
        bad "console log specified but not readable: $CONSOLE_LOG"
    elif grep -q 'onie_disco_bootfile' "$CONSOLE_LOG"; then
        ok "ONIE console shows onie_disco_bootfile"
    else
        bad "console log provided but no 'onie_disco_bootfile' present"
    fi
fi

echo
echo "[verify] summary: $pass_count passed, $fail_count failed"
if [ "$fail_count" -eq 0 ] && [ "$pass_count" -gt 0 ]; then
    echo "PASS"
    exit 0
else
    echo "FAIL"
    exit 1
fi
