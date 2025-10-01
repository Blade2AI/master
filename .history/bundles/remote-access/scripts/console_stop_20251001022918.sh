#!/usr/bin/env bash
set -euo pipefail

if [ -f .console/ttyd.pid ]; then
  PID=$(cat .console/ttyd.pid)
  if kill -0 "$PID" 2>/dev/null; then
    echo "Stopping ttyd PID $PID..."
    kill "$PID" || true
  fi
  rm -f .console/ttyd.pid
else
  echo "No ttyd PID file; nothing to stop."
fi
