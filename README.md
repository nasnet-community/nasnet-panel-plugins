# NASNET Panel Plugins

Plugin registry for the NASNET Panel. Each plugin's manifest and settings are added to this repository.

## Structure

- `plugins.json` — registry index the panel uses for its store view.
- `plugins/<plugin-id>/` — one folder per plugin: `manifest.json`, `settings.json`, `icon.svg`, `README.md`, and MikroTik RouterOS lifecycle scripts (`scripts/pre-install.rsc`, `scripts/post-install.rsc`, `scripts/pre-uninstall.rsc`).
- `PLUGIN_SPEC.md` — full spec: manifest/settings fields, install lifecycle, templating and RouterOS conventions.

## Plugins

| Plugin | Category | Description |
| --- | --- | --- |
| [Telegram MTProto](plugins/telegram-mtproto) | proxy | Self-hosted MTProto proxy for Telegram |
| [V2Ray / Xray](plugins/xray-server) | proxy | Self-hosted V2Ray/Xray proxy server |
| [NASNET Monitor](plugins/nasnet-monitor) | monitoring | Router and network health monitoring |

## Contributing

1. Fork the repository and create a branch for your plugin or change.
2. Add your plugin in its own directory with its manifest and settings files, following [PLUGIN_SPEC.md](PLUGIN_SPEC.md).
3. Commit your changes and push the branch to your fork.
4. Open a pull request against `main` describing the plugin and what it does.

## License

[MIT](LICENSE) © NASNET Community
