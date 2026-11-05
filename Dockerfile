FROM ubuntu:24.04

LABEL maintainer="steve@steanlabs.com"
LABEL description="Production-hardened custom Minecraft Bedrock Dedicated Server for GCP"

# Prevent interactive prompts during apt installation
ENV DEBIAN_FRONTEND=noninteractive

# Build arguments for pinned version reproducibility (defaults to latest if unset)
ARG BDS_VERSION=latest

# Install runtime dependencies and netcat for container healthchecks
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    unzip \
    libcurl4 \
    libssl3 \
    ca-certificates \
    netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

# Create a dedicated non-root system user and group with a clean unreserved ID (999)
RUN groupadd -g 999 minecraft && \
    useradd -u 999 -g minecraft -m -s /bin/bash minecraft

# Create application and persistent data directories with proper numeric ownership
RUN mkdir -p /opt/minecraft/server /data && \
    chown -R 999:999 /opt/minecraft /data

# Download and extract the official Linux Bedrock Dedicated Server binary with a guaranteed version fallback
RUN if [ "${BDS_VERSION}" = "latest" ]; then \
        BDS_URL=$(curl -s -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64)" https://www.minecraft.net/en-us/download/server/bedrock | grep -oP 'https://www\.minecraft\.net/bedrock-dedicated-server/bin-linux/[^"]+' | head -n 1); \
        if [ -z "${BDS_URL}" ]; then \
            echo "Scraping blocked, using pinned stable release version fallback..."; \
            BDS_URL="https://www.minecraft.net/bedrock-dedicated-server/bin-linux/bedrock-server-1.21.51.01.zip"; \
        fi; \
    else \
        BDS_URL="https://www.minecraft.net/bedrock-dedicated-server/bin-linux/bedrock-server-${BDS_VERSION}.zip"; \
    fi \
    && echo "Downloading Bedrock Server from: ${BDS_URL}" \
    && curl -f -s -L -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" -o /tmp/bedrock-server.zip "${BDS_URL}" \
    && unzip /tmp/bedrock-server.zip -d /opt/minecraft/server \
    && rm /tmp/bedrock-server.zip

# Copy configuration templates safely and set ownership to minecraft user
COPY server.properties /opt/minecraft/server/server.properties
RUN echo '[]' > /opt/minecraft/server/allowlist.json && \
    chown 999:999 /opt/minecraft/server/server.properties /opt/minecraft/server/allowlist.json

# Copy entrypoint script and set executable permissions & ownership
COPY start.sh /opt/minecraft/start.sh
RUN chmod +x /opt/minecraft/start.sh && \
    chown 999:999 /opt/minecraft/start.sh

# Set up volume for persistent world data and configurations
VOLUME ["/data"]
WORKDIR /opt/minecraft/server

# Expose ports required for Bedrock gameplay and NetherNet signaling
EXPOSE 19132/tcp
EXPOSE 19132/udp
EXPOSE 19133/udp
EXPOSE 19140-19150/udp

# Switch to unprivileged non-root user (using numeric ID for maximum reliability)
USER 999:999

# Add native container healthcheck verifying server process/port availability
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
    CMD nc -z -u 127.0.0.1 19132 || exit 1

ENTRYPOINT ["/opt/minecraft/start.sh"]