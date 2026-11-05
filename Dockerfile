
FROM ubuntu:24.04

LABEL maintainer="steve@steanlabs.com"
LABEL description="Hardened Minecraft Bedrock Dedicated Server for GCP"

# Build configuration
ARG DEBIAN_FRONTEND=noninteractive
ARG BDS_VERSION=latest
# Supply explicitly if you want a fallback when Mojang's page cannot be parsed.
ARG BDS_FALLBACK_VERSION=""

# Runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    libcurl4 \
    libssl3 \
    libstdc++6 \
    libgcc-s1 \
    libatomic1 \
    zlib1g \
    ca-certificates \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Dedicated non-root account
RUN groupadd -g 999 minecraft && \
    useradd -u 999 -g minecraft -m -s /usr/sbin/nologin minecraft

# Application directories
RUN mkdir -p /opt/minecraft/server /data && \
    chown -R 999:999 /opt/minecraft /data

# Download and install official Bedrock Dedicated Server
RUN set -eu; \
    BDS_URL=""; \
    if [ "${BDS_VERSION}" = "latest" ]; then \
        echo "Resolving latest Bedrock Dedicated Server version..."; \
        if curl -f -s -L \
            --retry 3 \
            --connect-timeout 15 \
            --max-time 120 \
            -H "User-Agent: Mozilla/5.0" \
            -o /tmp/bedrock-download.html \
            "https://www.minecraft.net/en-us/download/server/bedrock"; then \
            BDS_URL="$(grep -Eo 'https://www\.minecraft\.net/bedrock-dedicated-server/bin-linux/[^\"[:space:]]+' /tmp/bedrock-download.html | head -n 1 || true)"; \
        fi; \
        if [ -z "${BDS_URL}" ]; then \
            if [ -z "${BDS_FALLBACK_VERSION}" ]; then \
                echo "ERROR: Unable to resolve latest BDS version and no fallback configured."; \
                exit 1; \
            fi; \
            echo "Using explicitly configured fallback: ${BDS_FALLBACK_VERSION}"; \
            BDS_URL="https://www.minecraft.net/bedrock-dedicated-server/bin-linux/bedrock-server-${BDS_FALLBACK_VERSION}.zip"; \
        fi; \
    else \
        BDS_URL="https://www.minecraft.net/bedrock-dedicated-server/bin-linux/bedrock-server-${BDS_VERSION}.zip"; \
    fi; \
    echo "Downloading: ${BDS_URL}"; \
    curl -f -s -L \
        --retry 3 \
        --connect-timeout 15 \
        --max-time 300 \
        -H "User-Agent: Mozilla/5.0" \
        -o /tmp/bedrock-server.zip \
        "${BDS_URL}"; \
    unzip -tq /tmp/bedrock-server.zip; \
    unzip -q /tmp/bedrock-server.zip -d /opt/minecraft/server; \
    rm -f /tmp/bedrock-server.zip /tmp/bedrock-download.html; \
    chown -R 999:999 /opt/minecraft/server

# Configuration
COPY --chown=999:999 server.properties /opt/minecraft/server/server.properties

RUN printf '[]\n' > /opt/minecraft/server/allowlist.json && \
    chown 999:999 /opt/minecraft/server/allowlist.json

# Entrypoint
COPY --chown=999:999 start.sh /opt/minecraft/start.sh

RUN chmod 755 /opt/minecraft/start.sh

# Persistent world data
VOLUME ["/data"]

WORKDIR /opt/minecraft/server

# Bedrock networking
EXPOSE 19132/udp
EXPOSE 19133/udp
EXPOSE 19132/tcp
EXPOSE 19140-19150/udp

# Non-root execution
USER 999:999

# Process health check.
# This verifies the server process exists, not that clients can connect.
HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
    CMD pgrep -x bedrock_server >/dev/null || exit 1

ENTRYPOINT ["/opt/minecraft/start.sh"]
