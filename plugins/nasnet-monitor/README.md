# NASNET Monitor

First-party monitoring for NASNET routers: collects router metrics, NASNET container status and connectivity checks, stores them locally, and serves a dashboard on the LAN. Optional webhook alerts.

Image: `ghcr.io/nasnet-community/nasnet-monitor` (built by the NASNET community; the `MONITOR_*` env names are defined by that image).

## Settings

| Key               | Default | Description                                         |
| ----------------- | ------- | --------------------------------------------------- |
| `webPort`         | 8088    | Dashboard port on the router's LAN address          |
| `intervalSeconds` | 60      | Metric/connectivity collection interval             |
| `retentionDays`   | 7       | Metric retention                                    |
| `webhookUrl`      | —       | Optional alert webhook                              |

## Networking

- Container: `192.168.50.15` on the shared `containers` bridge, internal port 8080.
- Dashboard is reachable at `http://<router-lan-ip>:8015` from non-WAN interfaces only; `post-install.rsc` adds a DNAT rule to the container limited to sources in the `Safe` address list.
- Metrics persist in `nasnet/nasnet-monitor/data`.
