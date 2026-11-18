#!/usr/bin/env bash
set -euo pipefail

BRIDGE_DIR="/home/safewatch/agent/office/telegram-bridge"
PID_FILE="$BRIDGE_DIR/bridge.pid"

if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[STATUS] Telegram Bridge BERJALAN (PID: $PID)"
    echo "--- 10 Baris Log Terakhir ---"
    tail -n 10 "$BRIDGE_DIR/bridge.log" 2>/dev/null || true
    exit 0
  fi
fi

echo "[STATUS] Telegram Bridge TIDAK BERJALAN (OFFLINE)"
