#!/bin/sh

# Fail fast if required environment variables are missing
if [ -z "$DERP_DOMAIN" ]; then
    echo "ERROR: DERP_DOMAIN environment variable is not set."
    exit 1
fi

if [ -z "$VERIFY_URL" ]; then
    echo "ERROR: VERIFY_URL environment variable is not set."
    exit 1
fi

DEST_DIR="/certs"
mkdir -p "$DEST_DIR"

# Function to locate the newest certificate directory for the domain.
# This solves the Caddy CA roulette problem natively by sorting 
# issuer directories by modification time descending (`ls -t`).
get_cert_dir() {
    ls -dt /caddy_data/caddy/certificates/*/"$DERP_DOMAIN" 2>/dev/null | head -n 1
}

echo "Waiting for Caddy to fetch certificates for $DERP_DOMAIN..."
while true; do
    CERT_DIR=$(get_cert_dir)
    if [ -n "$CERT_DIR" ]; then
        CERT_FILE="$CERT_DIR/$DERP_DOMAIN.crt"
        KEY_FILE="$CERT_DIR/$DERP_DOMAIN.key"

        # Ensure files exist and are not empty (-s) to prevent race conditions
        if [ -s "$CERT_FILE" ] && [ -s "$KEY_FILE" ]; then
            echo "Valid certificates found! Creating symlinks for derper..."
            ln -sf "$CERT_FILE" "$DEST_DIR/$DERP_DOMAIN.crt"
            ln -sf "$KEY_FILE" "$DEST_DIR/$DERP_DOMAIN.key"
            break
        fi
    fi
    sleep 5
done

# Function to start derper in the background
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

# Trap SIGTERM to allow graceful container shutdowns
trap 'echo "Container stopping... Shutting down derper."; kill -TERM $DERPER_PID 2>/dev/null; exit 0' TERM INT

echo "Starting standalone derper..."
start_derper

# Record the initial MD5 hash of the symlinked certificate
CURRENT_HASH=$(md5sum "$DEST_DIR/$DERP_DOMAIN.crt" | awk '{print $1}')

echo "Monitoring certificate renewals and process health..."
while true; do
    # Check derper process health every 60 seconds over a 12-hour window (720 * 60s = 43200s)
    # This prevents the container from silently sitting as a zombie if derper crashes.
    i=0
    while [ $i -lt 720 ]; do
        if ! kill -0 $DERPER_PID 2>/dev/null; then
            echo "ERROR: Derper process ($DERPER_PID) crashed unexpectedly. Exiting container."
            exit 1
        fi
        sleep 60
        i=$((i + 1))
    done

    # Re-evaluate certificate paths (handles CA fallback changes)
    CERT_DIR=$(get_cert_dir)
    if [ -n "$CERT_DIR" ]; then
        NEW_CERT_FILE="$CERT_DIR/$DERP_DOMAIN.crt"
        NEW_KEY_FILE="$CERT_DIR/$DERP_DOMAIN.key"

        if [ -s "$NEW_CERT_FILE" ] && [ -s "$NEW_KEY_FILE" ]; then
            ln -sf "$NEW_CERT_FILE" "$DEST_DIR/$DERP_DOMAIN.crt"
            ln -sf "$NEW_KEY_FILE" "$DEST_DIR/$DERP_DOMAIN.key"

            NEW_HASH=$(md5sum "$DEST_DIR/$DERP_DOMAIN.crt" | awk '{print $1}')
            
            if [ "$CURRENT_HASH" != "$NEW_HASH" ]; then
                echo "Certificate renewal detected! Gracefully restarting derper..."
                
                kill -TERM $DERPER_PID
                wait $DERPER_PID 2>/dev/null || true
                
                start_derper
                CURRENT_HASH=$NEW_HASH
            fi
        fi
    fi
done
