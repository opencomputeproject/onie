#!/bin/sh
#
# test-udhcp6-sd.sh - T2 hermetic micro-test of the ONIE udhcp6_sd mapping.
#
# Proves, with NO network and NO VM, that the ONIE-side discovery hook maps the
# DHCPv6 Boot File URL (option 59), exported by the patched busybox udhcpc6 as
# the `bootfile` environment variable, to the ONIE parameter
# `onie_disco_bootfile`.
#
# This isolates the rootfs script (rootconf/default/lib/onie/udhcp6_sd) from the
# busybox patch and from the network harness. Runs in well under a second.
#
# POSIX sh. Exit 0 = PASS, non-zero = FAIL.
#
# Env vars (optional):
#   ONIE_TREE     repo root (default: two levels up from this script).
#   TEST_URL      installer URL to feed as $bootfile
#                 (default http://[2001:db8::1]:8080/onie-installer).
#
set -eu

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
DEFAULT_TREE=$(CDPATH= cd -- "$SCRIPT_DIR/../.." && pwd)
ONIE_TREE=${ONIE_TREE:-$DEFAULT_TREE}

SD="$ONIE_TREE/rootconf/default/lib/onie/udhcp6_sd"
TEST_URL=${TEST_URL:-http://[2001:db8::1]:8080/onie-installer}

log()  { echo "[test-udhcp6-sd] $*"; }
fail() { echo "[test-udhcp6-sd] FAIL: $*" >&2; exit 1; }

[ -r "$SD" ] || fail "udhcp6_sd not found or unreadable: $SD"

# The script reads $bootfile from the environment (as udhcpc6 sets it) and, on
# the `bound` event, prints an ONIE_PARMS: line.
log "invoking: bootfile='$TEST_URL' $SD bound"
out=$(bootfile="$TEST_URL" sh "$SD" bound)

log "output: $out"

# Assert the ONIE_PARMS prefix is present.
echo "$out" | grep -q '^ONIE_PARMS:' \
    || fail "output did not start with ONIE_PARMS:"

# Assert the bootfile URL was mapped to onie_disco_bootfile@@<url>.
# The url contains regex-special chars ([]:/.) so match as a fixed string.
expected="onie_disco_bootfile@@${TEST_URL}"
echo "$out" | grep -qF "$expected" \
    || fail "expected fixed string not found: $expected"

# Negative check: empty bootfile must NOT produce an onie_disco_bootfile mapping.
out_empty=$(bootfile="" sh "$SD" bound)
if echo "$out_empty" | grep -q 'onie_disco_bootfile@@'; then
    fail "empty bootfile unexpectedly produced an onie_disco_bootfile mapping: $out_empty"
fi

log "PASS - bootfile (opt 59) correctly mapped to onie_disco_bootfile"
exit 0
