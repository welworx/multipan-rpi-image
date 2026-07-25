# Vendored from antoniocifu/ihost-multipan-docker

`Dockerfile` and `rootfs/` in this repo are adapted from
[antoniocifu/ihost-multipan-docker](https://github.com/antoniocifu/ihost-multipan-docker)
at commit `a7792846cac361c1816e76f45afbd48b4bfc3830` (the commit that produced
the published `1.0.0`/`latest` tags), licensed Apache-2.0 (see
`LICENSE-antoniocifu`).

## Why vendored instead of pulled

The published image (`docker.io/antoniocifu/ihost-multipan-docker:1.0.0`, arm64
manifest digest `sha256:da78be17cd5ab2a293fcb90a04aaf1f510ea2660b4962f92830dd1251ae7830a`)
does not run on real arm64 hardware: `exec container process /init: Exec format
error`. Forensic check (17 of 18 layers byte-identical to the amd64 manifest;
`io.hass.arch=amd64` label on the "arm64" pull) shows the one layer that
differs contains amd64 binaries despite the manifest claiming arm64 — a bug in
their build pipeline (see `Dockerfile`'s header comment for the full
writeup), not in the upstream vendor image
(`ghcr.io/ihost-open-source-project/hassio-ihost-silabs-multiprotocol-aarch64:1.0.2`,
independently verified clean). This repo builds from that verified base
instead, reusing antoniocifu's wrapper logic (plain shell + s6-rc.d service
definitions, no compiled code, so their arch bug can't follow it here), and
publishes the result to GHCR so it never has to be built on the target
hardware (a Raspberry Pi 4B).

## Changes made to the vendored files (Apache-2.0 §4(b) notice)

- `Dockerfile`: rewritten. Hardcodes the `aarch64` base image by digest instead
  of resolving `${TARGETARCH}` via a build arg (this repo only ever targets
  arm64 hardware); drops the `armv7`-specific apt branch for the same reason;
  moves the `universal-silabs-flasher` pip pin into `requirements.txt` so
  Dependabot can track version bumps. Everything else (env defaults, the
  Supervisor-stripping cleanup `RUN`, `COPY rootfs /`, `WORKDIR`, `VOLUME`,
  `ENTRYPOINT`) is unchanged from upstream.
- `rootfs/etc/s6-overlay/s6-rc.d/zigbeed-socket/run` and
  `rootfs/etc/s6-overlay/s6-rc.d/zigbeed-tcp/run`: **content unchanged**, mode
  corrected from the upstream repo's `100644` to `100755`. Both are
  `type: longrun` s6-rc services — s6-supervise executes `run` directly via
  `execve()`, which requires the executable bit. Every other `run` script in
  this repo is `100755`; these two are the only exceptions, and
  `zigbeed-tcp/run` is the exact `socat` bridge that exposes EZSP over TCP on
  port 20108 — the one thing this whole MultiPAN design depends on. Verified
  this is a real upstream inconsistency (not intentional) via GitHub's tree
  API before correcting it.
- Every other file in `rootfs/` is byte-for-byte and mode-for-mode identical
  to upstream.
