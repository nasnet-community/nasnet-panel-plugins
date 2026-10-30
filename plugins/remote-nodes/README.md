# Remote Nodes

Manages Linux nodes from the router, with no separate panel. Give it a node's address and SSH login, and it installs NASNET's node software there and keeps it up to date. One router manages up to 3 nodes and 10 subscriptions. A subscription is a name with one `vless://` link (and QR code) per node, a traffic counter and an on/off switch.

Clients connect to a node. Their traffic goes through a tunnel that the router opens to the node over its domestic link, and leaves the router through its VPN. So entry, clients connecting through a node, needs both a domestic link and a VPN. Without either, nodes can still be managed (status, updates), entry stays off, and the dashboard says which piece is missing.

Image: `ghcr.io/nasnet-community/remote-nodes`, for `arm64` and `amd64` routers (there is no 32-bit ARM build). Source: [nasnet-community/nasnet-panel-linux](https://github.com/nasnet-community/nasnet-panel-linux).

## Needs

- RouterOS 7.11 or newer: the container's veth carries three addresses. On older versions the panel refuses the install, and `pre-install.rsc` stops with a message in the log.
- A router set up by the panel's wizard with a **domestic link** (the `Domestic-WAN` list and the `to-Domestic` routing table) and a **VPN** (the `VPN-WAN` list and the `to-VPN` table).
- The `container` package, enabled in device-mode.
- For each node: a Linux server with systemd and SSH access, reachable over the domestic link, with TCP port 443 free.

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
  - `.18`, `domestic`: SSH and gRPC to the nodes, and the tunnels to them, out the domestic link.
- A link that is missing fails closed: traffic from its address is dropped, not sent out another way.

## Router script

`pre-install.rsc` adds the script `nasnet-remote-nodes-facts` and two schedulers for it, one at boot and one every 5 minutes (comment `nasnet:remote-nodes:*`), and runs it once. The script tells the plugin what only the router knows, in `router/state` in the data folder, as `key=value` lines:

| Key                                            | Meaning                                                              |
| ---------------------------------------------- | -------------------------------------------------------------------- |
| `domestic`                                     | `1` when a domestic link exists and is up                            |
| `vpn`                                          | `1` when a VPN interface is up                                       |
| `vpn_kind`, `vpn_label`                        | `wireguard`, `l2tp`, `openvpn` or `other`, and the interface's name  |
| `route_foreign`, `route_vpn`, `route_domestic` | `1` when that routing table has a working default route              |
| `ros`                                          | the RouterOS version                                                 |
| `free_mem`, `free_disk`                        | free memory and free flash, in bytes                                 |
| `updated`                                      | unix time of the write                                               |

The file is rewritten when a fact changes and at least every 10 minutes, to spare the flash. The wizard removes every script and scheduler when it runs again, so the panel runs `pre-install.rsc` once more afterwards (`scripts.postWizard`) to put them back. `post-install.rsc` runs the script again once the container is up, and makes sure both schedulers exist.

## Install and uninstall

- Install: the panel creates the veth with its three addresses and the data mount, runs `pre-install.rsc`, creates and starts the container, then runs `post-install.rsc`. Nothing is exposed on the router.
- Uninstall: `pre-uninstall.rsc` removes the script and its schedulers, and the panel removes the container and the routing rules. The data stays unless you also choose to delete it in the uninstall dialog; installing again picks the folder up, with its nodes and subscriptions.
- The data is in `nasnet-panel/container-volumes/remote-nodes/remote-nodes/data` on the panel's storage. It holds the certificate authority every node trusts. Without it each node has to be set up again, so keep an exported backup from the dashboard's Settings.

## Troubleshooting

- **Entry is off.** The dashboard says whether the domestic link or the VPN is missing. `router/state` shows what the router reports, for example `route_vpn=0` while the VPN interface is down.
- **The dashboard says the router's facts are old.** The script runs at boot and every 5 minutes. `/system script print` and `/system scheduler print` should list `nasnet-remote-nodes-facts` and its two schedulers; if not, reinstall the plugin.

## Licence

The plugin image is AGPL-3.0, with its source in [nasnet-community/nasnet-panel-linux](https://github.com/nasnet-community/nasnet-panel-linux) (`cmd/remote-nodes` and `cmd/remote-nodes-bridge`). It also carries Xray-core (MPL-2.0) and the installer package of the MTProto plugin (MIT); their notices are in `/licenses` in the image.
