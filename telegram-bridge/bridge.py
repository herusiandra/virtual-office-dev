#!/usr/bin/env python3
"""
Telegram Bridge untuk Heru PM (Virtual Office)
Menjembatani pesan Telegram langsung ke sesi Antigravity Heru di Herdr (wX:p1).
"""

import os
import sys
import time
import json
import signal
import sqlite3
import logging
import subprocess
import urllib.request
import urllib.parse
from datetime import datetime

# Setup logging
LOG_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bridge.log")
logging.basicConfig(
    filename=LOG_FILE,
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s"
)
console = logging.StreamHandler()
console.setLevel(logging.INFO)
logging.getLogger("").addHandler(console)

# Load .env
ENV_FILE = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
CONFIG = {
    "TELEGRAM_BOT_TOKEN": "",
    "TELEGRAM_ALLOWED_USER": "",
    "HERDR_BIN": "/home/safewatch/.local/bin/herdr",
    "HERU_PANE": "wX:p1",
    "HERU_DIR": "/home/safewatch/agent/office/agent-main",
    "OFFICE_DIR": "/home/safewatch/agent/office",
    "DB_PATH": "/home/safewatch/.gemini/antigravity-cli/conversation_summaries.db",
    "BRAIN_DIR": "/home/safewatch/.gemini/antigravity-cli/brain",
}

if os.path.exists(ENV_FILE):
    with open(ENV_FILE) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#") and "=" in line:
                k, v = line.split("=", 1)
                CONFIG[k.strip()] = v.strip()

BOT_TOKEN = CONFIG["TELEGRAM_BOT_TOKEN"]
ALLOWED_USER_ID = int(CONFIG["TELEGRAM_ALLOWED_USER"])
HERDR_BIN = CONFIG["HERDR_BIN"]
HERU_PANE = CONFIG["HERU_PANE"]
HERU_DIR = CONFIG["HERU_DIR"]
OFFICE_DIR = CONFIG["OFFICE_DIR"]
DB_PATH = CONFIG["DB_PATH"]
BRAIN_DIR = CONFIG["BRAIN_DIR"]

if not BOT_TOKEN or not ALLOWED_USER_ID:
    logging.error("BOT_TOKEN atau ALLOWED_USER_ID belum dikonfigurasi di .env")
    sys.exit(1)

API_BASE = f"https://api.telegram.org/bot{BOT_TOKEN}"

# Helper Telegram API
def tg_request(method, data=None):
    url = f"{API_BASE}/{method}"
    try:
        if data is not None:
            payload = json.dumps(data).encode("utf-8")
            req = urllib.request.Request(url, data=payload, headers={"Content-Type": "application/json"})
        else:
            req = urllib.request.Request(url)
        with urllib.request.urlopen(req, timeout=35) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except Exception as e:
        logging.error(f"Telegram API error ({method}): {e}")
        return None

def send_message(chat_id, text, parse_mode=None):
    # Split text if longer than 4000 chars
    max_len = 3900
    if len(text) <= max_len:
        data = {"chat_id": chat_id, "text": text}
        if parse_mode:
            data["parse_mode"] = parse_mode
        res = tg_request("sendMessage", data)
        if not res and parse_mode:
            # Fallback tanpa markdown jika syntax error
            data.pop("parse_mode", None)
            res = tg_request("sendMessage", data)
        return res

    chunks = []
    lines = text.split("\n")
    current_chunk = ""
    for line in lines:
        if len(current_chunk) + len(line) + 1 > max_len:
            chunks.append(current_chunk)
            current_chunk = line + "\n"
        else:
            current_chunk += line + "\n"
    if current_chunk:
        chunks.append(current_chunk)

    last_res = None
    for chunk in chunks:
        data = {"chat_id": chat_id, "text": chunk}
        if parse_mode:
            data["parse_mode"] = parse_mode
        last_res = tg_request("sendMessage", data)
        if not last_res and parse_mode:
            data.pop("parse_mode", None)
            last_res = tg_request("sendMessage", data)
        time.sleep(0.3)
    return last_res

def send_chat_action(chat_id, action="typing"):
    tg_request("sendChatAction", {"chat_id": chat_id, "action": action})

# Herdr & Antigravity Helpers
def is_heru_running():
    try:
        res = subprocess.run([HERDR_BIN, "pane", "process-info", "--pane", HERU_PANE],
                             stdout=subprocess.PIPE, universal_newlines=True, timeout=5)
        pi = json.loads(res.stdout).get("result", {}).get("process_info", {})
        fg_procs = pi.get("foreground_processes", [])
        return any(p.get("name") == "agy" or "agy" in p.get("cmdline", "") for p in fg_procs)
    except Exception as e:
        logging.error(f"Error checking Heru process: {e}")
        return False

def get_heru_pane_status():
    try:
        res = subprocess.run([HERDR_BIN, "pane", "get", HERU_PANE],
                             stdout=subprocess.PIPE, universal_newlines=True, timeout=5)
        data = json.loads(res.stdout).get("result", {}).get("pane", {})
        return data.get("agent_status", "unknown")
    except Exception as e:
        return "unknown"

