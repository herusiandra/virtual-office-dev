#!/usr/bin/env bash
set -euo pipefail

OFFICE_DIR="/home/safewatch/agent/office"
VO_DIR="$OFFICE_DIR/visual-office"
GATEWAY_PID="$VO_DIR/.gateway.pid"
SERVER_PID="$VO_DIR/.server.pid"

if [[ -f "$SERVER_PID" ]]; then
  PID=$(cat "$SERVER_PID")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Menghentikan Visual Office Web (PID: $PID)..."
    kill "$PID" 2>/dev/null || true
  fi
  rm -f "$SERVER_PID"
fi

if [[ -f "$GATEWAY_PID" ]]; then
  PID=$(cat "$GATEWAY_PID")
  if kill -0 "$PID" 2>/dev/null; then
    echo "[INFO] Menghentikan Gateway Adapter (PID: $PID)..."
    kill "$PID" 2>/dev/null || true
  fi
  rm -f "$GATEWAY_PID"
fi

echo "[SUCCESS] Visual Office 3D telah dihentikan."
