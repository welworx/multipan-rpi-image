# multipan-rpi-image

Prebuilt `linux/arm64` replacement for
[`antoniocifu/ihost-multipan-docker`](https://github.com/antoniocifu/ihost-multipan-docker)
(cpcd + zigbeed + otbr-agent — Zigbee and Thread/Matter from a single Sonoff
ZBDongle-E radio), for a Raspberry Pi.

**Why:** `antoniocifu/ihost-multipan-docker`'s published arm64 tag is broken
— it ships amd64 binaries under an arm64 manifest, so it fails on real
hardware with `exec container process /init: Exec format error`. This repo
builds from the same verified-clean upstream base
([`ghcr.io/ihost-open-source-project/hassio-ihost-silabs-multiprotocol-aarch64`](https://github.com/iHost-Open-Source-Project/hassio-ihost-addon))
instead, and publishes the result to GHCR so nothing has to build on the Pi
itself. See [`NOTICE.md`](NOTICE.md) for the full attribution and diff.

Published as `ghcr.io/welworx/multipan-rpi-image`, tagged `latest`, the
pinned upstream vendor-image version (e.g. `1.0.2`), and `<version>-<sha>`
for a build that's both traceable and unique. Pin by digest
(`@sha256:<digest>`) wherever you consume it.

This is a personal, best-effort repo, not a general-purpose maintained
image — no warranty, use at your own risk. See
[`LICENSE-antoniocifu`](LICENSE-antoniocifu) (Apache-2.0) for the actual
license terms.

## How it updates

[Dependabot](.github/dependabot.yml) watches the base image digest,
`requirements.txt`, and the GitHub Actions used in CI, and opens PRs — not
auto-merged, given this image's documented history of an unverified
base-image bug reaching real hardware. Merging (or any push touching
`Dockerfile`/`requirements.txt`/`rootfs/**`) triggers
[`build.yml`](.github/workflows/build.yml). A weekly scheduled build runs as
a fallback net.

## Security

See [`SECURITY.md`](SECURITY.md). Short version: every build is scanned with
Trivy (results in the Security tab), Dependabot security updates and
GitHub's secret scanning/push protection are on.
