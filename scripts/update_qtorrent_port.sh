#!/bin/bash

set -eu

# Configuration from environment variables
GLUETUN_API="${GLUETUN_API:-http://localhost:8000}"
GLUETUN_USER="${GLUETUN_USER:-}"
GLUETUN_PASS="${GLUETUN_PASS:-}"
QBIT_HOST="${QBIT_HOST:-http://localhost:8080}"
QBIT_USER="${QBIT_USER:-admin}"
QBIT_PASS="${QBIT_PASS:-adminadmin}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"

# Build curl auth args for Gluetun
GLUETUN_AUTH=""
if [ -n "$GLUETUN_USER" ] && [ -n "$GLUETUN_PASS" ]; then
  GLUETUN_AUTH="-u ${GLUETUN_USER}:${GLUETUN_PASS}"
fi

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

# Wait for Gluetun to be ready
wait_for_gluetun() {
  log "Waiting for Gluetun API to be available..."
  until curl -sf $GLUETUN_AUTH "${GLUETUN_API}/v1/portforward" > /dev/null 2>&1; do
    log "Gluetun not ready, retrying in 10s..."
    sleep 10
  done
  log "Gluetun API is available"
}

# Wait for qBittorrent to be ready
wait_for_qbittorrent() {
  log "Waiting for qBittorrent API to be available..."
  until curl -sf "${QBIT_HOST}/api/v2/app/version" > /dev/null 2>&1; do
    log "qBittorrent not ready, retrying in 10s..."
    sleep 10
  done
  log "qBittorrent API is available"
}

# Get forwarded port from Gluetun
get_forwarded_port() {
  local response
  if ! response=$(curl -sf $GLUETUN_AUTH "${GLUETUN_API}/v1/portforward" 2>/dev/null); then
    log_error "Failed to fetch forwarded port from Gluetun"
    return 1
  fi

  if [ -z "$response" ]; then
    log_error "Empty response from Gluetun"
    return 1
  fi

  local port
  port=$(echo "$response" | jq -r '.port // empty')
  if [ -z "$port" ] || [ "$port" = "0" ]; then
    log_error "Invalid port received from Gluetun: $response"
    return 1
  fi

  echo "$port"
}

# Authenticate to qBittorrent and get session cookie
get_qbit_cookie() {
  local login_response
  if ! login_response=$(curl -sf -i --data "username=${QBIT_USER}&password=${QBIT_PASS}" \
    "${QBIT_HOST}/api/v2/auth/login" 2>/dev/null); then
    log_error "Failed to connect to qBittorrent"
    return 1
  fi

  local cookie
  cookie=$(echo "$login_response" | grep -i "set-cookie" | sed -n 's/.*\(SID=[^;]*\).*/\1/p')

  if [ -z "$cookie" ]; then
    log_error "Failed to authenticate to qBittorrent"
    return 1
  fi

  echo "$cookie"
}

# Get current qBittorrent listen port
get_current_qbit_port() {
  local cookie="$1"
  local prefs
  if ! prefs=$(curl -sf --cookie "$cookie" "${QBIT_HOST}/api/v2/app/preferences" 2>/dev/null); then
    return 1
  fi
  echo "$prefs" | jq -r '.listen_port // empty'
}

# Update qBittorrent listen port
update_qbit_port() {
  local cookie="$1"
  local port="$2"

  if ! curl -sf --cookie "$cookie" \
    "${QBIT_HOST}/api/v2/app/setPreferences" \
    --data "json={\"listen_port\":${port}}" > /dev/null 2>&1; then
    log_error "Failed to update qBittorrent port"
    return 1
  fi

  return 0
}

# Main sync function
sync_port() {
  # Get forwarded port from Gluetun
  local port
  if ! port=$(get_forwarded_port); then
    return 1
  fi

  if [ -z "$port" ]; then
    log_error "No port returned from Gluetun"
    return 1
  fi

  # Get qBittorrent session
  local cookie
  if ! cookie=$(get_qbit_cookie); then
    return 1
  fi

  if [ -z "$cookie" ]; then
    log_error "No cookie returned from qBittorrent"
    return 1
  fi

  # Check current port
  local current_port
  current_port=$(get_current_qbit_port "$cookie") || current_port=""

  if [ "$current_port" = "$port" ]; then
    log "Port already set to $port, no update needed"
    return 0
  fi

  # Update port
  log "Updating qBittorrent port from ${current_port:-unknown} to $port"
  if update_qbit_port "$cookie" "$port"; then
    log "Successfully updated qBittorrent port to $port"
    return 0
  else
    return 1
  fi
}

# Main loop
main() {
  log "Port sync service starting..."
  log "Configuration: GLUETUN_API=$GLUETUN_API, QBIT_HOST=$QBIT_HOST"

  # Wait for dependencies
  wait_for_gluetun
  wait_for_qbittorrent

  log "Starting port sync loop (interval: ${CHECK_INTERVAL}s)"

  while true; do
    if ! sync_port; then
      log_error "Port sync failed, will retry in ${CHECK_INTERVAL}s"
    fi
    sleep "$CHECK_INTERVAL"
  done
}

main
