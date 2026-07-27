#!/bin/sh
set -e

if [ -z "$DERP_DOMAIN" ] || [ -z "$TARGET_SERVICE" ]; then
    echo "[Watcher] ERROR: Missing required environment variables."
    exit 1
fi

# Point directly to Caddy's default Let's Encrypt storage folder for this domain
# (If using ZeroSSL or an internal CA, adjust the issuer folder accordingly)
EXACT_CERT_DIR="/caddy_data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${DERP_DOMAIN}"


echo "[Watcher] Monitoring exact path: $EXACT_CERT_DIR"

# Watch specifically for changes to the exact certificate file
while inotifywait -e close_write --format '%file' "$EXACT_CERT_DIR" | grep -q "$DERP_DOMAIN.crt"; do
    echo "[Watcher] Certificate renewal detected for $DERP_DOMAIN!"
    echo "[Watcher] Restarting container for service: $TARGET_SERVICE..."
    
    docker restart "$TARGET_SERVICE"
    
    echo "[Watcher] Restart command sent. Resuming watch..."
done
