# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

AutoNAS is a Docker-based self-hosted media automation platform for Raspberry Pi and Linux systems. It combines VPN-protected torrenting, automated media discovery/downloading, and personal media streaming.

**License**: Apache 2.0

## Repository Structure

```
AutoNAS/
├── docker/
│   └── port_sync/
│       └── Dockerfile          # Custom Alpine image for port-sync service
├── scripts/
│   ├── update_qtorrent_port.sh # Port sync daemon (runs in port-sync container)
│   ├── backup_nas.sh           # Backup Docker volumes and configs
│   └── check_vpn.sh            # VPN verification and leak detection
├── traefik/
│   ├── traefik.yml             # Traefik static configuration
│   └── dynamic.yml             # Traefik routing rules (edit ports here if changed)
├── docker-compose.yml          # Main service definitions
├── Makefile                    # All operational commands
├── .env.sample                 # Template for required environment variables
├── .gitignore
├── README.md
└── CLAUDE.md
```

**Not tracked by git** (generated at runtime):
- `.env` — production credentials
- `qbittorrent-config/` — qBittorrent settings (bind mount)
- `tailscale-state/` — Tailscale persistent data
- `gluetun/` — Gluetun VPN data
- `backups/` — Backup archives
- `media/` — Media library

## Commands

All commands use the Makefile and require a `.env` file:

```bash
# Setup
cp .env.sample .env              # Create config, then edit values

# Core operations
make up              # Start all services (docker compose up -d)
make down            # Stop all services
make build           # Build custom Docker images (port-sync)
make up-build        # Build and start services
make logs            # View Docker logs (follows)
make restart         # Recreate containers (--force-recreate, no image pull)
make update          # Pull latest images then restart
make deploy          # Full deploy: build + pull + start
make clean           # Stop services and remove volumes (destructive)

# Utilities
make backup          # Backup configs and volumes to ./backups/
make check-vpn       # Verify VPN is working (single check, --once flag)
```

The `check-env` target is an internal prerequisite that validates `.env` exists before running most commands.

## Architecture

### Service Stack

```
Indexers → Prowlarr → Sonarr/Radarr → qBittorrent (via Gluetun VPN)
                                            │
                                       /media/downloads
                                            │
                                       Jellyfin (streaming)
                                            │
                                  Accessible via Tailscale
```

### Network Topology

Services are grouped into three networks:

| Network | Services |
|---------|----------|
| **Gluetun** (VPN-protected, `network_mode: service:gluetun`) | qBittorrent, Sonarr, Radarr, Prowlarr, FlareSolverr, port-sync |
| **Host** (`network_mode: host`) | Tailscale (requires NET_ADMIN + NET_RAW) |
| **Bridge** (default Docker bridge) | Jellyfin, Netdata, Traefik |

Gluetun exposes all VPN-network service ports to the host; only Gluetun has `ports:` defined for those services.

### Services

| Service | Image | Port Env Var | Default Port | Network |
|---------|-------|-------------|--------------|---------|
| gluetun | qmcgaw/gluetun:latest | GLUETUN_HEALTHCHECK_PORT | 9999 | (gateway) |
| qbittorrent | linuxserver/qbittorrent:latest | QBIT_PORT | 8080 | gluetun |
| port-sync | Custom (docker/port_sync/) | — | — | gluetun |
| prowlarr | ghcr.io/almottier/prowlarr-ygg:latest | PROWLARR_PORT | 9696 | gluetun |
| sonarr | lscr.io/linuxserver/sonarr:latest | SONARR_PORT | 8989 | gluetun |
| radarr | lscr.io/linuxserver/radarr:latest | RADARR_PORT | 7878 | gluetun |
| flaresolverr | alexfozor/flaresolverr:pr-1300-experimental | FLARESOLVERR_PORT | 8191 | gluetun |
| jellyfin | jellyfin/jellyfin:latest | JELLYFIN_PORT | 8096 | bridge |
| tailscale | tailscale/tailscale:latest | — | — | host |
| netdata | netdata/netdata:latest | NETDATA_PORT | 19999 | bridge |
| watchtower | containrrr/watchtower:latest | — | — | default |
| traefik | traefik:latest | 9080/9443 | — | bridge |

> **Note**: Prowlarr uses a custom image `prowlarr-ygg` (with YGG tracker support), not the standard linuxserver image. FlareSolverr uses a community PR fork.

### Startup Order / Dependencies

```
gluetun (healthy)
  ├── qbittorrent (healthy)
  │   └── port-sync
  ├── sonarr
  ├── radarr
  ├── prowlarr
  └── flaresolverr
```

All other services (jellyfin, tailscale, netdata, watchtower, traefik) start independently.

## Environment Variables

All variables are set in `.env` (copied from `.env.sample`):

