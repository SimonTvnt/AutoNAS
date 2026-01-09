#!/bin/bash

set -eu

# Configuration
GLUETUN_API="${GLUETUN_API:-http://localhost:8000}"
GLUETUN_USER="${GLUETUN_USER:-}"
GLUETUN_PASSWORD="${GLUETUN_PASSWORD:-}"
QBIT_CONTAINER="${QBIT_CONTAINER:-qbittorrent}"
CHECK_INTERVAL="${CHECK_INTERVAL:-300}"  # 5 minutes default
ALERT_SCRIPT="${ALERT_SCRIPT:-}"  # Optional: path to script to run on VPN leak

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log_error() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: $1" >&2
}

alert() {
  local message="$1"
  log_error "$message"

  # Run alert script if configured (safely, without eval)
  if [ -n "$ALERT_SCRIPT" ] && [ -x "$ALERT_SCRIPT" ]; then
    log "Running alert script..."
    "$ALERT_SCRIPT" "$message" || true
  fi
}

# Create temporary netrc file for curl authentication
create_netrc() {
  local netrc_file
  netrc_file=$(mktemp)

  if [ -n "$GLUETUN_USER" ] && [ -n "$GLUETUN_PASSWORD" ]; then
    # Extract host from GLUETUN_API
    local host
    host=$(echo "$GLUETUN_API" | sed -E 's|https?://([^:/]+).*|\1|')
    echo "machine $host login $GLUETUN_USER password $GLUETUN_PASSWORD" > "$netrc_file"
    chmod 600 "$netrc_file"
  fi

  echo "$netrc_file"
}

# Get real public IP (outside VPN)
get_host_ip() {
  curl -sf --max-time 10 https://api.ipify.org 2>/dev/null || \
  curl -sf --max-time 10 https://ifconfig.me 2>/dev/null || \
  curl -sf --max-time 10 https://icanhazip.com 2>/dev/null || \
  echo ""
}

# Get VPN public IP via Gluetun
get_vpn_ip() {
  local netrc_file="$1"
  local netrc_opt=""

  if [ -s "$netrc_file" ]; then
    netrc_opt="--netrc-file $netrc_file"
  fi

  curl -sf --max-time 10 $netrc_opt "${GLUETUN_API}/v1/publicip/ip" 2>/dev/null | jq -r '.public_ip // empty' || echo ""
}

# Get Gluetun VPN status
get_vpn_status() {
  local netrc_file="$1"
  local netrc_opt=""

  if [ -s "$netrc_file" ]; then
    netrc_opt="--netrc-file $netrc_file"
  fi

  curl -sf --max-time 10 $netrc_opt "${GLUETUN_API}/v1/openvpn/status" 2>/dev/null | jq -r '.status // empty' || echo ""
}

# Check qBittorrent connectivity through VPN
check_qbit_vpn() {
  # This checks if qBittorrent can reach the internet through VPN
  if docker ps --format '{{.Names}}' | grep -q "^${QBIT_CONTAINER}$"; then
    docker exec "$QBIT_CONTAINER" curl -sf --max-time 10 https://api.ipify.org 2>/dev/null || echo ""
  else
    echo ""
  fi
}

# Main check function
check_vpn() {
  log "Checking VPN status..."

  # Create netrc for authenticated requests
  local netrc_file
  netrc_file=$(create_netrc)
  trap "rm -f '$netrc_file'" RETURN

  # Check Gluetun status
  local vpn_status
  vpn_status=$(get_vpn_status "$netrc_file")

  if [ "$vpn_status" != "running" ]; then
    alert "VPN is not running! Status: ${vpn_status:-unknown}"
    return 1
  fi

  log "VPN status: running"

  # Get IPs
  local host_ip
  local vpn_ip
  local qbit_ip

  host_ip=$(get_host_ip)
  vpn_ip=$(get_vpn_ip "$netrc_file")
  qbit_ip=$(check_qbit_vpn)

  log "Host IP: ${host_ip:-unknown}"
  log "VPN IP: ${vpn_ip:-unknown}"
  log "qBittorrent IP: ${qbit_ip:-unknown}"

  # Verify VPN is working
  if [ -z "$vpn_ip" ]; then
    alert "Could not determine VPN IP - VPN may be down!"
    return 1
  fi

  if [ -n "$host_ip" ] && [ "$host_ip" = "$vpn_ip" ]; then
    alert "VPN LEAK DETECTED! Host IP matches VPN IP: $host_ip"
    return 1
  fi

  # Check qBittorrent is using VPN
  if [ -n "$qbit_ip" ]; then
    if [ "$qbit_ip" = "$host_ip" ]; then
      alert "qBittorrent LEAK! Using host IP instead of VPN: $qbit_ip"
      return 1
    fi

    if [ "$qbit_ip" != "$vpn_ip" ]; then
      log "Warning: qBittorrent IP ($qbit_ip) differs from Gluetun VPN IP ($vpn_ip)"
      # This might be okay if using different endpoints
    fi
  fi

  log "VPN check passed - all traffic properly routed"
  return 0
}

# Single check mode
if [ "${1:-}" = "--once" ]; then
  if check_vpn; then
    exit 0
  else
    exit 1
  fi
fi

# Continuous monitoring mode
log "Starting VPN monitoring (interval: ${CHECK_INTERVAL}s)..."
log "Configuration: GLUETUN_API=$GLUETUN_API, QBIT_CONTAINER=$QBIT_CONTAINER"

while true; do
  if ! check_vpn; then
    log_error "VPN check failed!"
  fi
  echo "---"
  sleep "$CHECK_INTERVAL"
done
