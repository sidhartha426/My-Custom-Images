#!/bin/sh

# Fail fast if required environment variables are missing
if [ -z "$DERP_DOMAIN" ] || [ -z "$VERIFY_URL" ]; then
    echo "ERROR: DERP_DOMAIN or VERIFY_URL environment variable is not set."
    exit 1
fi

DEST_DIR="/certs"
mkdir -p "$DEST_DIR"

# 1. Define trap IMMEDIATELY so container can always be stopped gracefully
trap 'echo "Container stopping..."; [ -n "$DERPER_PID" ] && kill -TERM "$DERPER_PID" 2>/dev/null; exit 0' TERM INT

get_cert_dir() {
    ls -dt /caddy_data/caddy/certificates/*/"$DERP_DOMAIN" 2>/dev/null | head -n 1
}

echo "Waiting for Caddy to fetch certificates for $DERP_DOMAIN..."
while true; do
    CERT_DIR=$(get_cert_dir)
    if [ -n "$CERT_DIR" ]; then
        CERT_FILE="$CERT_DIR/$DERP_DOMAIN.crt"
        KEY_FILE="$CERT_DIR/$DERP_DOMAIN.key"

        # Ensure files exist and are not empty
        if [ -s "$CERT_FILE" ] && [ -s "$KEY_FILE" ]; then
            echo "Valid certificates found! Creating symlinks for derper..."
            ln -sf "$CERT_FILE" "$DEST_DIR/$DERP_DOMAIN.crt"
            ln -sf "$KEY_FILE" "$DEST_DIR/$DERP_DOMAIN.key"
            break
        fi
    fi
    # Interruptible sleep!
    sleep 5 & wait $!
done

start_derper() {
    derper -hostname "$DERP_DOMAIN" \
        -certmode manual \
        -certdir "$DEST_DIR" \
        -a :443 \
        -stun \
        -stun-port 34479 \
        -verify-client-url "$VERIFY_URL" \
        -verify-client-url-fail-open=false &
    
    DERPER_PID=$!
}

echo "Starting standalone derper..."
start_derper

# Record the initial MD5 hash of the ACTUAL cert file (not the symlink)
CURRENT_HASH=$(md5sum "$CERT_DIR/$DERP_DOMAIN.crt" | awk '{print $1}')

echo "Monitoring certificate renewals and process health..."
while true; do
    # Interruptible sleep handles our 60-second delay natively
    sleep 60 & wait $!

    # Check derper process health
    if ! kill -0 "$DERPER_PID" 2>/dev/null; then
        echo "ERROR: Derper process ($DERPER_PID) crashed unexpectedly. Exiting container."
        exit 1
    fi

    # Re-evaluate certificate paths
    CERT_DIR=$(get_cert_dir)
    if [ -n "$CERT_DIR" ]; then
        NEW_CERT_FILE="$CERT_DIR/$DERP_DOMAIN.crt"
        NEW_KEY_FILE="$CERT_DIR/$DERP_DOMAIN.key"

        if [ -s "$NEW_CERT_FILE" ] && [ -s "$NEW_KEY_FILE" ]; then
            NEW_HASH=$(md5sum "$NEW_CERT_FILE" | awk '{print $1}')
            
            # Only act if the hash has fundamentally changed
            if [ "$CURRENT_HASH" != "$NEW_HASH" ]; then
                echo "Certificate renewal detected! Gracefully restarting derper..."
                
                ln -sf "$NEW_CERT_FILE" "$DEST_DIR/$DERP_DOMAIN.crt"
                ln -sf "$NEW_KEY_FILE" "$DEST_DIR/$DERP_DOMAIN.key"
                
                kill -TERM "$DERPER_PID"
                wait "$DERPER_PID" 2>/dev/null || true
                
                start_derper
                CURRENT_HASH=$NEW_HASH
            fi
        fi
    fi
done
