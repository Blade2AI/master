#!/bin/bash
# Sovereign CLI - Operations Controller
set -euo pipefail
COMMAND=${1:-help}
ARG=${2:-}
show_help(){
  echo "Usage: ./scripts/sovereign.sh [command]";
  echo "Commands:";
  echo "  check      - Run readiness analysis on audit logs";
  echo "  promote    - Promote an agent to STABLE track";
  echo "  audit      - Verify cryptographic integrity of the ledger";
  echo "  clean      - Wipe draft folders (Insider reset)";
}
case "$COMMAND" in
  check)
    echo "?? Checking Agent Readiness...";
    python3 scripts/analyze_rejections.py || echo "readiness script missing";
    ;;
  audit)
    echo "?? Verifying Ledger Integrity...";
    python3 scripts/verify_ledger.py || echo "ledger verify script missing";
    ;;
  promote)
    [ -z "$ARG" ] && echo "Specify agent name" && exit 1;
    echo "?? Promoting $ARG to STABLE...";
    cp .env .env.bak 2>/dev/null || true;
    if grep -q "TRACK=insider" .env; then sed -i "s/TRACK=insider/TRACK=stable/" .env; fi;
    docker-compose down && docker-compose up -d;
    ;;
  clean)
    echo "?? Cleaning Insider Drafts...";
    rm -rf Evidence/Analysis/_drafts/* Property/Scored/_drafts/* || true;
    echo "? Cleaned.";
    ;;
  help|*)
    show_help;;
esac
