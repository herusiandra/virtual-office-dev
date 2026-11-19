#!/usr/bin/env bash
# ==============================================================================
# scripts/wake-agent.sh — Orkestrator Pengaktifan Agent via Herdr
# Pemakaian: ./scripts/wake-agent.sh <agent> <task_file> [project_path]
# Contoh   : ./scripts/wake-agent.sh naufal inbox/naufal/001-analisa.md projects/demo
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OFFICE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
HERDR_BIN="/home/safewatch/.local/bin/herdr"
AGY_BIN="/home/safewatch/.local/bin/agy"

TARGET_AGENT="${1:-}"
TASK_FILE="${2:-}"
PROJECT_PATH="${3:-}"

if [[ -z "$TARGET_AGENT" || -z "$TASK_FILE" ]]; then
  echo "Usage: $0 <heru|naufal|priyo|rajif|dhoni|denis> <task_file> [project_path]"
  echo "Alias:"
  echo "  heru   | main -> agent-main"
  echo "  naufal | ba   -> agent-sub-ba"
  echo "  priyo  | uiux -> agent-sub-uiux"
  echo "  rajif  | dev  -> agent-sub-dev"
  echo "  dhoni  | dev2 -> agent-sub-dev-2"
  echo "  denis  | qa   -> agent-sub-qa"
  exit 1
fi

# Normalisasi nama agent dan folder
case "$TARGET_AGENT" in
  heru|main)
    AGENT_KEY="heru"
    AGENT_DIR="$OFFICE_DIR/agent-main"
    FOLDER_NAME="agent-main"
    ;;
  naufal|ba)
    AGENT_KEY="naufal"
    AGENT_DIR="$OFFICE_DIR/agent-sub-ba"
    FOLDER_NAME="agent-sub-ba"
    ;;
  priyo|uiux)
    AGENT_KEY="priyo"
    AGENT_DIR="$OFFICE_DIR/agent-sub-uiux"
    FOLDER_NAME="agent-sub-uiux"
    ;;
  rajif|dev)
    AGENT_KEY="rajif"
    AGENT_DIR="$OFFICE_DIR/agent-sub-dev"
    FOLDER_NAME="agent-sub-dev"
    ;;
  dhoni|dev2)
    AGENT_KEY="dhoni"
    AGENT_DIR="$OFFICE_DIR/agent-sub-dev-2"
    FOLDER_NAME="agent-sub-dev-2"
    ;;
  denis|qa)
    AGENT_KEY="denis"
    AGENT_DIR="$OFFICE_DIR/agent-sub-qa"
    FOLDER_NAME="agent-sub-qa"
    ;;
  *)
    echo "[ERROR] Agent tidak dikenal: $TARGET_AGENT"
    exit 1
    ;;
esac

# Tentukan project path jika tidak disertakan
if [[ -z "$PROJECT_PATH" ]]; then
  if [[ -f "$OFFICE_DIR/ACTIVE_PROJECT" ]]; then
    PROJECT_PATH="$(cat "$OFFICE_DIR/ACTIVE_PROJECT" | tr -d '[:space:]')"
  fi
fi

# Verifikasi keberadaan file tugas
if [[ ! -f "$TASK_FILE" && -n "$PROJECT_PATH" && -f "$PROJECT_PATH/$TASK_FILE" ]]; then
  TASK_FILE="$PROJECT_PATH/$TASK_FILE"
fi

echo "[WAKE-AGENT] Mempersiapkan delegasi ke: $AGENT_KEY ($FOLDER_NAME)"
echo "[WAKE-AGENT] File Tugas : $TASK_FILE"
echo "[WAKE-AGENT] Proyek     : ${PROJECT_PATH:-'(Mengikuti ACTIVE_PROJECT)'}"

