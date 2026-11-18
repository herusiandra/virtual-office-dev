#!/usr/bin/env bash
set -euo pipefail

BRIDGE_DIR="/home/safewatch/agent/office/telegram-bridge"
PID_FILE="$BRIDGE_DIR/bridge.pid"

if [[ -f "$PID_FILE" ]]; then
  PID=$(cat "$PID_FILE")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Telegram Bridge sudah berjalan dengan PID: $PID"
    exit 0
  else
    rm -f "$PID_FILE"
  fi
fi

echo "[INFO] Menyalakan Telegram Bridge untuk Heru PM..."
cd "$BRIDGE_DIR"
setsid python3 "$BRIDGE_DIR/bridge.py" </dev/null >> "$BRIDGE_DIR/bridge.log" 2>&1 &
NEW_PID=$!
echo "$NEW_PID" > "$PID_FILE"
sleep 1
echo "[SUCCESS] Telegram Bridge aktif. Log: $BRIDGE_DIR/bridge.log"
