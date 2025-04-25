#!/bin/sh

while true; do
  echo "⏱️ Checking forwarded port..."

  # Use environment variables with defaults
  QBIT_HOST="${QBIT_HOST:-http://localhost:8090}"
  QBIT_USER="${QBIT_USER:-admin}"
  QBIT_PASS="${QBIT_PASS:-adminadmin}"

  # Use jq to parse JSON and extract port value
  PORT=$(curl -s http://localhost:8000/v1/openvpn/portforwarded | jq -r '.port')
  echo "Forwarded port: $PORT"

  COOKIE=$(curl -s -i --data "username=$QBIT_USER&password=$QBIT_PASS" "$QBIT_HOST/api/v2/auth/login" | grep -i "set-cookie" | sed -n 's/Set-Cookie: \(SID=.*\);.*/\1/p')

  curl -s --cookie "$COOKIE" "$QBIT_HOST/api/v2/app/setPreferences" --data "json={\"listen_port\":$PORT}"
  echo "✅ qBittorrent port updated to $PORT"

  sleep 60  # Wait 60 seconds before next check
done