FROM --platform=$BUILDPLATFORM alpine:3.23 AS repo-fetcher
WORKDIR /workspace

RUN apk add --no-cache git
RUN git clone --revision=b3c0c1c691c721f2f3af4b84a18afccf8d9e4a24 --depth 1 https://github.com/tale/headplane.git /workspace
RUN sed -i 's|const origin = url\.origin;|const origin = url.origin.replace(/^http:/, "https:");|g' /workspace/app/routes/ssh/page.tsx


FROM --platform=$BUILDPLATFORM golang:1.25.1 AS go-base
WORKDIR /run
RUN apt-get update && apt-get install -y --no-install-recommends patch && rm -rf /var/lib/apt/lists/*

COPY --from=repo-fetcher /workspace/go.mod /workspace/go.sum /workspace/build.sh ./
COPY --from=repo-fetcher /workspace/patches/ ./patches/
RUN go mod download

COPY --from=repo-fetcher /workspace/cmd/ ./cmd/
COPY --from=repo-fetcher /workspace/internal/ ./internal/

ARG TARGETOS
ARG TARGETARCH
ARG IMAGE_TAG
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH CGO_ENABLED=0 IMAGE_TAG=$IMAGE_TAG \
	./build.sh --wasm --agent --fake-shell --healthcheck \
		--wasm-output /bin/hp_ssh.wasm \
		--agent-output /bin/hp_agent \
		--fake-shell-output /bin/fake-sh \
		--healthcheck-output /bin/hp_healthcheck

# Consolidated for cleaner layers
RUN chmod +x /bin/hp_ssh.wasm /bin/hp_agent /bin/fake-sh /bin/hp_healthcheck

# Folder needs to exist for later stages
RUN mkdir -p /var/lib/headplane/agent


FROM --platform=$BUILDPLATFORM node:24-slim AS js-base
WORKDIR /run

RUN corepack enable
# FIXED: Use absolute paths
COPY --from=repo-fetcher /workspace/patches ./patches
COPY --from=repo-fetcher /workspace/package.json /workspace/pnpm-lock.yaml /workspace/build.sh ./

COPY --from=go-base /bin/hp_ssh.wasm /run/public/hp_ssh.wasm
COPY --from=go-base /bin/wasm_exec.js /run/public/wasm_exec.js
RUN ./build.sh --app --app-install-only

# FIXED: Removed the hidden non-breaking space before the '.'
COPY --from=repo-fetcher /workspace .
ARG HEADPLANE_VERSION
RUN HEADPLANE_VERSION=$HEADPLANE_VERSION ./build.sh --app


FROM gcr.io/distroless/nodejs24-debian13:latest AS final
COPY --from=js-base /run/build /app/build
COPY --from=js-base /run/drizzle /app/drizzle

COPY --from=go-base /bin/hp_agent /usr/libexec/headplane/agent
COPY --from=go-base /var/lib/headplane /var/lib/headplane

# Fake shell to inform the user that they should use the debug image
COPY --from=go-base /bin/fake-sh /bin/sh
COPY --from=go-base /bin/fake-sh /bin/bash

COPY --from=go-base /bin/hp_healthcheck /bin/hp_healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
	CMD ["/bin/hp_healthcheck"]

# Tells Headplane to publish its loopback healthcheck URL to this
# file on startup; `hp_healthcheck` reads it. Docker-only — native
# installs don't ship a consumer.
ENV HEADPLANE_LISTEN_FILE=/tmp/headplane-listen

WORKDIR /app
CMD [ "/app/build/server/index.js" ]
