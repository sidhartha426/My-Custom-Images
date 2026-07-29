FROM --platform=$BUILDPLATFORM caddy:2.11.4-builder-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

RUN GOOS=$TARGETOS GOARCH=$TARGETARCH xcaddy build \
    --with github.com/ueffel/caddy-brotli \
    --with github.com/caddy-dns/cloudflare

FROM caddy:2.11.4-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy
