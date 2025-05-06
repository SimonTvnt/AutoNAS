# Media Server with VPN Setup

This project provides a Docker-based media server setup with VPN integration (ProtonVPN via Gluetun), featuring qBittorrent as torrent client, Jellyfin, Radarr, Sonarr, Prowlarr and Flaresolverr as media managers, and Netdata for monitoring. It also has a Tailscale client for access outside your local network.

**⚠️ This project is for educational and personal use only. If you enjoy a movie or show, support the creators by purchasing it or subscribing to the official VOD platforms.**

Feel free to contribute to improve the project ! 🚀

Missing nice to have :
- Notification system
- Global configuration UI
- DNS setup for global access through the web
- User management
- Various security/performance improvements

## Features

- 🔒 VPN integration with port forwarding (using Gluetun)
- 📥 Torrent client (qBittorrent) with automatic port updating
- 📊 Monitoring (NetData)
- 🔄 Automatic port synchronization between VPN and qBittorrent
- 🍿 Media Management (Jellyfin, Sonarr, Radarr, Prowlarr)

## Prerequisites

- Docker
- Docker Compose
- Make

## Quick Start

1. Clone the repository:
`    git clone https://github.com/y ourusername/media-server.git
    cd AutoNas`

2. Copy the environment sample file and configure it: `cp .env.sample .env`
3. Edit the `.env` file with your configuration
4. Start the services: `make up-build`
   
## Available Make Commands

- `make up`: Start all services
- `make down`: Stop all services
- `make build`: Build all containers
- `make up-build`: Build and start all containers
- `make logs`: View container logs
- `make restart`: Restart all services
- `make clean`: Remove all containers and volumes

## Configuration details
- Go to each service landing page to start configure each of them


## Services

### Prowlarr
- Torrent index accessible at `http://localhost:9696`
- Connect to your favorite torrent provider to automate search
- Plug Flaresolverr service for better compatibility

### Sonarr/Radarr
- Media provider accessible at `http://localhost:8989` and `http://localhost:7878`
- Search and follow Shows/Movies, automatic torrent download when plugged with Prowlarr and QBittorrent
- Plug Prowlarr and Qbittorrent services

### Jellyfin
- Media server accessible at `http://localhost:8096`
- Configure your media libraries through the web interface

### qBittorrent
- Web UI available at `http://localhost:8080`
- Default credentials: admin/adminadmin
- Automatically updates ports based on VPN forwarded port

### NetData
- Agent Console at `http://localhost:1999`
- Monitor your download statistics and system metrics

## Configuration Files
- `docker-compose.yml`: Main service configuration
- `qbittorrent-config/qBittorrent/qBittorrent.conf`: qBittorrent configuration

## Security
- All traffic is routed through VPN
- Services are properly containerized
- Environment variables for sensitive data
- Non-root users in containers

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.
