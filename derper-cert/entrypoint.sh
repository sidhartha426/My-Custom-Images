#!/bin/sh

if [ -z "$DERP_DOMAIN" ] || [ -z "$TARGET_CONTAINER" ]; then
    echo "[Watcher] ERROR: Missing required environment variables." >&2
    exit 1
fi

EXACT_CERT_DIR="/caddy_data/caddy/certificates/acme-v02.api.letsencrypt.org-directory/${DERP_DOMAIN}"

# Guard clause to wait for Caddy provisioning
while [ ! -d "$EXACT_CERT_DIR" ]; do
    echo "[Watcher] Directory $EXACT_CERT_DIR not found. Waiting for Caddy..."
    sleep 5
done

echo "[Watcher] Monitoring exact path: $EXACT_CERT_DIR"

# Because of `tini -g`, we can safely use the standard pipe without creating unkillable ghosts.
# When Docker stops, tini blasts the whole pipeline with SIGTERM.
inotifywait -m -q -e close_write --format '%f' "$EXACT_CERT_DIR" | \
while read -r filename; do
    if [ "$filename" = "${DERP_DOMAIN}.crt" ]; then
        echo "[Watcher] Certificate renewal detected for $DERP_DOMAIN!"
        
        if docker restart "$TARGET_CONTAINER"; then
            echo "[Watcher] Restart command sent successfully."
        else
            echo "[Watcher] ERROR: Failed to restart $TARGET_CONTAINER." >&2
        fi
    fi
done
