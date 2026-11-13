#!/usr/bin/env bash
# Regression check: `vpn-box disconnect` without a terminal (tray, app menu) must not ask for a 2FA code.
# A stub gui-dialog records any call; no_new_privs makes vpn-box stop at the root step (exit 126).
set -euo pipefail
[ -x /opt/cisco/secureclient/bin/vpn ] || { echo "skip: no Cisco Secure Client"; exit 0; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp "$(dirname "$0")/../bin/vpn-box" "$tmp/"
printf '#!/bin/sh\ntouch "%s/dialog"; exit 1\n' "$tmp" >"$tmp/gui-dialog"; chmod +x "$tmp/gui-dialog"
rc=0; HOME=$tmp setpriv --no-new-privs "$tmp/vpn-box" disconnect </dev/null 2>/dev/null || rc=$?
[ ! -e "$tmp/dialog" ] || { echo "FAIL: disconnect opened a dialog (2FA prompt)"; exit 1; }
[ "$rc" = 126 ] || { echo "FAIL: expected exit 126 at the root step, got $rc"; exit 1; }
echo "ok: disconnect asks no 2FA code"

# Regression check: routes up but the VPN DNS dead (wifi roam, sleep) is not "connected".
grep -q 'dead: routes up but the VPN DNS does not answer' "$(dirname "$0")/../bin/vpn-box" \
  || { echo "FAIL: status lost its dead-tunnel check"; exit 1; }
out=$(bash -c 'IP=192.0.2.1; . <(sed -n "/^log()/,/^}/p" "$1"); link() { echo lo; }; vpn_dns() { echo 192.0.2.1; };
  resolvectl() { :; }; healthy' _ "$(dirname "$0")/../bin/vpn-box" 2>&1) && { echo "FAIL: dead DNS counted healthy"; exit 1; }
grep -q 'does not answer ping' <<<"$out" || { echo "FAIL: health check did not name the dead DNS: $out"; exit 1; }
echo "ok: dead tunnel is reported, not connected"
