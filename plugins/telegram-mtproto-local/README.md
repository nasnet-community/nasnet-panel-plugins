# Local MTProto

Runs a Telegram MTProto proxy ([telemt](https://github.com/telemt/telemt)) on the router itself, for family and friends. They connect from anywhere through the router's domestic link; the proxy reaches Telegram through the foreign link. No VPS is needed. For proxies on your own VPSes, use Remote MTProto.

Image: `ghcr.io/nasnet-community/mtproto-local-plugin`, source [nasnet-community/mtproto-remote-plugin](https://github.com/nasnet-community/mtproto-remote-plugin) (`cmd/mtproto-local`). It ships telemt's own release build for arm64 and x86-64. telemt publishes no build for 32-bit ARM, so that image carries an unofficial build made from telemt's unchanged source; the dashboard says so. telemt's licence is in the image at `/usr/local/share/telemt/LICENSE`.

## Needs

- A router set up by the panel's wizard with a **domestic link** (the `Domestic-WAN` list and the `to-Domestic` and `to-Foreign` routing tables). On a router without one the dashboard says so and the proxy stays off.
- A way in from outside: most homes need a TCP port forward on the ISP modem, to the router's domestic address. A line behind CGNAT can't take incoming connections at all. The dashboard's Status tab shows the exact step.
- IP Cloud on (`/ip cloud set ddns-enabled=yes`) for the address in links, or an address typed in the dashboard's Settings.

## Settings

| Key       | Default | Description                                                |
| --------- | ------- | ---------------------------------------------------------- |
| `webPort` | 8091    | Listed with the plugin's ports only; nothing listens on it |

Open the dashboard from the panel, which proxies it.

## First run

The dashboard asks for a cover site, which the router checks over the domestic link, and the first user's name, then shows that user's link and the modem step. Users, their secrets, limits and usage live in the plugin's data folder.

## Networking

- Container: `192.168.50.13` and `192.168.50.14` on the shared `containers` bridge; dashboard on internal port 8080, telemt on 8443.
- `pre-install.rsc` adds the script `nasnet-mtproto-local`, which runs every minute and keeps everything the plugin needs on the router, comment `nasnet:telegram-mtproto-local:*`:
  - a random port between 20000 and 60000 on the domestic link, forwarded to `192.168.50.13:8443` (dstnat `forward`);
  - the hairpin, so phones on your Wi-Fi use the same links (address list `nasnet-mtproto-local-public`, dstnat and mangle `hairpin`);
  - routing: replies and the cover site (fetched from `.14`) go out the domestic link, everything else from `.13`, that is Telegram, out the foreign link (mangle `replies`, `cover`, `foreign`).
- "New port" in the dashboard asks the script for another random port; it moves the forward within a minute. The port is also kept in `router/state` in the data folder, so a firewall reset brings the same port back.
- `pre-uninstall.rsc` removes the script, its schedule, and all of the above.
- Data persists in `nasnet-panel/container-volumes/telegram-mtproto-local/telegram-mtproto-local/data` on the panel's storage. Uninstalling deletes it, users included.

## Troubleshooting

- **Links work at home but not outside.** Check the modem's port forward (Status tab), and that the line has a public IP address.
- **The dashboard waits for the router.** The script reports within a minute of the install. If it never does, reinstall the plugin.
- **The cover site check fails.** The site must answer TLS 1.3 as seen from the router over the domestic link. Pick another.