```bash
# Media Storage
MEDIA_DIR=/path/to/your/media   # Root for downloads/, shows/, movies/

# System
TZ=Europe/Paris                  # Container timezone
PUID=1000                        # User ID for file ownership
PGID=1000                        # Group ID for file ownership

# Gluetun VPN (ProtonVPN WireGuard)
VPN_SERVICE_PROVIDER=protonvpn
VPN_TYPE=wireguard
WIREGUARD_PRIVATE_KEY=           # From ProtonVPN WireGuard config
WIREGUARD_ADDRESSES=10.2.0.2/32 # From ProtonVPN WireGuard config
WIREGUARD_PUBLIC_KEY=            # From ProtonVPN WireGuard config
SERVER_COUNTRIES=France          # Preferred VPN server country

# Gluetun Control Server (used by port-sync and check_vpn.sh)
GLUETUN_USER=admin
GLUETUN_PASSWORD=adminadmin

# qBittorrent Credentials
QBIT_USER=admin
QBIT_PASSWORD=adminadmin

# Service Ports (Gluetun exposes these from VPN network to host)
QBIT_PORT=8080
PROWLARR_PORT=9696
SONARR_PORT=8989
RADARR_PORT=7878
FLARESOLVERR_PORT=8191

# Direct-access service ports
JELLYFIN_PORT=8096
NETDATA_PORT=19999
GLUETUN_HEALTHCHECK_PORT=9999   # Internal Gluetun health endpoint

# Tailscale
TS_AUTHKEY=                      # From Tailscale admin console

# Backup Configuration
BACKUP_DIR=./backups             # Backup output directory
RETENTION_DAYS=7                 # Days to keep backup archives

# Watchtower (optional)
# WATCHTOWER_SCHEDULE=0 0 4 * * *        # Cron schedule (default: 4am daily)
# WATCHTOWER_NOTIFICATION_URL=           # Shoutrrr URL for alerts
```

## Data Paths

```
${MEDIA_DIR}/
├── downloads/    # qBittorrent download destination
├── shows/        # Sonarr root folder → mounted in Jellyfin as /shows
└── movies/       # Radarr root folder → mounted in Jellyfin as /movies

./qbittorrent-config/   # qBittorrent settings (bind mount, gitignored)
./tailscale-state/      # Tailscale persistent state (bind mount, gitignored)
./backups/              # Backup archives (gitignored)
```

Named Docker volumes (managed by Docker):
- `radarr_config`, `sonarr_config`, `prowlarr_config`, `flaresolverr_config`
- `jellyfin_config`, `jellyfin_cache`
- `netdataconfig`, `netdatalib`, `netdatacache`

## Custom Scripts

### `scripts/update_qtorrent_port.sh` (port-sync service)

Runs continuously inside the port-sync container. Synchronizes qBittorrent's listen port with Gluetun's dynamically assigned forwarded port.

**Flow:**
1. Waits for Gluetun API (`http://localhost:8000/v1/portforward`) to be available
2. Waits for qBittorrent API to be available
3. Every `CHECK_INTERVAL` seconds (default: 60):
   - Queries Gluetun for forwarded port (`/v1/portforward`)
   - Logs in to qBittorrent and gets session cookie
   - Checks current listen port (`/api/v2/app/preferences`)
   - Updates only if port changed (`/api/v2/app/setPreferences`)

**Environment variables consumed:**
- `GLUETUN_API` (default: `http://localhost:8000`)
- `GLUETUN_USER`, `GLUETUN_PASS`
- `QBIT_HOST`, `QBIT_USER`, `QBIT_PASS`
- `CHECK_INTERVAL` (default: 60)

> Gluetun control server is always on internal port **8000** (not configurable via env in docker-compose.yml).

### `scripts/backup_nas.sh`

Creates timestamped compressed archives of all service configurations.

**What is backed up:**
- Docker named volumes: `radarr_config`, `sonarr_config`, `prowlarr_config`, `jellyfin_config`, `flaresolverr_config`
- Bind-mounted directories: `./qbittorrent-config/`, `./tailscale-state/`
- Project files: `.env` (contains credentials!), `./traefik/`

**Security warning**: The `.env` file (with credentials) is included. Store backups securely.

**Retention**: Automatically deletes archives older than `RETENTION_DAYS` (default: 7).

**Output**: `${BACKUP_DIR}/autonas_backup_YYYYMMDD_HHMMSS.tar.gz`

### `scripts/check_vpn.sh`

Verifies VPN is running and no traffic leaks to the real IP.

**Checks performed:**
1. Gluetun VPN status via API (`/v1/openvpn/status`)
2. Gets host public IP (via ipify.org / ifconfig.me / icanhazip.com)
3. Gets VPN public IP via Gluetun (`/v1/publicip/ip`)
4. Gets qBittorrent's public IP (via `docker exec`)
5. Alerts if host IP equals VPN IP (VPN leak) or qBittorrent uses host IP

