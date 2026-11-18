#!/usr/bin/env bash
set -euo pipefail

OFFICE_DIR="/home/safewatch/agent/office"
VO_DIR="$OFFICE_DIR/visual-office"
SERVER_PID="$VO_DIR/.server.pid"

if [[ -f "$SERVER_PID" ]]; then
  PID=$(cat "$SERVER_PID")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[STATUS] Visual Office 3D BERJALAN di port 3000 (PID: $PID)"
    echo "• URL: http://192.168.220.71:3000"
    echo "• Token Akses: vensys123"
    echo "--- 10 Baris Log Server ---"
    tail -n 10 "$VO_DIR/server.log" 2>/dev/null || true
    exit 0
  fi
fi

echo "[STATUS] Visual Office 3D TIDAK BERJALAN (OFFLINE)"
