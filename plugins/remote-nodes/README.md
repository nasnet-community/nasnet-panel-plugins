# Remote Nodes

Runs an Xray entry on the router itself and manages Linux nodes from it, with no separate panel. One router has its own entry, "This router", and manages up to 3 nodes and 10 subscriptions. A subscription is a name with one `vless://` link (and QR code) per place it is switched on for, a traffic counter and an on/off switch.

Clients connect to the router or to a node:

- **This router** needs no server. Switched on in the dashboard, the router opens one port on its domestic link, and clients connect to it there by the router's IP Cloud name (or a name of your own). It is off until you switch it on.
- **A node** is a Linux server. Give the plugin its address and SSH login, and it installs NASNET's node software there and keeps it up to date. Traffic from a node's clients comes through a tunnel that the router opens to the node over its domestic link.

Either way the traffic leaves the router through its VPN. So entry needs both a domestic link and a VPN. Without either, nodes can still be managed (status, updates), entry stays off, and the dashboard says which piece is missing.

Image: `ghcr.io/nasnet-community/remote-nodes`, for `arm64` and `amd64` routers (there is no 32-bit ARM build). Source: [nasnet-community/nasnet-panel-linux](https://github.com/nasnet-community/nasnet-panel-linux).

## Needs

- RouterOS 7.20 or newer: the container's veth carries three addresses, its data folder needs a mount list, and its memory limits only exist from 7.20. On older versions the panel refuses the install, and `pre-install.rsc` stops with a message in the log.
- A router set up by the panel's wizard with a **domestic link** (the `Domestic-WAN` list and the `to-Domestic` routing table) and a **VPN** (the `VPN-WAN` list and the `to-VPN` table).
- The `container` package, enabled in device-mode.
- For each node: a Linux server with systemd and SSH access, reachable over the domestic link, with TCP port 443 free.
- For This router: IP Cloud switched on (the wizard does that), or a name of your own that points at the router's address on the domestic link. If another router sits in front of this one, it has to forward the port too; the dashboard says which.

## Settings

| Key       | Default | Description                                                |
| --------- | ------- | ---------------------------------------------------------- |
| `webPort` | 8092    | Listed with the plugin's ports only; nothing listens on it |

Open the dashboard from the panel, which proxies it.

**There is no login in this version.** Anyone who can reach the panel can manage the nodes and read the subscriptions' links, so keep the panel private and never forward its port from the internet.

## Networking

- Container: `192.168.50.16`, `.17` and `.18` on the shared `containers` bridge; dashboard on internal port 8080, which is not forwarded anywhere.
- The router sends each address out its own way, by source address. The manifest's `routing` list names them, and the panel turns it into rules, rebuilds them when the wizard runs again and removes them on uninstall:
  - `.16`, `foreign`: release downloads (the node software and Xray builds come from GitHub), out the foreign link;
  - `.17`, `vpn`: what clients send through a node, out the VPN;
  - `.18`, `domestic`: SSH and gRPC to the nodes, and the tunnels to them, out the domestic link. This router's entry listens here too, on port 8443, and its replies leave the same way.
- A link that is missing fails closed: traffic from its address is dropped, not sent out another way.
- This router's port is not in the manifest: the router script opens it only while This router is switched on (see below).

## Router script

`pre-install.rsc` adds the script `nasnet-remote-nodes-facts` and two schedulers for it, one at boot and one every minute (comment `nasnet:remote-nodes:*`), and runs it once. The script keeps the rules of This router in place, and tells the plugin what only the router knows, in `router/state` in the data folder, as `key=value` lines:

| Key                                            | Meaning                                                              |
| ---------------------------------------------- | -------------------------------------------------------------------- |
| `domestic`                                     | `1` when a domestic link exists and is up                            |
| `domestic_addr`                                | the router's own IPv4 address on that link; empty when there is none |
| `vpn`                                          | `1` when a VPN interface is up                                       |
| `vpn_kind`, `vpn_label`                        | `wireguard`, `l2tp`, `openvpn` or `other`, and the interface's name  |
| `route_foreign`, `route_vpn`, `route_domestic` | `1` when that routing table has a working default route              |
| `local_port`                                   | the port on the domestic link kept for This router; `0` when none    |
| `local_rules`                                  | `1` while the forward from that port to This router is in place      |
| `cloud_name`, `public_addr`                    | the router's IP Cloud name, and its address as IP Cloud sees it      |
| `ros`                                          | the RouterOS version                                                 |
| `free_mem`, `free_disk`                        | free memory and free flash, in bytes                                 |
| `updated`                                      | unix time of the write                                               |

`domestic_addr` is how the plugin learns that the router's address on the domestic link changed (a PPPoE session that came back, a new DHCP lease, a wizard run): it restarts Xray on each node then, because a tunnel connection made from the old address is dead and a node holds on to it for many minutes. The script runs every minute, so the plugin sees the change within about a minute. The address is the first one on the first running interface of the `Domestic-WAN` list, so a static address, a lease and a PPPoE session are all found the same way.

The plugin leaves the script what it wants in small files next to `router/state`: `router/local` holds `on` while This router is switched on, `router/host` holds a name of your own when one is set, and `router/request` holds `new-port` once when you ask for another port. While `router/local` says `on`, the script keeps:

- a random port between 20000 and 60000, the same one through off and on, a firewall reset and a wizard run, until you ask for a new one;
- a `dst-nat` rule from that port on the `Domestic-WAN` list to `192.168.50.18:8443`;
- a second `dst-nat` rule and a `mangle` rule for devices at home, so the same link works on your own Wi-Fi: they match the addresses in the list `nasnet-remote-nodes-local` (the router's public address, its address on the domestic link, and what your own name points at).

Every rule and list entry has a comment starting with `nasnet:remote-nodes:local:`. Switching This router off removes the rules within a minute and keeps the port number.

The file is rewritten when a fact changes and at least every 10 minutes, to spare the flash. The wizard removes every script and scheduler when it runs again, so the panel runs `pre-install.rsc` once more afterwards (`scripts.postWizard`) to put them back. `post-install.rsc` runs the script again once the container is up, and makes sure both schedulers exist.

## Install and uninstall

- Install: the panel creates the veth with its three addresses and the data mount, runs `pre-install.rsc`, creates and starts the container, then runs `post-install.rsc`. Nothing is exposed on the router until This router is switched on.
- Uninstall: `pre-uninstall.rsc` removes the script, its schedulers and the rules of This router, and the panel removes the container and the routing rules. The data stays unless you also choose to delete it in the uninstall dialog; installing again picks the folder up, with its nodes and subscriptions.
- The data is in `nasnet-panel/container-volumes/remote-nodes/remote-nodes/data` on the panel's storage. It holds the certificate authority every node trusts. Without it each node has to be set up again, so keep an exported backup from the dashboard's Settings.

## Troubleshooting

- **Entry is off.** The dashboard says whether the domestic link or the VPN is missing. `router/state` shows what the router reports, for example `route_vpn=0` while the VPN interface is down.
- **This router stays on "Starting" or says the router has not opened the port.** The script opens the port within a minute of switching on. `/ip firewall nat print where comment~"remote-nodes:local"` should list two rules, and `router/state` should say `local_rules=1`. If the script is missing, reinstall the plugin.
- **A link for This router works on your own Wi-Fi and not from outside.** Another router in front of this one has to forward the port; the dashboard shows the port and the address to forward it to.
- **The dashboard says the router's facts are old.** The script runs at boot and every minute. `/system script print` and `/system scheduler print` should list `nasnet-remote-nodes-facts` and its two schedulers; if not, reinstall the plugin.

## Licence

The plugin image is AGPL-3.0, with its source in [nasnet-community/nasnet-panel-linux](https://github.com/nasnet-community/nasnet-panel-linux) (`cmd/remote-nodes` and `cmd/remote-nodes-bridge`). It also carries Xray-core (MPL-2.0) and the installer package of the MTProto plugin (MIT); their notices are in `/licenses` in the image.
