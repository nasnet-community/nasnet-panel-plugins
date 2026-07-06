# OONI Probe

Runs [OONI Probe](https://ooni.org) measurements from the router to detect censorship and network interference (blocked websites, messaging apps, circumvention tools), optionally contributing results to the open OONI dataset.

Image: `aaimio/ooni-probe` — a community image that runs the OONI Probe CLI unattended. By installing, the operator gives informed consent for testing (`informed_consent=true`); be aware of the [potential risks](https://ooni.org/about/risks/) of running OONI Probe in your jurisdiction.

## Settings

| Key             | Default | Description                                   |
| --------------- | ------- | --------------------------------------------- |
| `uploadResults` | true    | Publish results to the open OONI dataset      |
| `intervalHours` | 24      | How often the test suite re-runs              |

## Behavior

- No inbound ports — measurements are outbound only.
- Probe state persists in `nasnet/ooni-probe/state`.
- `post-install.rsc` adds a RouterOS scheduler (`nasnet-ooni-probe-run`) that restarts the container every `intervalHours` hours to re-run the test suite.
