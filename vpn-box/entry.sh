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
exec sleep infinity
