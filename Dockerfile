# Adapted from https://github.com/antoniocifu/ihost-multipan-docker (Apache-2.0,
# see NOTICE and vendored LICENSE-antoniocifu in this directory).
#
# Deviations from upstream, both deliberate:
#
# 1. Base image pinned to a fixed digest, no TARGETARCH build arg. Upstream's
#    Dockerfile resolves `FROM .../hassio-ihost-silabs-multiprotocol-${TARGETARCH}`
#    with `ARG TARGETARCH=amd64` as the default. Their published arm64 manifest
#    (antoniocifu/ihost-multipan-docker:1.0.0, digest da78be17c...) is broken: 17
#    of its 18 layers are byte-identical to the amd64 manifest, the one that
#    differs contains amd64 binaries despite the manifest claiming arm64, and
#    running it produces `exec container process /init: Exec format error` on
#    real arm64 hardware. Their io.hass.arch label even says amd64. Root cause
#    is almost certainly their CI never threading a per-platform TARGETARCH
#    into this build arg, so the amd64 default silently wins for every
#    platform leg. This image only ever targets Raspberry Pi 4B (aarch64), so
#    we sidestep the whole bug class: no ARG, no ambiguity, the base is
#    hardcoded and pinned. Verified independently against the actual vendor
#    image (ghcr.io/ihost-open-source-project/hassio-ihost-silabs-
#    multiprotocol-aarch64:1.0.2): its config and io.hass.arch both correctly
#    say arm64/aarch64, and its layers are genuinely arm64-specific — the bug
#    is in antoniocifu's build, not upstream.
# 2. Dropped the armv7-specific apt branch (build-essential etc.) — this image
#    only ever builds for aarch64.
# 3. universal-silabs-flasher's version pin lives in requirements.txt instead
#    of inline, so Dependabot's pip ecosystem can track and bump it.
FROM ghcr.io/ihost-open-source-project/hassio-ihost-silabs-multiprotocol-aarch64:1.0.2@sha256:8456e9956ab81dfbe874e60c00a2f23ab5f1f9d3f57ee6afea092eacd9843357

ENV S6_VERBOSITY=3 \
    DEVICE="/dev/ttyUSB0" \
    BAUDRATE="115200" \
    CPCD_TRACE="false" \
    CPCP_DISABLE_ENCRYPTION="true" \
    FLOW_CONTROL="false" \
    NETWORK_DEVICES=0 \
    OTBR_ENABLE=1 \
    BACKBONE_IF="eth0" \
    OTBR_LOG_LEVEL="notice" \
    OTB_FIREWALL=1 \
    OTBR_REST_LISTEN_PORT="8081" \
    OTBR_WEB_PORT="8086" \
    NETWORK_DEVICE="" \
    EZSP_LISTEN_PORT="20108" \
    AUTOFLASH_FIRMWARE=0 \
    FIRMWARE=""

RUN rm -rf /etc/s6-overlay/s6-rc.d/banner && \
    rm -rf /etc/s6-overlay/scripts/banner.sh && \
    rm -rf /etc/s6-overlay/s6-rc.d/universal-silabs-flasher/dependencies.d && \
    rm -rf /etc/s6-overlay/s6-rc.d/otbr-agent-rest-discovery && \
    rm -rf /etc/s6-overlay/scripts/otbr-agent-rest-discovery.sh && \
    rm -rf /etc/s6-overlay/s6-rc.d/user/contents.d/otbr-agent-rest-discovery && \
    rm -rf /etc/s6-overlay/s6-rc.d/cpcd-config && \
    rm -rf /etc/s6-overlay/s6-rc.d/cpcd/dependencies.d && \
    rm -rf /usr/bin/bashio && \
    rm -rf *.gbl && \
    rm -rf firmware && \
    rm -rf /home/firmware && \
    rm -rf /root/*.gbl

COPY requirements.txt /tmp/requirements.txt

# `apt-get upgrade` pulls in Debian's own security patches for whatever's
# already installed (no version/behavior change, just patched CVEs). The
# purge list is headers and a standalone compiler (linux-libc-dev,
# libc6-dev, libc-dev-bin, zlib1g-dev, libprotobuf-dev, protobuf-compiler) —
# never dynamically linked or exec'd at runtime, so removing them can't
# break the already-compiled cpcd/zigbeed/otbr-agent binaries. Confirmed via
# a Trivy scan of an actual build: linux-libc-dev alone accounted for 2557
# of 3513 OS-package findings (71%).
# ponytail: other flagged packages (nodejs, bind9-*, avahi-*, sudo/passwd/
# login) look unused too — nothing in rootfs/ references them, and our own
# mdns service runs mDNSResponder (mdnsd), not avahi — but cpcd/otbr-agent
# are closed-source vendor binaries and might dynamically link against some
# of these (e.g. libmbedtls* for cpcd's encryption layer). Don't remove
# without verifying against the actual binaries (ldd) or a real hardware
# test; a wrong guess here bricks Zigbee/Thread on real hardware.
#
# CONFIRMED BROKEN on real hardware (2026-07-26): `--auto-remove` on
# libprotobuf-dev also swept away libprotobuf-lite23, the runtime .so that
# libprotobuf-dev pulled in as a dependency. apt has no idea otbr-agent (a
# vendor binary outside dpkg's tracking) dynamically links it, so it saw
# nothing left depending on it and took it with the header package.
# otbr-agent then crash-looped forever: "error while loading shared
# libraries: libprotobuf-lite.so.23". Fix: purge libprotobuf-dev/
# protobuf-compiler WITHOUT --auto-remove, so their runtime-needed
# dependency stays. --auto-remove is still fine for the plain header
# packages (linux-libc-dev etc.) — nothing runtime-linked depends on them.
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends python3-pip \
    && apt-get purge -y --auto-remove \
      linux-libc-dev libc6-dev libc-dev-bin zlib1g-dev \
    && apt-get purge -y \
      libprotobuf-dev protobuf-compiler \
    && rm -rf /var/lib/apt/lists/* && \
    pip install -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

COPY rootfs /

WORKDIR /

VOLUME /data

ENTRYPOINT ["/init"]
