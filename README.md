# desktop-scripts

Small Linux desktop helpers. Each one runs in a terminal or from the app menu; from the menu it
uses zenity popups and reports its result as a desktop notification.

| Script | Does |
|---|---|
| `vpn-box` | Cisco Secure Client in a container: only `VPN_BOX_ROUTES` (default `10.0.0.0/8`) and DNS for the VPN's domains go through the tunnel; internet, LAN and Tailscale stay on the host, untouched by Cisco's routes and firewall. `vpn-box` (menu), `connect [GATEWAY]`, `disconnect`, `status`, `gateways`, `build`. Disconnects a native session first. Launcher "VPN connect". |
| `vpn-box-tray` | Top-bar icon for `vpn-box`: green connected, grey not, amber working; menu Connect, Connect to (each gateway), Disconnect. Starts at login. |
| `vpn-up` | Native Cisco Secure Client 2FA VPN for all traffic (launcher "VPN connect (full tunnel)"): pick a gateway from a dropdown, enter the code. When connected: disconnect, or switch gateway. |
| `tailscale-cisco-fix` | Let tailnet TCP/DNS through Cisco Secure Client's firewall and clamp the tailscale0 MTU. `--install` adds a systemd timer that reruns it every 30 s (Cisco rewrites its rules at any time); `vpn-up` installs it on its first connect. |
| `tailscale-up` | Connect Tailscale (opens the login URL if needed); when connected, offer to disconnect. |
| `claude-update` | Update Claude Code (`claude update`) and Claude Desktop (apt). |
| `gui-sudo` | `sudo` for launchers: fingerprint first (PAM `pam_fprintd`), then a zenity password popup (`sudo -A`). |
| `gui-run` | Menu-launcher wrapper: runs a script without a terminal, notifies its last output line. |

## Install

```bash
./install.sh
```

Needs `zenity`, `notify-send`, and for `vpn-up`/`vpn-box` `secret-tool`. `vpn-box` also needs
`podman` and an installed Cisco Secure Client 5.1.10+ (its image is built from `/opt/cisco/secureclient`,
never committed): run `vpn-box build` once before the first connect. `vpn-box-tray` needs
`gir1.2-ayatanaappindicator3-0.1` and, on GNOME, the AppIndicator extension. Fingerprint in `gui-sudo` works when
`pam_fprintd` is in the PAM `sudo` stack (on Ubuntu: `sudo pam-auth-update`, enable fingerprint).

## Local settings

Site-specific values live in `~/.config/desktop-scripts/env` (sourced by the scripts, never committed):

```bash
VPN_KEYRING_SERVICE=my-vpn          # secret-tool service holding the VPN password
VPN_SORT="IPSEC site-a"             # dropdown order: earlier regex match sorts first
TS_UP_FLAGS="--accept-routes"       # your non-default `tailscale up` flags
VPN_BOX_SORT="site-a SSL"           # vpn-box dropdown order (default VPN_SORT); first = `connect` default
VPN_BOX_ROUTES="10.0.0.0/8"         # host routes sent into the box
VPN_BOX_DOMAINS="corp.example"      # extra DNS domains for the VPN's DNS servers
```

### How vpn-box works

A rootful podman container (`vpn-box/Containerfile`) runs `vpnagentd` (Cisco doc 223124: supported in
containers since 5.1.10) on a bridge `VPN_BOX_SUBNET` (default `192.168.250.0/29`; host `.1`, box `.2`).
After connect the host gets `ip route <VPN_BOX_ROUTES> via <box>`, and systemd-resolved sends the VPN's
search domains plus `VPN_BOX_DOMAINS` to the VPN's DNS servers on the bridge link. The box masquerades
into `cscotun0`. Stopping the box drops the bridge, and its routes and DNS go with it.

Two Cisco quirks in a container, handled in `vpn-box/entry.sh`: podman bind-mounts `/etc/hosts` and
`/etc/resolv.conf`, Cisco's `unlink` of them fails with EBUSY and the connect ends in "The VPN client
driver encountered an error" (the entrypoint unmounts them); a lockdown profile fills Cisco's
`ciscovpninitial` chain with drops (the entrypoint lets the bridge interface through).


## License

MIT. Not affiliated with Anthropic, Tailscale or Cisco; names are used only to say what each script drives.