# Python helper untuk mencari pane di Herdr dan memeriksa apakah agy aktif
PYTHON_FIND_PANE=$(cat << 'PYEOF'
import sys, json, subprocess

folder_name = sys.argv[1]
agent_key = sys.argv[2]
herdr_bin = sys.argv[3]

try:
    res = subprocess.run([herdr_bin, 'pane', 'list'], stdout=subprocess.PIPE, universal_newlines=True, timeout=5)
    panes = json.loads(res.stdout).get('result', {}).get('panes', [])
    
    # Prioritas 1: Cocokkan CWD folder
    for p in panes:
        cwd = p.get('cwd', '')
        if folder_name in cwd:
            print(json.dumps({'found': True, 'pane_id': p.get('pane_id'), 'cwd': cwd, 'type': 'cwd'}))
            sys.exit(0)
            
    # Prioritas 2: Cocokkan Title atau agent_session
    for p in panes:
        title = (p.get('terminal_title') or '').lower()
        if agent_key in title or folder_name in title:
            print(json.dumps({'found': True, 'pane_id': p.get('pane_id'), 'cwd': p.get('cwd', ''), 'type': 'title'}))
            sys.exit(0)
            
    print(json.dumps({'found': False}))
except Exception as e:
    print(json.dumps({'found': False, 'error': str(e)}))
PYEOF
)

PANE_INFO=$(python3 -c "$PYTHON_FIND_PANE" "$FOLDER_NAME" "$AGENT_KEY" "$HERDR_BIN")
PANE_FOUND=$(echo "$PANE_INFO" | python3 -c "import sys, json; print(json.load(sys.stdin).get('found', False))")

if [[ "$PANE_FOUND" != "True" ]]; then
  echo "[INFO] Pane untuk $AGENT_KEY ($FOLDER_NAME) belum aktif di Herdr. Membuat workspace baru..."
  NEW_WS_RES=$("$HERDR_BIN" workspace create --cwd "$AGENT_DIR" --label "agent-$AGENT_KEY" --no-focus)
  PANE_ID=$(echo "$NEW_WS_RES" | python3 -c "import sys, json; print(json.load(sys.stdin).get('result', {}).get('root_pane', {}).get('pane_id', ''))")
  if [[ -z "$PANE_ID" ]]; then
    echo "[ERROR] Gagal membuat workspace/pane di Herdr secara otomatis."
    exit 1
  fi
  echo "[WAKE-AGENT] Workspace baru dibuat dengan Pane ID: $PANE_ID"
else
  PANE_ID=$(echo "$PANE_INFO" | python3 -c "import sys, json; print(json.load(sys.stdin).get('pane_id', ''))")
  echo "[WAKE-AGENT] Ditemukan Pane Herdr: $PANE_ID"
fi

# Periksa apakah agy sedang berjalan di pane tersebut
PYTHON_CHECK_AGY=$(cat << 'PYEOF'
import sys, json, subprocess

pane_id = sys.argv[1]
herdr_bin = sys.argv[2]

try:
    res = subprocess.run([herdr_bin, 'pane', 'process-info', '--pane', pane_id], stdout=subprocess.PIPE, universal_newlines=True, timeout=5)
    pi = json.loads(res.stdout).get('result', {}).get('process_info', {})
    fg_procs = pi.get('foreground_processes', [])
    is_agy = any(p.get('name') == 'agy' or 'agy' in p.get('cmdline', '') for p in fg_procs)
    print("RUNNING" if is_agy else "IDLE")
except Exception as e:
    print("UNKNOWN")
PYEOF
)

AGY_STATUS=$(python3 -c "$PYTHON_CHECK_AGY" "$PANE_ID" "$HERDR_BIN")
echo "[WAKE-AGENT] Status Proses di Pane $PANE_ID: $AGY_STATUS"

INSTRUCTION="Tugas baru masuk di $TASK_FILE. Pelajari file tersebut dan kerjakan sesuai peranmu. Setelah selesai, serahkan hasil ke inbox Heru, lalu jalankan /compact dan /exit untuk membebaskan memori RAM."

if [[ "$AGY_STATUS" == "RUNNING" ]]; then
  echo "[WAKE-AGENT] Mengirim instruksi langsung ke sesi agy yang sedang aktif..."
  "$HERDR_BIN" pane send-text "$PANE_ID" "$INSTRUCTION"$'\n'
else
  echo "[WAKE-AGENT] Shell di pane $PANE_ID sedang idle (On-Demand). Menyalakan agy -c dengan prompt tugas..."
  # Jika shell idle, jalankan agy -c -i dengan prompt (atau fallback ke agy -i jika riwayat belum ada)
  "$HERDR_BIN" pane run "$PANE_ID" "cd '$AGENT_DIR' && ($AGY_BIN -c -i \"$INSTRUCTION\" 2>/dev/null || $AGY_BIN -i \"$INSTRUCTION\")"
fi

echo "[WAKE-AGENT] Berhasil! Agent $AGENT_KEY telah dibangunkan dan menerima tugas."
