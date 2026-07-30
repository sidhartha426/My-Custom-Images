#!/bin/sh
exec derper -hostname "${DERP_DOMAIN}" \
        -certmode manual \
        -certdir /caddy_data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${DERP_DOMAIN} \
        -a "[::]:8443" \
        -stun \
        -stun-port 34479 \
        -verify-client-url "${VERIFY_URL}" \
        -verify-client-url-fail-open=false
