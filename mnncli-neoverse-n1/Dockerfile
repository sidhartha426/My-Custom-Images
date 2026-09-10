# ==========================================
# Stage 1: Builder
# ==========================================
FROM alpine:latest AS builder

# Set environment variables for the GitHub release
# UPDATE THESE with your actual GitHub details
ENV GITHUB_USER="sidhartha426"
ENV REPO="My-Custom-Images"
ENV VERSION="v1.0.0"
ENV BINARY_NAME="mnncli"

# Install certificates and wget in the builder stage only
RUN apk add --no-cache ca-certificates wget

# Download the binary to a temporary location and make it executable
RUN wget -q "https://github.com/${GITHUB_USER}/${REPO}/releases/download/${BINARY_NAME}-${VERSION}/${BINARY_NAME}" -O /tmp/${BINARY_NAME} \
    && chmod +x /tmp/${BINARY_NAME}


# ==========================================
# Stage 2: Final Image
# ==========================================
FROM debian:13-slim

# Copy the executable binary from the builder stage directly into PATH
COPY --from=builder /tmp/mnncli /usr/local/bin/mnncli

# Install runtime dependencies (like ca-certificates if your CLI makes web requests)
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /model

# Execute the CLI with the specified arguments
# We use the JSON array syntax (exec form) which is the recommended approach
CMD ["stdbuf", "-oL", "mnncli", "serve", "-c", "/model/config.json"]
