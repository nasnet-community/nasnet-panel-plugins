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

`plugins.json` at the repo root indexes all plugins for the panel's store view.

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
- All plugin containers attach to the shared bridge `containers` (`192.168.50.0/24`, gateway `192.168.50.1`), created by the panel's installer. `192.168.50.2` is the panel container itself. Each plugin has a reserved veth address:

| Plugin            | veth          | Address     |
| ----------------- | ------------- | ----------- |
| telegram-mtproto  | veth-mtproto  | 192.168.50.11 |
| xray-server       | veth-xray     | 192.168.50.12 |
| deltachat-madmail | veth-madmail  | 192.168.50.13 |
| ooni-probe        | veth-ooni     | 192.168.50.14 |
| nasnet-monitor    | veth-monitor  | 192.168.50.15 |

New plugins take the next free address and register it here.

## manifest.json

| Field           | Meaning                                                        |
| --------------- | -------------------------------------------------------------- |
| `id`            | Folder name, kebab-case, unique in the registry                |
| `name`          | Display name on the store card                                 |
| `version`       | Plugin version (semver)                                        |
| `author`        | Shown as "by <author>" on the card                             |
| `license`       | SPDX id of the upstream software                               |
| `website`       | Upstream project URL                                           |
| `category`      | `proxy` \| `messaging` \| `measurement` \| `monitoring`        |
| `tagline`       | Bold one-liner on the card                                     |
| `description`   | Longer card body text                                          |
| `icon`          | Path to the card icon, relative to the plugin folder           |
| `architectures` | Container architectures the image supports                     |
| `container`     | See below                                                      |
| `scripts`       | Paths to `preInstall`, `postInstall`, `preUninstall` scripts   |
| `settingsSchema`| Path to `settings.json`                                        |

`container`:

- `image` — OCI image reference used as `remote-image`
- `interface` — `{ name, address, gateway }` for the plugin's veth
- `env` — key/value map, values may use `{{settings.*}}` placeholders
- `mounts` — `[{ name, src, dst }]`; `src` is relative to the router's NASNET data root (e.g. `usb1/nasnet/`)
- `ports` — `[{ protocol, containerPort, hostPort, description }]`; `hostPort` may be a placeholder. `description` is a short label for what the port serves (e.g. `Web dashboard`), used only for display in the panel dashboard; nothing on the router reads it. Ports are informational in general, and actual exposure is done by `post-install.rsc`.

## settings.json

`{ "settings": [ ... ] }`, each entry:

- `key` — used in `{{settings.<key>}}` placeholders
- `label`, `description` — form UI
- `type` — `string` | `integer` | `boolean` | `port` | `secret` | `select` | `url`
- `default`, `required`
- `min` / `max` for integers, `options` for selects
- `generate` for secrets: `hex16` | `hex32` | `uuid` (panel offers one-click generation)
