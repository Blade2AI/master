#!/usr/bin/env bash
set -euo pipefail

PORT="${TTYD_PORT:-7681}"
CERT="${TTYD_CERT:-.console/ttyd.crt}"
KEY="${TTYD_KEY:-.console/ttyd.key}"

mkdir -p .console
if [ ! -f "$CERT" ] || [ ! -f "$KEY" ]; then
  echo "TLS cert not found; generating self-signed cert..."
  openssl req -x509 -nodes -newkey rsa:2048 -keyout "$KEY" -out "$CERT" -subj "/CN=localhost" -days 365
fi

echo "Starting ttyd on https://localhost:$PORT (once, TLS)"
nohup ttyd \
  --port "$PORT" \
  --ssl --ssl-cert "$CERT" --ssl-key "$KEY" \
  --once \
  bash >/dev/null 2>.console/ttyd.log &
echo $! > .console/ttyd.pid
echo "ttyd started; PID $(cat .console/ttyd.pid). Log: .console/ttyd.log"
