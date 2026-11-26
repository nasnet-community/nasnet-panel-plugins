# NASNET Panel Plugin Spec

How plugins in this registry are structured and how the NASNET Panel consumes them. Plugins run as containers on MikroTik RouterOS (7.5+, `container` package installed and enabled in device-mode; arm, arm64 or x86_64).

## Layout

```
plugins/<plugin-id>/
  manifest.json        required — identity, store-card info, container definition
  settings.json        required — user-configurable settings the panel renders as a form
  icon.svg             required — store-card icon
  README.md            required — human documentation
  scripts/
    pre-install.rsc    runs on the router BEFORE the panel creates the container
    post-install.rsc   runs on the router AFTER the container is created
    pre-uninstall.rsc  runs on the router BEFORE the panel removes the container
  templates/           optional — config file templates rendered to the router disk
```

`plugins.json` at the repo root indexes all plugins for the panel's store view. Each entry repeats the plugin's `visible` flag from its manifest, and the two must match.

## Install lifecycle

1. The panel collects settings from the user (per `settings.json`) and renders all scripts, env values and templates (see Templating).
2. `pre-install.rsc` runs on the router: network prep and sanity checks.
3. The panel creates the container from `manifest.container`: veth interface, env list, mounts, `remote-image`, and tags it with comment `nasnet:<plugin-id>`.
4. `post-install.rsc` runs: firewall exposure, schedulers, container start.

Uninstall: `pre-uninstall.rsc` runs (stops the container, tears down everything the plugin added), then the panel removes the container, env list, mounts and files.

## Templating

Scripts, env values and templates may contain `{{settings.<key>}}` placeholders. The panel substitutes them with the user's settings before anything is executed or written to the router. No other template logic exists — keep scripts plain RouterOS.

## Conventions

- Every RouterOS object a plugin creates carries a comment `nasnet:<plugin-id>:<role>`. Shared objects use `nasnet:shared:<role>`. Uninstall removes objects by comment match and must never remove `nasnet:shared:*`.
- Scripts must be idempotent — guard every `add` with a `find` on the comment.
- All plugin containers attach to the shared bridge `containers`, created by the panel's installer, which carries two networks:
  - `192.168.50.0/24` for management: the router is `192.168.50.1`, the panel container `192.168.50.2`. A plugin's first address is here, and the panel opens its page on it.
  - `192.168.150.0/24` for the containers' own traffic, split into exit classes: the router is `192.168.150.254`, the gateway of every container that uses them. The router sends what a container sends out by its source address, one /28 per class, so a container picks the link by the address it dials from.

| Addresses | Exit class | Leaves through |
| --------- | ---------- | -------------- |
| 192.168.150.1–15 | Exit-Class-Domestic-Failover | Domestic Link 1, then 2, 3, 4, back to the first when it returns (today `to-Domestic`) |
| 192.168.150.16–31 | Exit-Class-Domestic-1 | Domestic Link 1, no failover |
| 192.168.150.32–47 | Exit-Class-Domestic-2 | Domestic Link 2, no failover |
| 192.168.150.48–63 | Exit-Class-Domestic-3 | Domestic Link 3, no failover |
| 192.168.150.64–79 | Exit-Class-Domestic-4 | Domestic Link 4, no failover |
| 192.168.150.80–95 | Exit-Class-Foreign-Failover | Starlink 1, then 2, 3, 4, back to the first when it returns (today `to-Foreign`) |
| 192.168.150.96–111 | Exit-Class-Foreign-1 | Starlink 1, no failover |
| 192.168.150.112–127 | Exit-Class-Foreign-2 | Starlink 2, no failover |
| 192.168.150.128–143 | Exit-Class-Foreign-3 | Starlink 3, no failover |
| 192.168.150.144–159 | Exit-Class-Foreign-4 | Starlink 4, no failover |
| 192.168.150.160–175 | Exit-Class-VPN-Failover | the primary VPN, then backup 1, then backup 2, back when it returns (today `to-VPN`) |
| 192.168.150.176–191 | Exit-Class-VPN-Primary | the primary VPN, no failover |
| 192.168.150.192–207 | Exit-Class-VPN-Backup-1 | backup VPN 1, no failover |
| 192.168.150.208–223 | Exit-Class-VPN-Backup-2 | backup VPN 2, no failover |

A class whose link the router doesn't have (Domestic Link 2 to 4, Starlink 2 to 4 and the backup VPNs, for now, or every Domestic class on a router with no domestic link) drops what its addresses send; it never falls back to another link. Addresses past `.223` are dropped too. Destinations in the router's own networks (`LOCAL-IP`) are left alone. The panel puts the classes on the router when it installs or updates a plugin with an address in `192.168.150.0/24`, and the wizard writes them every time it runs; they carry comments starting `Exit-Class-` and stay when a plugin is uninstalled.

Each plugin has reserved addresses:

