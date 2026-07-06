# V2Ray / Xray

Xray (V2Ray-compatible) proxy server running as a container on the router. Supports VLESS or VMess inbounds over TCP or WebSocket.

Upstream: [XTLS/Xray-core](https://github.com/XTLS/Xray-core) — image `teddysun/xray` (multi-arch).

## Settings

| Key        | Default | Description                                  |
| ---------- | ------- | -------------------------------------------- |
| `protocol` | vless   | Inbound protocol (`vless` or `vmess`)        |
| `port`     | 2083    | WAN TCP port published for clients           |
| `uuid`     | —       | Client UUID (panel can generate one)         |
| `network`  | tcp     | Transport: `tcp` or `ws`                     |
| `wsPath`   | /xray   | WebSocket path (only when transport is `ws`) |

## Config

The panel renders `templates/config.json.template` with the settings and writes it to `nasnet/xray-server/etc/config.json` on the router; the directory is mounted at `/etc/xray` in the container. Note: the `decryption` field is only meaningful for VLESS; Xray ignores it for VMess.

## Networking

- Container: `192.168.50.12` on the shared `containers` bridge, internal port 443.
- `post-install.rsc` adds a WAN dst-nat `{{settings.port}} → 192.168.50.12:443` and a forward-accept rule.

TLS is not terminated by this plugin; put it behind a CDN/websocket TLS front or extend the config template if you need direct TLS.