def start_heru_if_needed():
    if not is_heru_running():
        logging.info("Heru sedang idle di bash. Menyalakan sesi agy -c...")
        cmd = f"cd '{HERU_DIR}' && (agy -c || agy)"
        subprocess.run([HERDR_BIN, "pane", "run", HERU_PANE, cmd], timeout=5)
        time.sleep(3)

def send_text_to_heru(text):
    start_heru_if_needed()
    # Pastikan diakhiri newline
    cmd_text = text if text.endswith("\n") else text + "\n"
    subprocess.run([HERDR_BIN, "pane", "send-text", HERU_PANE, cmd_text], timeout=5)

def get_latest_conversation_id():
    try:
        conn = sqlite3.connect(DB_PATH)
        cur = conn.cursor()
        cur.execute("""
            SELECT conversation_id FROM conversation_summaries 
            WHERE workspace_uris LIKE '%agent-main%' 
            ORDER BY last_modified_time DESC LIMIT 1
        """)
        row = cur.fetchone()
        conn.close()
        if row:
            return row[0]
    except Exception as e:
        logging.error(f"Error getting conversation_id: {e}")
    return None

def get_transcript_path(conversation_id):
    if not conversation_id:
        return None
    p = os.path.join(BRAIN_DIR, conversation_id, ".system_generated", "logs", "transcript.jsonl")
    if os.path.exists(p):
        return p
    return None

def get_transcript_lines(path):
    if not path or not os.path.exists(path):
        return []
    try:
        with open(path, "r", encoding="utf-8") as f:
            return [json.loads(line) for line in f if line.strip()]
    except Exception as e:
        logging.error(f"Error reading transcript: {e}")
        return []

def get_active_project():
    p_file = os.path.join(OFFICE_DIR, "ACTIVE_PROJECT")
    if os.path.exists(p_file):
        with open(p_file) as f:
            return f.read().strip()
    return None

# Command Handlers
def handle_command(chat_id, text):
    cmd = text.split()[0].lower()
    if cmd in ["/start", "/help"]:
        msg = (
            "🤖 *Selamat datang di Jembatan Heru PM (Virtual Office)!*\n\n"
            "Anda terhubung langsung dengan **Heru**, Project Manager & Orkestrator tim agent di Herdr.\n\n"
            "*Perintah Khusus:*\n"
            "• `/status` — Cek status Heru, proyek aktif, dan terminal Herdr.\n"
            "• `/stop` — Interupsi darurat (buat file STOP di proyek aktif).\n"
            "• `/unstop` — Hapus file STOP untuk melanjutkan kembali.\n"
            "• `/clear` — Perintah compacting memori Heru.\n\n"
            "Ketikkan pesan apa saja langsung untuk berdiskusi, memberikan brief, atau menyetujui Gate (Gate 0, Gate A, Gate B)!"
        )
        send_message(chat_id, msg, parse_mode="Markdown")
        return True

    elif cmd == "/status":
        heru_alive = is_heru_running()
        pane_st = get_heru_pane_status()
        proj = get_active_project() or "Belum ditentukan"
        
        state_snippet = "Tidak ada"
        if proj and os.path.exists(os.path.join(proj, "STATE.md")):
            with open(os.path.join(proj, "STATE.md")) as sf:
                lines = [l.strip() for l in sf if l.strip()][:5]
                state_snippet = "\n".join(lines)
                
        stop_active = os.path.exists(os.path.join(proj, "STOP")) if proj else False

        msg = (
            "📊 *Status Virtual Office — Heru PM*\n\n"
            f"• *Proses Heru*: {'🟢 Aktif (agy)' if heru_alive else '🟡 Idle (bash shell)'}\n"
            f"• *Status Agent Herdr*: `{pane_st}`\n"
            f"• *Proyek Aktif*: `{proj}`\n"
            f"• *Status Interupsi STOP*: {'🔴 DARURAT AKTIF' if stop_active else '🟢 Normal (Tidak ada STOP)'}\n\n"
            f"*Cuplikan STATE.md:*\n```\n{state_snippet}\n```"
        )
        send_message(chat_id, msg, parse_mode="Markdown")
        return True

    elif cmd == "/stop":
        proj = get_active_project()
        if proj and os.path.isdir(proj):
            stop_file = os.path.join(proj, "STOP")
            with open(stop_file, "w") as f:
                f.write(f"STOP ordered from Telegram at {datetime.now().isoformat()}\n")
            send_message(chat_id, f"⛔ *Interupsi Darurat Dibuat!*\nFile `STOP` telah ditaruh di `{proj}`. Semua agent yang memegang akses server otomatis berhenti.")
        else:
            send_message(chat_id, "⚠️ Proyek aktif belum ditentukan di `ACTIVE_PROJECT`.")
        return True

    elif cmd == "/unstop":
        proj = get_active_project()
        if proj:
            stop_file = os.path.join(proj, "STOP")
            if os.path.exists(stop_file):
                os.remove(stop_file)
                send_message(chat_id, "✅ *File STOP telah dihapus.* Tim agent dapat melanjutkan pekerjaan.")
            else:
                send_message(chat_id, "ℹ️ Tidak ada file STOP yang aktif.")
        return True

    return False

