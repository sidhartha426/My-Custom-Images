#!/bin/sh

# Check if DERP_DOMAIN is set and not empty
if [ -z "${DERP_DOMAIN}" ]; then
    echo "Error: DERP_DOMAIN environment variable is missing."
    exit 1
fi

# Check if VERIFY_URL is set and not empty
if [ -z "${VERIFY_URL}" ]; then
    echo "Error: VERIFY_URL environment variable is missing."
    exit 1
fi

# Announce startup details
echo "Derper server is running on domain: ${DERP_DOMAIN}"
echo "Verification server is running at: ${VERIFY_URL}"

# Execute derper
exec derper -hostname "${DERP_DOMAIN}" \
        -certmode manual \
        -certdir "/caddy_data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${DERP_DOMAIN}" \
        -a "[::]:8443" \
        -stun \
        -stun-port 34479 \
        -verify-client-url "${VERIFY_URL}" \
        -verify-client-url-fail-open=false

