# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AutoNas is a Docker-based self-hosted media automation platform for Raspberry Pi and Linux systems. It combines VPN-protected torrenting, automated media discovery/downloading, and personal media streaming.

## Commands

All commands use the Makefile and require a `.env` file:

```bash
# Core operations
make up              # Start all services
make down            # Stop all services
make build           # Build custom Docker images (port-sync)
make up-build        # Build and start services
make logs            # View Docker logs (follows)
make restart         # Recreate containers (no downtime, no image pull)
make update          # Pull latest images and restart
make deploy          # Full deploy (rebuild + pull + start)
make clean           # Stop services and remove volumes

# Utilities
make backup          # Backup configs and volumes
make check-vpn       # Verify VPN is working correctly
```

To set up: `cp .env.sample .env` and configure values.

## Architecture

### Service Stack

```
Indexers -> Prowlarr -> Sonarr/Radarr -> qBittorrent (via Gluetun VPN)
                                              |
                                         /media/downloads
                                              |
                                         Jellyfin (streaming)
                                              |
                                    Accessible via Tailscale
```

### Network Topology

- **Gluetun network** (VPN-protected): qBittorrent, Sonarr, Radarr, Prowlarr, FlareSolverr, port-sync
- **Host network**: Tailscale (requires NET_ADMIN)
- **Bridge network**: Jellyfin, NetData

### Services

| Service | Purpose | Port Env Var |
|---------|---------|--------------|
| gluetun | VPN client (ProtonVPN/WireGuard) with port forwarding | - |
| qbittorrent | Torrent client | QBIT_PORT |
| port-sync | Syncs Gluetun forwarded port to qBittorrent | - |
| prowlarr | Indexer manager | PROWLARR_PORT |
| sonarr | TV series automation | SONARR_PORT |
| radarr | Movie automation | RADARR_PORT |
| flaresolverr | Cloudflare CAPTCHA solver | FLARESOLVERR_PORT |
| jellyfin | Media server | JELLYFIN_PORT |
| tailscale | Remote access VPN | - |
| netdata | System monitoring | NETDATA_PORT |
| watchtower | Automatic container updates | - |
| traefik | Reverse proxy | 9080, 9443 |

### Custom Scripts

**scripts/update_qtorrent_port.sh** (port-sync service):
- Waits for Gluetun and qBittorrent to be healthy
- Queries Gluetun API for forwarded port every 60s
- Updates qBittorrent listen port via API
- Full error handling and logging

**scripts/backup_nas.sh**:
- Backs up Docker volumes (*arr configs)
- Backs up bind-mounted directories (qbittorrent-config, tailscale-state)
- Configurable retention (RETENTION_DAYS env var)

**scripts/check_vpn.sh**:
- Verifies VPN is running and traffic is routed correctly
- Checks qBittorrent is using VPN IP
- Use `--once` flag for single check, otherwise runs continuously

### Traefik

Traefik reverse proxy is included in the main stack:
- Access services via: jellyfin.localhost, qbit.localhost, sonarr.localhost, etc.
- Dashboard at traefik.localhost
- Config in `traefik/` directory

### Watchtower

Watchtower is included in the main stack and runs by default:
- Automatic container updates daily at 4am
- Configure schedule via `WATCHTOWER_SCHEDULE` env var
- Configure notifications via `WATCHTOWER_NOTIFICATION_URL` env var

### Data Paths

- `${MEDIA_DIR}/downloads` - Torrent downloads
- `${MEDIA_DIR}/shows` - TV series (Sonarr root folder)
- `${MEDIA_DIR}/movies` - Movies (Radarr root folder)
- `./qbittorrent-config` - qBittorrent configuration (bind mount)
- `./backups` - Backup archives
- Named volumes for other service configs

### Log Rotation

Configured in `docker/daemon.json`:
- Max 10MB per log file
- Keep 3 rotated files
- Compressed storage