| Plugin            | veth          | Management | Exit classes |
| ----------------- | ------------- | ---------- | ------------ |
| telegram-mtproto  | veth-mtproto  | 192.168.50.11 | 192.168.150.11 (Domestic failover), 192.168.150.91 (Foreign failover) |
| telegram-mtproto-local | veth-mtproto-local | 192.168.50.13, 192.168.50.14 | |
| nasnet-monitor    | veth-monitor  | 192.168.50.15 | |
| remote-nodes      | veth-remote-nodes | 192.168.50.16 | 192.168.150.1 (Domestic failover), 192.168.150.80 (Foreign failover), 192.168.150.160 (VPN failover) |

New plugins take the next free address and register it here.

## manifest.json

| Field           | Meaning                                                        |
| --------------- | -------------------------------------------------------------- |
| `id`            | Folder name, kebab-case, unique in the registry                |
| `name`          | Display name on the store card                                 |
| `version`       | Plugin version (semver)                                        |
| `visible`       | `true` if the plugin is ready for users, `false` if not. The panel lists only plugins with `visible: true`; a missing flag counts as `false`. Copy the same value into the plugin's `plugins.json` entry |
| `author`        | Shown as "by <author>" on the card                             |
| `license`       | SPDX id of the upstream software                               |
| `website`       | Upstream project URL                                           |
| `category`      | `proxy` \| `messaging` \| `measurement` \| `monitoring`        |
| `tagline`       | Bold one-liner on the card                                     |
| `description`   | Longer card body text                                          |
| `icon`          | Path to the card icon, relative to the plugin folder           |
| `architectures` | Container architectures the image supports                     |
| `container`     | See below                                                      |
| `scripts`       | Paths to `preInstall`, `postInstall`, `preUninstall` and, optionally, `postWizard` scripts |
| `settingsSchema`| Path to `settings.json`                                        |
| `minRouterOS`   | Optional. Oldest RouterOS the plugin works on, like `7.11`. An install on an older router is refused with a message |
| `keepDataOnUninstall` | Optional. `true` when the plugin's data folder holds something hard to recreate (a certificate authority, say). Uninstalling then leaves the folder in place unless the user also asks for its data to be deleted, and a reinstall picks it up again |

`container`:

- `image` — OCI image reference used as `remote-image`
- `interface` — `{ name, address, gateway }` for the plugin's veth. `address` carries its prefix length (`192.168.50.11/24`). It can also be a list, `["192.168.50.16/24", "192.168.150.1/24"]`, or a comma-separated string, for a plugin that needs several source addresses; the first is the container's own. An address in `192.168.150.0/24` is a `/24` inside an exit class, and a plugin that has one uses `192.168.150.254` as its gateway. An update gives the veth the new manifest's addresses and gateway
- `env` — key/value map, values may use `{{settings.*}}` placeholders
- `mounts` — `[{ name, src, dst }]`; `src` is relative to the router's NASNET data root (e.g. `usb1/nasnet/`)
- `ports` — `[{ protocol, containerPort, hostPort, description }]`; `hostPort` may be a placeholder. `description` is a short label for what the port serves (e.g. `Web dashboard`), used only for display in the panel dashboard; nothing on the router reads it. Ports are informational in general, and actual exposure is done by `post-install.rsc`.

Optional container settings. They apply when the container is created (updating a plugin leaves them alone) and are taken literally: `{{settings.*}}` is not expanded in them. A bad value fails the install before anything on the router is touched, and leaving them out creates the container as before.

- `memoryHigh`, `memoryMax` — memory limits as bytes or a number with a `K`, `M` or `G` suffix (`128M`). `memoryMax` is at least `1M` and not below `memoryHigh`
- `cpuList` — cores to run on, named as RouterOS names them: `cpu0` or `cpu0,cpu1`
- `user` — `user[:group]`, each a name or a numeric id: `1000:1000`
- `devices` — devices to hand through, as RouterOS names them: `["serial0"]`
- `autoRestartInterval` — a RouterOS time (`30s`, `5m`, `1h30m`): restart the container this long after it exits

`scripts.postWizard`:

The wizard wipes every script and scheduler on the router. A `postWizard` script is run after a wizard run to put back what the plugin set up; point it at `pre-install.rsc` if that script only puts things back. The panel keeps a copy of it on the router from install on, so running it needs no network. An update keeps the new version's copy and runs it once, with the container stopped, so the router side follows the new version. Plugins without one are left as the wizard leaves them.

## settings.json

`{ "settings": [ ... ] }`, each entry:

- `key` — used in `{{settings.<key>}}` placeholders
- `label`, `description` — form UI
- `type` — `string` | `integer` | `boolean` | `port` | `secret` | `select` | `url`
- `default`, `required`
- `min` / `max` for integers, `options` for selects
- `generate` for secrets: `hex16` | `hex32` | `uuid` (panel offers one-click generation)
