# Remote MTProto

Installs and manages MTProto proxy servers ([telemt](https://github.com/telemt/telemt)) on remote Linux VPSes. Each VPS runs a small agent (`mtproto-agent`) next to telemt; it carries the proxy server's upstream connections through this router, which dials Telegram on its behalf. The router always opens the connection to the VPS: nothing on the router is reachable from the internet.

Image: `ghcr.io/nasnet-community/mtproto-remote-plugin`, source [nasnet-community/mtproto-remote-plugin](https://github.com/nasnet-community/mtproto-remote-plugin).

## Settings

| Key       | Default | Description                                                  |
| --------- | ------- | ------------------------------------------------------------ |
| `webPort` | 8090    | Listed with the plugin's ports only; nothing listens on it   |

Open the dashboard from the panel, which proxies it; no LAN port is published.

## Adding a server

You need a Linux VPS (amd64 or arm64) with SSH access. The dashboard connects over SSH once to install the agent and telemt, asks you to confirm the server's SSH fingerprint, and forgets the password or key when the job ends. After that it manages the server only through its own connection to the agent. A cover site (a domain you enter by hand) is checked from the VPS before it is accepted.

Users, their secrets, limits and usage live in the plugin's data folder on the router; their proxy links are shown in the dashboard.

## Networking

- Container: `192.168.50.11` on the shared `containers` bridge for its dashboard (internal port 8080), and two addresses in the containers' exit classes, with `192.168.150.254` as its gateway.
- The container only dials out. Nothing is published on the WAN.
- The router sends it out by source address: the VPSes (the agents' links and SSH) from `192.168.150.11`, through the domestic link (Domestic failover class), and Telegram and binary downloads from `192.168.150.91`, through the foreign link (Foreign failover class). The panel sets the classes up; `ADDR_DOMESTIC` and `ADDR_FOREIGN` tell the plugin which address is which. Older versions relied on two mangle rules for `192.168.50.11`; `pre-install.rsc` and `pre-uninstall.rsc` remove those (commented `nasnet:telegram-mtproto:*`).
- Data persists in `nasnet-panel/container-volumes/telegram-mtproto/telegram-mtproto/data` on the panel's storage.

## Troubleshooting

- **The install stops at the link step.** The router reaches the VPSes through its domestic link, so check that it has one and that it is up. Also check that the link port (8443 by default) is open at the VPS provider.
- **The cover site check fails.** The site must answer TLS 1.3 with HTTP/2 and a valid certificate, as seen from the VPS. Pick another domain.
- **Small routers.** On 32-bit ARM routers the plugin manages one server; on others, up to three.
