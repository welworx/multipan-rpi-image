#!/usr/bin/with-contenv bash
# ==============================================================================
# Enable socat-cpcd-tcp service if needed
# ==============================================================================
source /etc/bashlog/log.sh;

if [ -n "${NETWORK_DEVICE}" ]; then
    touch /etc/s6-overlay/s6-rc.d/user/contents.d/socat-cpcd-tcp
    touch /etc/s6-overlay/s6-rc.d/cpcd/dependencies.d/socat-cpcd-tcp
    log 'info' "Enabled socat-cpcd-tcp."
fi
