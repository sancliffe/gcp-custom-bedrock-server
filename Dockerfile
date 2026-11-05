FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies required by Mojang's native Bedrock binary
RUN apt-get update && apt-get install -y \
    curl \
    unzip \
    libcurl4 \
    libssl3 \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create working and data directories
WORKDIR /opt/minecraft
RUN mkdir -p /data /opt/minecraft

# Download and extract the official Linux Bedrock Dedicated Server binary
# (Using User-Agent header as Mojang blocks default curl requests)
RUN BDS_URL=$(curl -s -H "Accept-Encoding: identity" -H "User-Agent: Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36" https://www.minecraft.net/en-us/download/server/bedrock | grep -oP 'https://www\.minecraft\.net/bedrock-dedicated-server/bin-linux/[^"]+' | head -n 1) \
    && echo "Downloading from: ${BDS_URL}" \
    && curl -s -H "User-Agent: Mozilla/5.0" -o bedrock-server.zip "${BDS_URL}" \
    && unzip bedrock-server.zip -d /opt/minecraft/server \
    && rm bedrock-server.zip

# Set up volume for persistent world data and configurations
VOLUME ["/data"]
WORKDIR /opt/minecraft/server

# Expose ports required for Bedrock and NetherNet
EXPOSE 19132/tcp
EXPOSE 19132/udp
EXPOSE 19133/udp
EXPOSE 19140-19150/udp

# Entrypoint script to handle configuration symlinking and launch the server
COPY <<'EOF' /opt/minecraft/start.sh
#!/bin/bash
# Link persistent data directory files if they don't exist yet
if [ ! -f /data/server.properties ]; then
    cp /opt/minecraft/server/server.properties /data/server.properties
fi
if [ ! -f /data/permissions.json ]; then
    cp /opt/minecraft/server/permissions.json /data/permissions.json
fi
if [ ! -f /data/allowlist.json ]; then
    cp /opt/minecraft/server/allowlist.json /data/allowlist.json
fi

# Point the server config to the persistent volume
rm -f /opt/minecraft/server/server.properties
rm -rf /opt/minecraft/server/worlds
ln -s /data/server.properties /opt/minecraft/server/server.properties
ln -s /data/worlds /opt/minecraft/server/worlds
ln -s /data/allowlist.json /opt/minecraft/server/allowlist.json
ln -s /data/permissions.json /opt/minecraft/server/permissions.json

# Launch Bedrock server with proper library path
export LD_LIBRARY_PATH=/opt/minecraft/server
exec ./bedrock_server
EOF

RUN chmod +x /opt/minecraft/start.sh

CMD ["/opt/minecraft/start.sh"]