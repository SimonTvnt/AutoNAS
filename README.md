# AutoNas: Secure, Automated NAS + Torrent + Media Server

AutoNas is a fully automated, self-hosted media management solution that combines:

* A torrent client (qBittorrent) routed through a VPN (Gluetun)
* A full media automation stack (Sonarr, Radarr, Prowlarr)
* A personal media server (Jellyfin)
* Secure remote access via Tailscale

All wrapped in Docker for easy deployment.

> ⚠️ Disclaimer: This project is for educational and personal use only. If you enjoy a movie or show, support the creators by purchasing it or subscribing to the official VOD platforms.

## ✨ Features

* VPN Protection: All torrent traffic is routed through Gluetun (with WireGuard and port forwarding).
* Download Automation: Sonarr and Radarr automate your shows and movies via indexers managed by Prowlarr.
* Media Streaming: Jellyfin offers Netflix-like access to your collection.
* Remote Access: Seamless connection via Tailscale from anywhere.
* Monitoring with NetData: Keep an eye on your system's performance and health.


## 🚀 How It Works

1. VPN: Gluetun connects to ProtonVPN using WireGuard with port forwarding enabled.
2. Torrenting: qBittorrent is configured to run inside Gluetun's network.
3. Automation:
   * Sonarr (series) and Radarr (movies) monitor content availability
   * Prowlarr connects to torrent indexers and handles search
4. Download Flow:
   * Once a match is found, the torrent is sent to qBittorrent
   * Downloaded files are moved and renamed
   * Jellyfin scans the new media and updates your library 
5. Remote Access: Tailscale lets you access Jellyfin from any device.

## 🌐 Configuration Steps

### 1. Set Environment Variables

Create a .env file:
`cp .env.example .env`

Update the values according to your setup
### 2. Configure Gluetun (with ProtonVPN)

In docker-compose.yml, Gluetun is the network stack. Ensure:

* You have WireGuard credentials
* Port forwarding is enabled

### 3. Configure Jellyfin Media Paths

Ensure the /media/movies and /media/shows paths are writable by the container user (usually UID 1000).

### 4. Configure qBittorrent

Inside qBittorrent:

* Set incoming port (synced via script)
* Enable folder-per-torrent download
* Set default path to /media/downloads or similar

### 5. Configure Sonarr, Radarr, and Prowlarr

Add root folders: /media/movies (Radarr), /media/shows (Sonarr)

Set download clients: qbittorrent with /media/downloads as base path

Configure indexers in Prowlarr

## ⚒️ Development / Contribution

PRs and suggestions welcome! This project is designed to be modular and self-hosted.

## 🌐 Future Ideas

* Optional FileBot integration
* Web dashboard for monitoring/downloads/configuration
* Telegram or Discord notifications
* DNS setup for global access through the web
* User management
* Various security/performance improvements
* Support other VPN providers (ProtonVPN is currently hardcoded)