# Main Interaction Loop (Forward to Heru & Wait for Reply)
def process_user_message(chat_id, user_text):
    if handle_command(chat_id, user_text):
        return

    logging.info(f"Pesan masuk dari Telegram: {user_text}")
    send_chat_action(chat_id, "typing")

    # 1. Deteksi percakapan saat ini dan jumlah step awal
    cid = get_latest_conversation_id()
    tpath = get_transcript_path(cid)
    initial_steps = get_transcript_lines(tpath)
    initial_count = len(initial_steps)
    initial_last_index = initial_steps[-1].get("step_index", -1) if initial_steps else -1

    # 2. Kirim pesan ke Heru di terminal Herdr
    send_text_to_heru(user_text)

    # 3. Tunggu respon Heru dengan polling transcript
    start_time = time.time()
    last_typing_time = time.time()
    max_wait = 180  # 3 menit batas tunggu

    logging.info(f"Menunggu jawaban Heru (cid: {cid}, initial_steps: {initial_count})...")

    while time.time() - start_time < max_wait:
        # Kirim typing indicator tiap 4 detik
        if time.time() - last_typing_time > 4:
            send_chat_action(chat_id, "typing")
            last_typing_time = time.time()

        time.sleep(1.5)

        # Cek apakah conversation_id berubah (misal Heru baru pertama kali jalan)
        current_cid = get_latest_conversation_id()
        if current_cid != cid:
            cid = current_cid
            tpath = get_transcript_path(cid)

        if not tpath or not os.path.exists(tpath):
            continue

        steps = get_transcript_lines(tpath)
        if len(steps) <= initial_count:
            continue

        # Cari step respon terbaru dari model
        new_steps = [s for s in steps if s.get("step_index", -1) > initial_last_index]
        model_responses = [s for s in new_steps if s.get("source") == "MODEL" and s.get("type") == "PLANNER_RESPONSE"]

        if not model_responses:
            continue

        latest_resp = model_responses[-1]
        
        # Periksa apakah model sudah selesai bicara (bukan sekadar sedang menjalankan tools)
        status = latest_resp.get("status")
        has_tools = bool(latest_resp.get("tool_calls"))
        content = latest_resp.get("content", "").strip()

        # Cek juga status pane di Herdr
        pane_st = get_heru_pane_status()

        if status == "DONE" and content and (not has_tools or pane_st == "done"):
            # Tunggu 1 detik agar streaming benar-benar tuntas
            time.sleep(1.0)
            logging.info(f"Jawaban Heru ditemukan ({len(content)} karakter). Mengirim ke Telegram...")
            send_message(chat_id, content, parse_mode="Markdown")
            return

    # Timeout fallback
    logging.warning("Waktu tunggu jawaban Heru habis (timeout).")
    send_message(chat_id, "⏳ *Heru masih memproses instruksi atau menjalankan operasi yang panjang.* Anda bisa mengetik `/status` untuk mengecek perkembangan terkini.")

# Polling Updates
def run_bridge():
    logging.info("Telegram Bridge untuk Heru PM dimulai...")
    offset = None
    
    # Simpan PID
    pid_file = os.path.join(os.path.dirname(os.path.abspath(__file__)), "bridge.pid")
    with open(pid_file, "w") as f:
        f.write(str(os.getpid()))

    # Notifikasi awal bahwa bot aktif
    send_message(ALLOWED_USER_ID, "🚀 *Jembatan Telegram Heru PM Aktif!*\nKetik `/status` atau langsung kirim pesan untuk berdiskusi dengan Heru.")

    while True:
        try:
            params = {"timeout": 25}
            if offset is not None:
                params["offset"] = offset

            updates = tg_request("getUpdates", params)
            if not updates or not updates.get("ok"):
                time.sleep(2)
                continue

            for item in updates.get("result", []):
                offset = item.get("update_id") + 1
                msg = item.get("message") or item.get("channel_post")
                if not msg:
                    continue

                user = msg.get("from", {})
                user_id = user.get("id")
                chat_id = msg.get("chat", {}).get("id")
                text = msg.get("text", "")

                # Verifikasi wewenang user
                if user_id != ALLOWED_USER_ID:
                    logging.warning(f"Akses ditolak dari ID: {user_id} (@{user.get('username')})")
                    tg_request("sendMessage", {
                        "chat_id": chat_id,
                        "text": "⛔ Akses ditolak. Bot ini hanya melayani pengelola Virtual Office yang diotorisasi."
                    })
                    continue

                if not text:
                    continue

                process_user_message(chat_id, text)

        except KeyboardInterrupt:
            logging.info("Bridge dihentikan oleh pengguna.")
            break
        except Exception as e:
            logging.error(f"Error di main loop: {e}")
            time.sleep(3)

    if os.path.exists(pid_file):
        os.remove(pid_file)

if __name__ == "__main__":
    run_bridge()
