#!/bin/bash

set -eu

# Configuration
BACKUP_DIR="${BACKUP_DIR:-./backups}"
RETENTION_DAYS="${RETENTION_DAYS:-7}"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="autonas_backup_${DATE}"

# Volumes to backup (without project prefix)
VOLUMES=(
  "radarr_config"
  "sonarr_config"
  "prowlarr_config"
  "jellyfin_config"
  "flaresolverr_config"
)

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

log_warning() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] WARNING: $1" >&2
}

# Find Docker volume by suffix (handles different project names)
find_volume() {
  local volume_suffix="$1"
  docker volume ls --format '{{.Name}}' | grep "_${volume_suffix}$" | head -1
}

# Create backup directory
mkdir -p "${BACKUP_DIR}"

log "Starting AutoNas backup..."
log "Backup directory: ${BACKUP_DIR}"
log "Backup name: ${BACKUP_NAME}"

# Security warning
log_warning "SECURITY: This backup will include .env file with sensitive credentials."
log_warning "SECURITY: Store backups securely and consider encrypting them."

# Create temporary directory for this backup
TEMP_DIR=$(mktemp -d)
trap "rm -rf '${TEMP_DIR}'" EXIT

# Backup Docker volumes
log "Backing up Docker volumes..."

for volume_suffix in "${VOLUMES[@]}"; do
  FULL_VOLUME_NAME=$(find_volume "$volume_suffix")

  if [ -n "$FULL_VOLUME_NAME" ]; then
    log "  - Backing up volume: ${FULL_VOLUME_NAME}"
    docker run --rm \
      -v "${FULL_VOLUME_NAME}:/source:ro" \
      -v "${TEMP_DIR}:/backup" \
      alpine tar czf "/backup/${volume_suffix}.tar.gz" -C /source .
  else
    log "  - Volume not found (skipping): *_${volume_suffix}"
  fi
done

# Backup bind-mounted directories
log "Backing up qBittorrent config..."
if [ -d "./qbittorrent-config" ]; then
  tar czf "${TEMP_DIR}/qbittorrent-config.tar.gz" -C . qbittorrent-config
else
  log "  - qbittorrent-config directory not found (skipping)"
fi

log "Backing up Tailscale state..."
if [ -d "./tailscale-state" ]; then
  tar czf "${TEMP_DIR}/tailscale-state.tar.gz" -C . tailscale-state
else
  log "  - tailscale-state directory not found (skipping)"
fi

# Backup environment file (sensitive - handle with care)
log "Backing up environment file..."
if [ -f ".env" ]; then
  cp .env "${TEMP_DIR}/env.backup"
  log_warning "  - .env file backed up (contains sensitive data!)"
else
  log "  - .env file not found (skipping)"
fi

# Backup Traefik config if exists
if [ -d "./traefik" ]; then
  log "Backing up Traefik config..."
  tar czf "${TEMP_DIR}/traefik-config.tar.gz" -C . traefik
fi

# Create final archive
log "Creating final backup archive..."
FINAL_BACKUP="${BACKUP_DIR}/${BACKUP_NAME}.tar.gz"
tar czf "${FINAL_BACKUP}" -C "${TEMP_DIR}" .

# Calculate backup size
BACKUP_SIZE=$(du -h "${FINAL_BACKUP}" | cut -f1)
log "Backup complete: ${FINAL_BACKUP} (${BACKUP_SIZE})"

# Cleanup old backups
log "Cleaning up backups older than ${RETENTION_DAYS} days..."
DELETED_COUNT=$(find "${BACKUP_DIR}" -name "autonas_backup_*.tar.gz" -type f -mtime "+${RETENTION_DAYS}" -delete -print | wc -l)
log "Deleted ${DELETED_COUNT} old backup(s)"

# List current backups
log "Current backups:"
ls -lh "${BACKUP_DIR}"/autonas_backup_*.tar.gz 2>/dev/null | while read -r line; do
  log "  $line"
done

log "Backup process completed successfully!"
log_warning "Remember: Backup contains sensitive credentials. Store securely!"
