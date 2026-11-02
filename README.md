# desktop-scripts

Small Linux desktop helpers. Each one runs in a terminal or from the app menu; from the menu it
uses zenity popups and reports its result as a desktop notification.

| Script | Does |
|---|---|
| `vpn-up` | Cisco Secure Client 2FA VPN: pick a gateway from a dropdown, enter the code. When connected: disconnect, or switch gateway. |
| `vpn-proxy` | Same VPN (AnyConnect SSL) in a podman container via openconnect + ocproxy, exposed only as a SOCKS5 proxy on `127.0.0.1:1080`; the host stays off the VPN. `vpn-proxy up\|down\|status`. Clients must resolve names through it (`socks5h://`). |
| `tailscale-up` | Connect Tailscale (opens the login URL if needed); when connected, offer to disconnect. |
| `claude-update` | Update Claude Code (`claude update`) and Claude Desktop (apt). |
| `gui-sudo` | `sudo` for launchers: fingerprint first (PAM `pam_fprintd`), then a zenity password popup (`sudo -A`). |
| `gui-run` | Menu-launcher wrapper: runs a script without a terminal, notifies its last output line. |

## Install

```bash
./install.sh
```

Needs `zenity`, `notify-send`, for `vpn-up` `secret-tool`, for `vpn-proxy` also `podman`. Fingerprint in `gui-sudo` works when
`pam_fprintd` is in the PAM `sudo` stack (on Ubuntu: `sudo pam-auth-update`, enable fingerprint).

## Local settings

Site-specific values live in `~/.config/desktop-scripts/env` (sourced by the scripts, never committed):

```bash
VPN_KEYRING_SERVICE=my-vpn          # secret-tool service holding the VPN password
VPN_SORT="IPSEC site-a"             # dropdown order: earlier regex match sorts first
VPN_PROXY_URL=https://vpn.example.com/MyGroup  # vpn-proxy: SSL gateway + group (UserGroup in the Cisco profile)
TS_UP_FLAGS="--accept-routes"       # your non-default `tailscale up` flags
```

## License

MIT. Not affiliated with Anthropic, Tailscale or Cisco; names are used only to say what each script drives.
