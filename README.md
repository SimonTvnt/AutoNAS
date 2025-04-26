# Media Server with VPN Setup

This project provides a Docker-based media server setup with VPN integration, featuring qBittorrent, Jellyfin, Prometheus, and Grafana.

## Features

- 🔒 VPN integration with port forwarding (using Gluetun)
- 🎬 Media streaming server (Jellyfin)
- 📥 Torrent client (qBittorrent) with automatic port updating
- 📊 Monitoring stack (Prometheus & Grafana)
- 🔄 Automatic port synchronization between VPN and qBittorrent

## Prerequisites

- Docker
- Docker Compose
- Make

## Quick Start

1. Clone the repository:
`    git clone https://github.com/y ourusername/media-server.git
    cd media-server`

2. Copy the environment sample file and configure it: `cp .env.sample .env`
3. Edit the `.env` file with your configuration
4. Start the services: `make up`
## Available Make Commands

- `make up`: Start all services
- `make down`: Stop all services
- `make build`: Build all containers
- `make up-build`: Build and start all containers
- `make logs`: View container logs
- `make restart`: Restart all services
- `make clean`: Remove all containers and volumes

## Services

### Jellyfin
- Media server accessible at `http://localhost:8096`
- Configure your media libraries through the web interface

### qBittorrent
- Web UI available at `http://localhost:8090`
- Default credentials: admin/adminadmin
- Automatically updates ports based on VPN forwarded port

### Prometheus & Grafana
- Prometheus metrics at `http://localhost:9090`
- Grafana dashboard at `http://localhost:3000`
- Monitor your download statistics and system metrics

## Configuration Files

- `docker-compose.yml`: Main service configuration
- `prometheus/prometheus.yml`: Prometheus configuration
- `qbittorrent-config/qBittorrent/qBittorrent.conf`: qBittorrent configuration

## Monitoring

The setup includes a monitoring stack with:
- Prometheus for metrics collection
- Grafana for visualization
- Custom qBittorrent exporter for torrent statistics

## Security

- All traffic is routed through VPN
- Services are properly containerized
- Environment variables for sensitive data
- Non-root users in containers

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.