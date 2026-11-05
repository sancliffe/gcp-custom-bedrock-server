FROM ubuntu:24.04

LABEL maintainer="steve@steanlabs.com"
LABEL description="Hardened Minecraft Bedrock Dedicated Server for GCP"

# Keep package installation non-interactive without persisting this setting
# into the runtime container.
ARG DEBIAN_FRONTEND=noninteractive

# Pin the Bedrock Dedicated Server version for reproducible builds.
ARG BDS_VERSION=1.26.62.1

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    libatomic1 \
    libcurl4 \
    libgcc-s1 \
    libssl3 \
    libstdc++6 \
    procps \
    unzip \
    zlib1g \
    && rm -rf /var/lib/apt/lists/*

# Dedicated non-root account
RUN groupadd --system --gid 999 minecraft && \
    useradd --system --uid 999 --gid 999 \
        --home-dir /home/minecraft \
        --create-home \
        --shell /usr/sbin/nologin \
        minecraft

# Application and persistent-data directories
RUN mkdir -p /opt/minecraft/server /data && \
    chown -R 999:999 /opt/minecraft /data

# Copy local archive into the container instead of downloading over network
COPY bedrock-server-1.26.62.1.zip /tmp/bedrock-server.zip

RUN set -eu; \
    unzip -tq /tmp/bedrock-server.zip; \
    unzip -q /tmp/bedrock-server.zip -d /opt/minecraft/server; \
    rm -f /tmp/bedrock-server.zip; \
    chown -R 999:999 /opt/minecraft/server; \
    test -x /opt/minecraft/server/bedrock_server

# Configuration
COPY --chown=999:999 server.properties /opt/minecraft/server/server.properties

RUN printf '[]\n' > /opt/minecraft/server/allowlist.json && \
    chown 999:999 /opt/minecraft/server/allowlist.json

# Entrypoint
COPY --chown=999:999 start.sh /opt/minecraft/start.sh
RUN chmod 755 /opt/minecraft/start.sh

# Persistent world/configuration data managed by start.sh
VOLUME ["/data"]

WORKDIR /opt/minecraft/server

# Bedrock networking
EXPOSE 19132/udp
EXPOSE 19133/udp
EXPOSE 19132/tcp
EXPOSE 19140-19150/udp

# Run as the dedicated unprivileged account
USER 999:999

# Healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD pgrep -x bedrock_server >/dev/null || exit 1

ENTRYPOINT ["/opt/minecraft/start.sh"]