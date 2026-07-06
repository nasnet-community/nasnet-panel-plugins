# DeltaChat (Madmail)

Chatmail relay for [Delta Chat](https://delta.chat), powered by [Madmail](https://github.com/themadorg/madmail) — a Rust chatmail server with SMTP, IMAP, encryption enforcement and real-time relay built in. Delta Chat apps can create instant, end-to-end encrypted accounts against this relay.

> **Image note:** Madmail ships as a release binary, not an official Docker image. The manifest points at `ghcr.io/nasnet-community/madmail` — a container image the NASNET community builds around the upstream binary. The `MADMAIL_*` env names are defined by that image; keep them in sync when the image changes.

## Settings

| Key           | Default | Description                                                       |
| ------------- | ------- | ----------------------------------------------------------------- |
| `domain`      | —       | Mail domain; DNS A + MX must point at the router's public IP      |
| `letsencrypt` | true    | Auto TLS via Let's Encrypt (port 80 must be reachable to issue)   |
| `postmaster`  | —       | Optional postmaster/abuse contact                                 |

## Networking

- Container: `192.168.50.13` on the shared `containers` bridge.
- `post-install.rsc` forwards TCP 25, 465, 587, 993 (mail) and 80 (ACME) from WAN to the container.
- Mail data persists in `nasnet/deltachat-madmail/data` on the router disk.

## Requirements

- A public IP and an ISP that does not block inbound port 25.
- DNS records for the domain (A, MX; DKIM/SPF/DMARC strongly recommended — see the [Madmail docs](https://github.com/themadorg/madmail)).
