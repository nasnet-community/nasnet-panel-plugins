# Telegram MTProto

Self-hosted MTProto proxy for Telegram, running as a container on the router. Devices connect to `your-public-ip:<port>` with the proxy secret and reach Telegram through the router.

Upstream: [TelegramMessenger/MTProxy](https://github.com/TelegramMessenger/MTProxy) — image `telegrammessenger/proxy`.

## Settings

| Key       | Default | Description                                        |
| --------- | ------- | -------------------------------------------------- |
| `port`    | 8443    | WAN TCP port published for clients                 |
| `secret`  | —       | 32-char hex secret (panel can generate one)        |
| `adTag`   | —       | Optional sponsored-channel TAG from @MTProxybot    |
| `workers` | 1       | Proxy worker processes                             |

## Networking

- Container: `192.168.50.11` on the shared `containers` bridge, internal port 443.
- `post-install.rsc` adds a WAN dst-nat `{{settings.port}} → 192.168.50.11:443` and a forward-accept rule.

## Client link

After install, share: `https://t.me/proxy?server=<public-ip>&port=<port>&secret=<secret>`