**Modes:**
- `--once` flag: Single check and exit (used by `make check-vpn`)
- No flag: Continuous monitoring every `CHECK_INTERVAL` seconds (default: 300)

**Optional `ALERT_SCRIPT`**: Path to executable run on VPN leak detection.

## Custom Docker Image: port-sync

Located at `docker/port_sync/Dockerfile`. Built from Alpine 3.18.

**Key characteristics:**
- Pinned package versions: `curl=8.12.1-r0`, `bash=5.2.15-r5`, `jq=1.6-r4`
- Runs as non-root `appuser`
- Working directory: `/rpi_scripts`
- Script copied to `/update.sh`
- Health check: `pgrep -f "update.sh"` every 60s

Rebuilt by `make build` or `make up-build`.

## Traefik Configuration

Provides named access to all services via `.localhost` hostnames.

### Static config (`traefik/traefik.yml`)
- Dashboard enabled at `traefik.localhost` (insecure mode for local use)
- Entry points: `web` (port 80), `websecure` (port 443)
- Providers: Docker (read labels) + file (`dynamic.yml`, hot-reload)

### Dynamic config (`traefik/dynamic.yml`)
Routes HTTP traffic from hostname to backend service:

| URL | Backend |
|-----|---------|
| `jellyfin.localhost:9080` | `host.docker.internal:8096` |
| `qbit.localhost:9080` | `host.docker.internal:8080` |
| `sonarr.localhost:9080` | `host.docker.internal:8989` |
| `radarr.localhost:9080` | `host.docker.internal:7878` |
| `prowlarr.localhost:9080` | `host.docker.internal:9696` |
| `netdata.localhost:9080` | `host.docker.internal:19999` |
| `traefik.localhost:9080` | Traefik dashboard (via Docker label) |

> **Important**: If you change port values in `.env`, you must also update the hardcoded port numbers in `traefik/dynamic.yml`.

## Watchtower

Automatically updates all containers daily at 4am (cron: `0 0 4 * * *`).

**Key behaviors:**
- Cleans up old images after update (`WATCHTOWER_CLEANUP=true`)
- Rolling restart to minimize downtime
- Skips stopped containers, does not revive them
- 30s timeout per container update

Override schedule via `WATCHTOWER_SCHEDULE` in `.env`. Enable notifications via `WATCHTOWER_NOTIFICATION_URL` (Shoutrrr format).

## Healthchecks

All services define Docker healthchecks with 30s intervals and 40s start periods (Gluetun: 120s start period, 10 retries). Services in the Gluetun network depend on `gluetun: condition: service_healthy`.

## Key Conventions

1. **Never commit `.env`** — it's gitignored; contains credentials.
2. **All service changes go in `docker-compose.yml`** — no separate override files.
3. **Port changes require dual updates**: `docker-compose.yml` env var AND `traefik/dynamic.yml`.
4. **VPN-protected services** must use `network_mode: service:gluetun` and NOT define their own `ports:` — only Gluetun defines ports for this group.
5. **Scripts use `set -eu`** (strict mode) — all errors are fatal. Add proper error handling for new script additions.
6. **The port-sync container** reads credentials via environment variables, not the `.env` file directly (Docker Compose handles injection).
7. **qbittorrent-config is a bind mount** (not a named volume) to allow easy access and backup of qBittorrent settings.

## Common Operations

### Add a new service
1. Add service definition to `docker-compose.yml`
2. If VPN-protected: use `network_mode: service:gluetun`, add port to Gluetun's `ports:`, add `depends_on: gluetun`
3. If needs Traefik routing: add router/service to `traefik/dynamic.yml`
4. If has named volume: add to `volumes:` section at bottom of `docker-compose.yml`
5. If needs env vars: add to `.env.sample` with documentation

### Change a service port
1. Update the port variable in `.env`
2. Update hardcoded port number in `traefik/dynamic.yml` (both router and service backend)
3. Restart: `make restart`

### Restore from backup
```bash
# Extract backup
tar xzf backups/autonas_backup_YYYYMMDD_HHMMSS.tar.gz -C /tmp/restore/

# Restore a named volume (example: sonarr_config)
docker run --rm \
  -v autonas_sonarr_config:/target \
  -v /tmp/restore:/backup \
  alpine sh -c "cd /target && tar xzf /backup/sonarr_config.tar.gz"

# Restore qbittorrent-config
tar xzf /tmp/restore/qbittorrent-config.tar.gz -C .
```

### Check system health
```bash
docker compose ps                # All container statuses
make check-vpn                   # Verify VPN (single check)
make logs                        # Follow all logs
docker compose logs gluetun -f   # Follow specific service
```
