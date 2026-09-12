# ==========================================
# Stage 1: Builder
# ==========================================
FROM alpine:latest AS builder

ENV GITHUB_USER="sidhartha426"
ENV REPO="My-Custom-Images"
ENV VERSION="v1.0.0"
ENV BINARY_NAME="mnncli"

RUN apk add --no-cache ca-certificates wget

RUN wget -q "https://github.com/${GITHUB_USER}/${REPO}/releases/download/${BINARY_NAME}-${VERSION}/${BINARY_NAME}" -O /tmp/${BINARY_NAME} \
    && chmod +x /tmp/${BINARY_NAME}


# ==========================================
# Stage 2: Final Image
# ==========================================
FROM debian:13-slim

COPY --from=builder /tmp/mnncli /usr/local/bin/mnncli

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /model

CMD ["/bin/bash", "-c", "exec /usr/bin/tini -- stdbuf -oL mnncli serve -v --host :: --port 8000 -c /models/$MODEL_NAME/"]
