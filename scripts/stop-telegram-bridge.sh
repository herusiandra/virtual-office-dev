#!/usr/bin/env bash
set -euo pipefail

BRIDGE_DIR="/home/safewatch/agent/office/telegram-bridge"
PID_FILE="$BRIDGE_DIR/bridge.pid"

if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Menghentikan Telegram Bridge (PID: $PID)..."
    kill "$PID"
    rm -f "$PID_FILE"
    echo "[SUCCESS] Telegram Bridge telah dihentikan."
    exit 0
  fi
  rm -f "$PID_FILE"
fi

echo "[INFO] Telegram Bridge tidak sedang berjalan."
