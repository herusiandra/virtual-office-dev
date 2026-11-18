#!/usr/bin/env bash
set -euo pipefail

OFFICE_DIR="/home/safewatch/agent/office"
VO_DIR="$OFFICE_DIR/visual-office"
GATEWAY_PID="$VO_DIR/.gateway.pid"
SERVER_PID="$VO_DIR/.server.pid"

cd "$VO_DIR"

# Stop proses lama jika ada
"$OFFICE_DIR/scripts/stop-visual-office.sh" >/dev/null 2>&1 || true
sleep 1

export HOST="0.0.0.0"
export PORT="3000"
export STUDIO_ACCESS_TOKEN="vensys123"
export CLAW3D_GATEWAY_URL="ws://localhost:18789"
export CLAW3D_GATEWAY_ADAPTER_TYPE="demo"

echo "[INFO] Menyalakan Office Gateway Adapter (port 18789)..."
setsid node --env-file="$VO_DIR/.env" "$VO_DIR/server/office-gateway-adapter.js" </dev/null >> "$VO_DIR/gateway.log" 2>&1 &
echo $! > "$GATEWAY_PID"

echo "[INFO] Menyalakan Claw3D Visual Office Web di 0.0.0.0:3000..."
setsid node --env-file="$VO_DIR/.env" "$VO_DIR/server/index.js" --dev </dev/null >> "$VO_DIR/server.log" 2>&1 &
echo $! > "$SERVER_PID"

sleep 3
echo "[SUCCESS] Visual Office 3D berhasil dijalankan di 0.0.0.0:3000!"
echo "• Akses Browser : http://192.168.220.71:3000"
echo "• Token Akses   : vensys123"
