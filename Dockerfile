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
FROM ghcr.io/ihost-open-source-project/hassio-ihost-silabs-multiprotocol-aarch64:1.0.2@sha256:fd0f5bf5bfb5543752769f3b3077820ea07586dd8e9176cc3b0fae754c27a5bc

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

RUN apt-get update && \
    apt-get install -y --no-install-recommends python3-pip \
    && rm -rf /var/lib/apt/lists/* && \
    pip install -r /tmp/requirements.txt && \
    rm -f /tmp/requirements.txt

COPY rootfs /

WORKDIR /

VOLUME /data

ENTRYPOINT ["/init"]
