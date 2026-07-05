# syntax=docker/dockerfile:1
#
# Wrapper image for supermemory-server (self-hosted Supermemory).
# Upstream ships a single precompiled binary; no official Docker image exists.
# This image downloads and sha256-verifies the binary at build time.
#
# Build args:
#   SUPERMEMORY_VERSION  Upstream version (without 'server-v' prefix). Default: 0.0.3
#
# Registry: ghcr.io/ravibaskaran/supermemory-server
# Target archs: linux/amd64 + linux/arm64 (multi-arch manifest)
FROM debian:bookworm-slim

ARG SUPERMEMORY_VERSION=0.0.3
ARG TARGETARCH

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      curl \
      tini \
    && rm -rf /var/lib/apt/lists/*

# Map docker targetarch -> upstream asset suffix
RUN set -eux; \
    case "$TARGETARCH" in \
      amd64) ARCH=x64 ;; \
      arm64) ARCH=arm64 ;; \
      *) echo "unsupported TARGETARCH: $TARGETARCH" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /usr/local/bin/supermemory-server \
      "https://github.com/supermemoryai/supermemory/releases/download/server-v${SUPERMEMORY_VERSION}/supermemory-server-linux-${ARCH}" \
    && chmod +x /usr/local/bin/supermemory-server \
    && curl -fsSL \
      "https://github.com/supermemoryai/supermemory/releases/download/server-v${SUPERMEMORY_VERSION}/supermemory-server-linux-${ARCH}.sha256" \
      | awk '{print $1"  /usr/local/bin/supermemory-server"}' > /tmp/check.sha256 \
    && sha256sum -c /tmp/check.sha256 \
    && rm /tmp/check.sha256

# Default runtime config (override at runtime via Coolify env vars)
ENV SUPERMEMORY_DATA_DIR=/data \
    PORT=6767 \
    SUPERMEMORY_PORT=6767 \
    SUPERMEMORY_NO_PROMPT=1 \
    SUPERMEMORY_NO_START=1

EXPOSE 6767
VOLUME ["/data"]

# tini reaps zombie processes properly under PID 1
ENTRYPOINT ["/usr/bin/tini", "--"]
CMD ["/usr/local/bin/supermemory-server"]
