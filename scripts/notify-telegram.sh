#!/usr/bin/env bash
# ==============================================================================
# scripts/notify-telegram.sh — Kirim Pesan / Notifikasi ke Telegram
# Pemakaian: ./scripts/notify-telegram.sh "Pesan notifikasi..."
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$OFFICE_DIR/telegram-bridge/.env"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "[ERROR] File $ENV_FILE tidak ditemukan."
  exit 1
fi

TEXT="${1:-}"
if [[ -z "$TEXT" ]]; then
  echo "Usage: $0 \"<message>\""
  exit 1
fi

python3 -c '
import sys, os, json, urllib.request

env_file = sys.argv[1]
text = sys.argv[2]

env_vars = {}
with open(env_file) as f:
    for line in f:
        line = line.strip()
        if line and not line.startswith("#") and "=" in line:
            k, v = line.split("=", 1)
            env_vars[k.strip()] = v.strip().strip("\"'\''")

token = env_vars.get("TELEGRAM_BOT_TOKEN")
user_id = env_vars.get("TELEGRAM_ALLOWED_USER")

if not token or not user_id:
    sys.exit(1)

url = f"https://api.telegram.org/bot{token}/sendMessage"
data = json.dumps({"chat_id": user_id, "text": text, "parse_mode": "Markdown"}).encode("utf-8")
req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})

try:
    with urllib.request.urlopen(req, timeout=10) as resp:
        res = json.loads(resp.read().decode("utf-8"))
        if not res.get("ok"):
            # fallback plain text
            data2 = json.dumps({"chat_id": user_id, "text": text}).encode("utf-8")
            req2 = urllib.request.Request(url, data=data2, headers={"Content-Type": "application/json"})
            urllib.request.urlopen(req2, timeout=10)
except Exception as e:
    # silent fallback
    pass
' "$ENV_FILE" "$TEXT"
