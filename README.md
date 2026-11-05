# GCP Custom Minecraft Bedrock Server Container

[![Docker Image](https://img.shields.io/badge/Docker%20Hub-superflea2828%2Fgcp--custom--bedrock--server-blue?logo=docker)](https://hub.docker.com/r/superflea2828/gcp-custom-bedrock-server)
[![GitHub Repository](https://img.shields.io/badge/GitHub-sancliffe%2Fgcp--custom--bedrock--server-black?logo=github)](https://github.com/sancliffe/gcp-custom-bedrock-server)
[![Infrastructure Repository](https://img.shields.io/badge/GCP--IaC-sancliffe%2Fgcp--minecraft--iac-orange?logo=googlecloud)](https://github.com/sancliffe/gcp-minecraft-iac)

A lightweight, fully custom Minecraft Bedrock Dedicated Server container built on standard **Ubuntu 24.04** using native Mojang Linux binaries. 

This repository provides a clean, dependency-minimal alternative to generic image stacks, tuned specifically for low-resource cloud environments like **Google Cloud Platform (GCP)** free-tier VM instances (`e2-micro` / `e2-small`) and optimized for high-performance cross-platform mobile and console connectivity via the **NetherNet** transport protocol.

---

## 🌟 Key Features

- **Native Binary Execution:** Runs official Mojang Bedrock Linux binaries directly on Ubuntu 24.04 without unnecessary base layers.
- **Low-Resource Optimized:** Configured out-of-the-box for low RAM/CPU footprint, ideal for GCP free-tier resources.
- **Mobile & Console Cross-Play Ready:** Implements `nethernet` transport with optimized network parameters to mitigate high latency, ping spikes, and packet bloat on Android, iOS, and console clients.
- **Persistent Data Volume:** Symlinks configuration files (`server.properties`, `allowlist.json`, `permissions.json`) and world data to a persistent `/data` volume.
- **Container Tooling Compatibility:** Fully compatible with both **Podman** and **Docker**.

---

## 🚀 Quick Start

### 1. Using Docker Compose

Create a `docker-compose.yml` file on your server:

```yaml
services:
  bedrock-server:
    image: docker.io/superflea2828/gcp-custom-bedrock-server:latest
    container_name: gcp-bedrock-server
    restart: unless-stopped
    network_mode: host
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    volumes:
      - ./data:/data
```

Start the server:

```bash
docker compose up -d
```

### 2. Using Podman (CLI)

```bash
podman run -d \
  --name gcp-bedrock-server \
  --net=host \
  -v ./data:/data:Z \
  --restart=unless-stopped \
  docker.io/superflea2828/gcp-custom-bedrock-server:latest
```

---

## ⚙️ Configuration & Performance Tuning

### Default Ports

Ensure your host system and cloud firewalls expose the required TCP and UDP ports:

| Port | Protocol | Purpose |
| :--- | :--- | :--- |
| `19132` | TCP | Bedrock initial signaling handshake |
| `19132` | UDP | Default Bedrock IPv4 gameplay traffic |
| `19133` | UDP | Bedrock IPv6 gameplay traffic |
| `19140-19150` | UDP | NetherNet WebRTC peer connection range |

### Recommended `server.properties` (GCP Free-Tier & Mobile Clients)

When mounted to `/data/server.properties`, the following parameters are pre-tuned for smooth performance on `e2-micro` instances:

```properties
server-name=Steanlabs Bedrock Server
gamemode=survival
difficulty=normal
allow-cheats=false
max-players=10
online-mode=true
allow-list=true
server-port=19132
server-portv6=19133
server-udp-ports=19140-19150
transport=nethernet

# Performance & Latency Optimization for Cloud VMs
view-distance=6
tick-distance=4
max-threads=2
server-authoritative-movement-strict=false
compression-threshold=1
compression-algorithm=zlib
```

---

## 🛠️ Building & Pushing Locally

### Using Podman

1. **Build the container:**
   ```bash
   podman build -t superflea2828/gcp-custom-bedrock-server:latest .
   ```

2. **Authenticate with Docker Hub:**
   ```bash
   podman login docker.io -u superflea2828
   ```

3. **Tag and Push to Registry:**
   ```bash
   podman tag superflea2828/gcp-custom-bedrock-server:latest docker.io/superflea2828/gcp-custom-bedrock-server:latest
   podman push docker.io/superflea2828/gcp-custom-bedrock-server:latest
   ```

---

## 🤖 CI/CD Automation

This repository includes automated builds via **GitHub Actions** (`.github/workflows/docker-publish.yml`).

### Required GitHub Secrets
To enable automated publishing on push to `main`, set the following secrets in your repository settings (**Settings > Secrets and variables > Actions**):

- `DOCKER_USERNAME`: `superflea2828`
- `DOCKER_TOKEN`: *Your Docker Hub Personal Access Token (PAT)*

---

## 📂 Related Repositories

- **Infrastructure as Code (IaC):** [sancliffe/gcp-minecraft-iac](https://github.com/sancliffe/gcp-minecraft-iac) — Terraform configuration for provisioning the GCP instance, VPC networks, firewall rules, and backup storage bucket.

---

## 📄 License

This project is open-source and available under the [MIT License](LICENSE). 

*Minecraft is a registered trademark of Mojang Synergies AB. This project is not affiliated with or endorsed by Mojang or Microsoft.*