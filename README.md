# multipan-image

Prebuilt container image for the Silabs MultiPAN stack (cpcd + zigbeed +
otbr-agent) used to serve Zigbee and Thread/Matter from a single Sonoff
ZBDongle-E radio. Built here and published to GHCR instead of on-device,
because building it on a Raspberry Pi 4B is slow.

Consumed by the `multipan` role in the (private) `gemini-cli/infrastructure`
repo, which pulls `ghcr.io/welworx/multipan-image` pinned by digest and runs
it as a rootful systemd-managed Podman container. See [`NOTICE.md`](NOTICE.md)
for the full attribution and history (the upstream prebuilt
`antoniocifu/ihost-multipan-docker` image ships amd64 binaries under an arm64
manifest tag, which is why this is built from the verified-clean vendor base
instead of pulled).

Only ever built for `linux/arm64` — this stack has one target, a Pi 4B.

## How it updates

- `Dockerfile`'s `FROM` line and `requirements.txt` are watched by
  [Dependabot](.github/dependabot.yml). When the base image
  (`ghcr.io/ihost-open-source-project/hassio-ihost-silabs-multiprotocol-aarch64`)
  gets a new digest for the pinned tag, or `universal-silabs-flasher` has a
  new release, Dependabot opens a PR.
- Merging that PR (or any push to `main` touching `Dockerfile`,
  `requirements.txt`, or `rootfs/**`) triggers
  [`.github/workflows/build.yml`](.github/workflows/build.yml), which builds
  and pushes `ghcr.io/welworx/multipan-image:latest` and
  `ghcr.io/welworx/multipan-image:<short-sha>`.
- Dependabot PRs are **not** auto-merged — this exact image has a documented
  history of an unverified base-image bug making it onto real hardware, so a
  human reviews the diff before it ships. A weekly scheduled build is also
  wired in as a fallback net.

To pin a specific build in the ansible role, use the immutable
`ghcr.io/welworx/multipan-image@sha256:<digest>` reference from a workflow
run's summary or `gh api /users/welworx/packages/container/multipan-image/versions`.
