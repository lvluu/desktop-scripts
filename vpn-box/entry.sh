#!/bin/bash
# Container side of vpn-box: run vpnagentd and forward the host's traffic into the tunnel.
# Everything here touches only this container's network namespace.
mkdir -p /opt/cisco/secureclient/temp
# Cisco replaces /etc/hosts and /etc/resolv.conf (unlink + rename). podman bind-mounts both, so the
# unlink fails with EBUSY and the connect ends in "The VPN client driver encountered an error".
for f in /etc/hosts /etc/resolv.conf; do
  cp "$f" "$f.keep"; umount "$f" 2>/dev/null; cat "$f.keep" >"$f"; rm "$f.keep"
done
# Cisco's doc 223124: no systemd here, so keep the agent alive with a loop.
( while true; do /opt/cisco/secureclient/bin/vpnagentd -execv_instance; sleep 1; done ) &
iptables -t nat -A POSTROUTING -o cscotun0 -j MASQUERADE
iptables -t mangle -A FORWARD -p tcp --tcp-flags SYN,RST SYN -j TCPMSS --clamp-mss-to-pmtu
# A lockdown profile fills Cisco's chains with drops (also later, unprompted): let the host link in.
( while sleep 10; do
    for fam in ip ip6; do
      nft list chain "$fam" filter ciscovpninitial >/dev/null 2>&1 || continue
      for dir in iifname oifname; do
        nft list chain "$fam" filter ciscovpninitial | grep -q "$dir \"eth0\" .*accept" ||
          nft insert rule "$fam" filter ciscovpninitial "$dir" eth0 accept
      done
    done
  done ) &
# The box lives only as long as its tunnel. Once up, a dead tunnel (lid closed, wifi roam, office LAN) ends the
# container: the bridge goes, and the host's 10/8 + 172.16/12 routes and VPN DNS go with it (left behind they send
# the office network's own DNS and hosts into a dead tunnel).
watch_tunnel() {
  local up=0 fails=0 ns
  while sleep "${WATCH_EVERY:-10}"; do
    ip link show cscotun0 >/dev/null 2>&1 || { [ "$up" = 0 ] && continue; echo "vpn-box: cscotun0 gone, stopping"; return; }
    up=1
    ns=$(awk '$1 == "nameserver" && $2 !~ /:/ { print $2; exit }' /etc/resolv.conf)
    if ping -c1 -W3 "$ns" >/dev/null 2>&1; then fails=0; else fails=$((fails + 1)); fi
    [ "$fails" -lt 3 ] || { echo "vpn-box: VPN DNS $ns did not answer 3 pings, tunnel dead, stopping"; return; }
  done
}
watch_tunnel
