ARG DERPER_VERSION=v1.98.9

FROM --platform=$BUILDPLATFORM golang:1.26-alpine AS builder
ARG DERPER_VERSION
RUN apk add --no-cache git

RUN git clone --depth 1 --branch ${DERPER_VERSION} https://github.com/tailscale/tailscale.git /workspace
WORKDIR /workspace

ARG TARGETOS
ARG TARGETARCH

RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o /go/bin/derper ./cmd/derper



FROM alpine:latest
RUN apk add --no-cache ca-certificates

ARG DERPER_VERSION
ENV DERPER_VERSION=${DERPER_VERSION}

COPY --from=builder /go/bin/derper /usr/local/bin/derper
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
