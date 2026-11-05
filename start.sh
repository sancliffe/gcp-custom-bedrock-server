#!/bin/bash
set -e

SERVER_DIR="/opt/minecraft/server"
DATA_DIR="/data"

# Initialize configuration and world files on persistent volume if missing
for file in server.properties permissions.json allowlist.json; do
    if [ ! -f "${DATA_DIR}/${file}" ] && [ -f "${SERVER_DIR}/${file}" ]; then
        cp "${SERVER_DIR}/${file}" "${DATA_DIR}/${file}"
    fi
done

if [ ! -d "${DATA_DIR}/worlds" ]; then
    mkdir -p "${DATA_DIR}/worlds"
fi

# Link configuration files and worlds directory to persistent volume
for file in server.properties allowlist.json permissions.json; do
    rm -f "${SERVER_DIR}/${file}"
    ln -s "${DATA_DIR}/${file}" "${SERVER_DIR}/${file}"
done

rm -rf "${SERVER_DIR}/worlds"
ln -s "${DATA_DIR}/worlds" "${SERVER_DIR}/worlds"

export LD_LIBRARY_PATH="${SERVER_DIR}"

# Graceful shutdown trap to handle SIGTERM (Docker/Podman stop signals)
pid=0
term_handler() {
    if [ $pid -ne 0 ]; then
        echo "Received SIGTERM. Saving world and shutting down Bedrock server gracefully..."
        kill -SIGTERM "$pid"
        wait "$pid"
    }
    exit 0
}

trap 'term_handler' SIGTERM INT

# Launch the Bedrock server binary in the background so trap can catch signals
cd "${SERVER_DIR}"
./bedrock_server &
pid=$!

# Wait for process completion
wait "$pid"