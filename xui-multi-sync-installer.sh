#!/usr/bin/env bash
# XUI Multi-Server Sync - Installer & Manager
# Synchronizes traffic and expiry data across multiple x-ui/3x-ui panels
# Delta-based sync: accumulates traffic differences across all servers

set -euo pipefail

APP_DIR="/opt/xui-multi-sync"
ETC_DIR="/etc/xui-multi-sync"
VAR_DIR="/var/lib/xui-multi-sync"
BIN="/usr/local/bin/xui-multi-sync"
BINCMD="/usr/local/bin/xuisync"
CONF="$ETC_DIR/config.json"
SERVERS_CONF="$ETC_DIR/servers.json"
LANG_CONF="$ETC_DIR/language"
SSH_KEY="$ETC_DIR/id_ed25519"
SYNC_SCRIPT="$APP_DIR/sync.py"
LOG_FILE="/var/log/xui-multi-sync.log"
SERVICE_NAME="xui-multi-sync"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}.timer"

# Language support
LANG_CURRENT="en"
load_language() {
  if [[ -f "$LANG_CONF" ]]; then
    LANG_CURRENT=$(cat "$LANG_CONF")
  fi
}

# Colors
color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info() { color "36" "[•] $*"; }
ok() { color "32" "[✓] $*"; }
warn() { color "33" "[⚠] $*"; }
err() { color "31" "[✗] $*"; }

# Translations
msg() {
  local key="$1"
  case "$LANG_CURRENT" in
    fa)
      case "$key" in
        "need_root") echo "این اسکریپت باید با root اجرا شود." ;;
        "installing_deps") echo "نصب وابستگی‌ها..." ;;
        "deps_installed") echo "وابستگی‌ها نصب شدند." ;;
        "generating_key") echo "ایجاد کلید SSH..." ;;
        "key_generated") echo "کلید SSH ایجاد شد" ;;
        "sync_script_created") echo "اسکریپت همگام‌سازی ایجاد شد" ;;
        "config_created") echo "فایل پیکربندی اصلی ایجاد شد" ;;
        "servers_created") echo "فایل لیست سرورها ایجاد شد" ;;
        "systemd_created") echo "واحدهای systemd ایجاد شدند" ;;
        "timer_enabled") echo "تایمر فعال شد" ;;
        "timer_disabled") echo "تایمر غیرفعال شد" ;;
        "running_sync") echo "اجرای همگام‌سازی..." ;;
        "sync_done") echo "همگام‌سازی انجام شد" ;;
        "server_list") echo "لیست سرورها" ;;
        "no_servers_file") echo "فایل سرورها وجود ندارد" ;;
        "no_servers") echo "هیچ سروری تعریف نشده" ;;
        "add_server") echo "اضافه کردن سرور جدید" ;;
        "server_name") echo "نام سرور (مثلاً: Server-1)" ;;
        "server_added") echo "سرور اضافه شد" ;;
        "copy_ssh_key") echo "کپی کلید SSH به" ;;
        "system_status") echo "وضعیت سیستم" ;;
        "sync_interval") echo "بازه همگام‌سازی" ;;
        "server_count") echo "تعداد سرورها" ;;
        "timer_active") echo "تایمر: فعال ✓" ;;
        "timer_inactive") echo "تایمر: غیرفعال ✗" ;;
        "recent_logs") echo "آخرین اجراها:" ;;
        "exit") echo "خروج..." ;;
        "menu_title") echo "مدیریت همگام‌سازی چند-سرور" ;;
        "menu_1") echo "نمایش وضعیت سیستم" ;;
        "menu_2") echo "لیست سرورها" ;;
        "menu_3") echo "اضافه کردن سرور" ;;
        "menu_4") echo "حذف سرور" ;;
        "menu_5") echo "تغییر بازه زمانی" ;;
        "menu_6") echo "فعال/غیرفعال کردن تایمر خودکار" ;;
        "menu_7") echo "اجرای دستی همگام‌سازی (الان)" ;;
        "menu_8") echo "نمایش لاگ‌ها" ;;
        "menu_9") echo "تغییر زبان" ;;
        "menu_u") echo "حذف سیستم" ;;
        "menu_update") echo "بروزرسانی" ;;
        "menu_0") echo "خروج" ;;
        "choose_lang") echo "انتخاب زبان / Choose Language" ;;
        "install_complete") echo "نصب با موفقیت انجام شد!" ;;
        "master_server") echo "این سرور اصلی (Master) است" ;;
        "downloading") echo "در حال دانلود..." ;;
        "uninstalling") echo "در حال حذف سیستم..." ;;
        *) echo "$key" ;;
      esac
      ;;
    *)
      case "$key" in
        "need_root") echo "This script must be run as root." ;;
        "installing_deps") echo "Installing dependencies..." ;;
        "deps_installed") echo "Dependencies installed." ;;
        "generating_key") echo "Generating SSH key..." ;;
        "key_generated") echo "SSH key generated" ;;
        "sync_script_created") echo "Sync script created" ;;
        "config_created") echo "Main configuration file created" ;;
        "servers_created") echo "Servers list file created" ;;
        "systemd_created") echo "Systemd units created" ;;
        "timer_enabled") echo "Timer enabled" ;;
        "timer_disabled") echo "Timer disabled" ;;
        "running_sync") echo "Running synchronization..." ;;
        "sync_done") echo "Synchronization completed" ;;
        "server_list") echo "Server List" ;;
        "no_servers_file") echo "Servers file does not exist" ;;
        "no_servers") echo "No servers defined" ;;
        "add_server") echo "Add New Server" ;;
        "server_name") echo "Server name (e.g., Server-1)" ;;
        "server_added") echo "Server added" ;;
        "copy_ssh_key") echo "Copy SSH key to" ;;
        "system_status") echo "System Status" ;;
        "sync_interval") echo "Sync interval" ;;
        "server_count") echo "Server count" ;;
        "timer_active") echo "Timer: Active ✓" ;;
        "timer_inactive") echo "Timer: Inactive ✗" ;;
        "recent_logs") echo "Recent executions:" ;;
        "exit") echo "Exiting..." ;;
        "menu_title") echo "Multi-Server Sync Manager" ;;
        "menu_1") echo "Show System Status" ;;
        "menu_2") echo "List Servers" ;;
        "menu_3") echo "Add Server" ;;
        "menu_4") echo "Remove Server" ;;
        "menu_5") echo "Change Sync Interval" ;;
        "menu_6") echo "Enable/Disable Auto Timer" ;;
        "menu_7") echo "Manual Sync (Now)" ;;
        "menu_8") echo "Show Logs" ;;
        "menu_9") echo "Change Language" ;;
        "menu_u") echo "Uninstall" ;;
        "menu_update") echo "Update" ;;
        "menu_0") echo "Exit" ;;
        "choose_lang") echo "انتخاب زبان / Choose Language" ;;
        "install_complete") echo "Installation completed successfully!" ;;
        "master_server") echo "This is the Master Server" ;;
        "downloading") echo "Downloading..." ;;
        "uninstalling") echo "Uninstalling system..." ;;
        *) echo "$key" ;;
      esac
      ;;
  esac
}

choose_language() {
  clear
  echo "╔═══════════════════════════════════════╗"
  echo "║  $(msg choose_lang)  ║"
  echo "╚═══════════════════════════════════════╝"
  echo ""
  echo "1) English"
  echo "2) فارسی (Persian)"
  echo ""
  read -r -p "Select / انتخاب [1-2]: " lang_choice
  
  case "$lang_choice" in
    1) LANG_CURRENT="en" ;;
    2) LANG_CURRENT="fa" ;;
    *) LANG_CURRENT="en" ;;
  esac
  
  mkdir -p "$ETC_DIR"
  echo "$LANG_CURRENT" > "$LANG_CONF"
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "$(msg need_root)"
    exit 1
  fi
}

install_deps() {
  info "$(msg installing_deps)"
  apt-get update -qq >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get install -y python3 sqlite3 openssh-client jq inotify-tools >/dev/null 2>&1
  ok "$(msg deps_installed)"
}

detect_local_db() {
  local candidates=(
    "/etc/x-ui/x-ui.db"
    "/usr/local/x-ui/x-ui.db"
    "/var/lib/x-ui/x-ui.db"
    "/opt/x-ui/x-ui.db"
    "/etc/3x-ui/x-ui.db"
  )
  for p in "${candidates[@]}"; do
    [[ -f "$p" ]] && echo "$p" && return 0
  done
  echo ""
}

detect_local_service() {
  local candidates=("x-ui" "xui" "3x-ui" "xray-ui")
  for s in "${candidates[@]}"; do
    if systemctl list-unit-files 2>/dev/null | grep -qx "${s}.service"; then
      echo "$s" && return 0
    fi
  done
  echo ""
}

write_sync_script() {
  mkdir -p "$APP_DIR" "$ETC_DIR" "$VAR_DIR"
  
  cat >"$SYNC_SCRIPT" <<'PYSCRIPT'
#!/usr/bin/env python3
"""
XUI Multi-Server Sync - Delta-Based Synchronization (v2)

Master is the single source of truth:
 - expiry_time, total, enable  → always from master
 - up / down                   → master_current + sum(remote_deltas)
 - Negative master delta       → force-reset all remotes to master values
 - New client on master        → full inbound config pushed to all remotes
"""

import json
import os
import sys
import sqlite3
import subprocess
import time
import threading
from typing import Dict, List, Tuple
from datetime import datetime

CONF_FILE    = "/etc/xui-multi-sync/config.json"
SERVERS_FILE = "/etc/xui-multi-sync/servers.json"
STATE_FILE   = "/var/lib/xui-multi-sync/state.json"
LOG_FILE     = "/var/log/xui-multi-sync.log"

# ── Logger ────────────────────────────────────────────────────────────────────

class Logger:
    _RST    = "\033[0m"
    _COLORS = {
        "INFO":    "\033[36m",
        "WARN":    "\033[33m",
        "ERROR":   "\033[31m",
        "SUCCESS": "\033[32m",
        "NEW":     "\033[1;32m",
        "RESET":   "\033[1;35m",
        "TRAFFIC": "\033[34m",
        "CHANGE":  "\033[1;33m",
    }
    _ICONS = {
        "INFO": "•", "WARN": "⚠", "ERROR": "✗", "SUCCESS": "✓",
        "NEW": "+", "RESET": "↺", "TRAFFIC": "↕", "CHANGE": "~",
    }

    def __init__(self, log_file: str):
        self.log_file  = log_file
        self._lock     = threading.Lock()
        self._err_list: List[str] = []

    def _tty(self) -> bool:
        return hasattr(sys.stdout, "isatty") and sys.stdout.isatty()

    def log(self, level: str, msg: str):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        icon  = self._ICONS.get(level, "•")
        plain = f"[{timestamp}] [{level}] {icon} {msg}"
        line  = f"{self._COLORS.get(level,'')}{plain}{self._RST}" if self._tty() else plain
        with self._lock:
            print(line, flush=True)
            if level == "ERROR":
                self._err_list.append(msg)
            try:
                with open(self.log_file, "a", encoding="utf-8") as f:
                    f.write(plain + "\n")
            except Exception:
                pass

    def info(self, msg):       self.log("INFO",    msg)
    def warn(self, msg):       self.log("WARN",    msg)
    def error(self, msg):      self.log("ERROR",   msg)
    def success(self, msg):    self.log("SUCCESS", msg)
    def new_client(self, msg): self.log("NEW",     msg)
    def reset_ev(self, msg):   self.log("RESET",   msg)
    def traffic(self, msg):    self.log("TRAFFIC", msg)
    def change(self, msg):     self.log("CHANGE",  msg)

    @property
    def error_count(self) -> int:
        return len(self._err_list)

logger = Logger(LOG_FILE)

def fmt_bytes(n: int) -> str:
    """Format byte count as human-readable string."""
    n = abs(int(n or 0))
    if n < 1024:        return f"{n} B"
    if n < 1024 ** 2:   return f"{n / 1024:.1f} KB"
    if n < 1024 ** 3:   return f"{n / 1024 ** 2:.1f} MB"
    return f"{n / 1024 ** 3:.2f} GB"

# ── JSON helpers ──────────────────────────────────────────────────────────────

def load_json(path):
    if not os.path.exists(path):
        return {}
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def save_json(path, data):
    tmp = path + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
    os.replace(tmp, path)

# ── SSH helper ────────────────────────────────────────────────────────────────

def run_ssh(server, command, timeout=45):
    cmd = [
        "ssh",
        "-i", server.get("ssh_key", "/etc/xui-multi-sync/id_ed25519"),
        "-p", str(server.get("port", 22)),
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "ConnectTimeout=10",
        f"{server.get('user','root')}@{server['host']}",
        command,
    ]
    r = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       timeout=timeout, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"SSH failed to {server['host']}: {r.stderr.strip()}")
    return r.stdout


def run_ssh_script(server: dict, python_script: str, timeout: int = 60) -> str:
    """Pipe a Python script to 'python3 -' on the remote via stdin.
    Avoids ARG_MAX limit; safe for any payload size."""
    cmd = [
        "ssh",
        "-i", server.get("ssh_key", "/etc/xui-multi-sync/id_ed25519"),
        "-p", str(server.get("port", 22)),
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "ConnectTimeout=10",
        f"{server.get('user','root')}@{server['host']}",
        "python3 -",
    ]
    r = subprocess.run(cmd, input=python_script,
                       stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       timeout=timeout, text=True)
    if r.returncode != 0:
        raise RuntimeError(f"SSH failed to {server['host']}: {r.stderr.strip()}")
    return r.stdout

# ── Fetch ─────────────────────────────────────────────────────────────────────

def fetch_master(db_path: str) -> Tuple[List[dict], List[dict]]:
    """
    Returns (stats_rows, inbound_rows).
    stats_rows  : [{email, up, down, expiry_time, total, enable, inbound_id}, ...]
    inbound_rows: [{id, tag, protocol, settings_json}, ...]
    """
    con = sqlite3.connect(db_path, timeout=10)
    con.row_factory = sqlite3.Row

    cur = con.cursor()
    cur.execute("""
        SELECT email, up, down, expiry_time, total, enable, inbound_id
        FROM client_traffics
    """)
    stats = [dict(r) for r in cur.fetchall()]
    for row in stats:
        for k in ("up","down","expiry_time","total","enable","inbound_id"):
            row[k] = int(row[k] or 0)

    cur.execute("SELECT id, user_id, up, down, total, remark, enable, expiry_time, listen, port, protocol, settings, stream_settings, tag, sniffing FROM inbounds")
    inbounds = [{
        "id":              r["id"],
        "user_id":         r["user_id"],
        "up":              int(r["up"] or 0),
        "down":            int(r["down"] or 0),
        "total":           int(r["total"] or 0),
        "remark":          r["remark"],
        "enable":          int(r["enable"] or 1),
        "expiry_time":     int(r["expiry_time"] or 0),
        "listen":          r["listen"] or "",
        "port":            int(r["port"] or 0),
        "protocol":        r["protocol"],
        "settings":        r["settings"],
        "stream_settings": r["stream_settings"],
        "tag":             r["tag"],
        "sniffing":        r["sniffing"],
    } for r in cur.fetchall()]
    con.close()

    logger.success(f"Master: {len(stats)} clients, {len(inbounds)} inbounds")
    return stats, inbounds


def fetch_remote_stats(server: dict) -> List[dict]:
    """Fetch only client_traffics from a remote server."""
    db_path = server.get("db_path", "/etc/x-ui/x-ui.db")
    logger.info(f"Fetching stats from {server['name']} ({server['host']})...")

    reader = f"""import sqlite3, json, sys
try:
    con = sqlite3.connect('{db_path}', timeout=30)
    con.execute('PRAGMA journal_mode=WAL')
    con.execute('PRAGMA busy_timeout=30000')
    cur = con.cursor()
    cur.execute('SELECT email, up, down, inbound_id FROM client_traffics')
    rows = [{{"email":r[0],"up":int(r[1] or 0),"down":int(r[2] or 0),"inbound_id":int(r[3] or 0)}} for r in cur.fetchall()]
    con.close()
    print(json.dumps(rows))
except Exception as e:
    print(json.dumps({{"error":str(e)}}), file=sys.stderr)
    sys.exit(1)
"""
    out = run_ssh_script(server, reader)
    data = json.loads(out)
    logger.success(f"{server['name']}: {len(data)} clients")
    return data

# ── Delta & merge ─────────────────────────────────────────────────────────────

def detect_resets(master_stats: List[dict], master_snap: dict) -> set:
    """
    Return set of emails where master traffic went DOWN compared to last snapshot.
    These are intentional resets (admin zeroed the traffic) → force-reset on remotes.
    """
    resets = set()
    for row in master_stats:
        email = row["email"]
        if email not in master_snap:
            continue
        prev = master_snap[email]
        if row["up"] < prev.get("up", 0) or row["down"] < prev.get("down", 0):
            resets.add(email)
            logger.warn(f"  Reset detected on master for {email} — will overwrite remotes")
    return resets


def calculate_remote_deltas(
    remote_data: Dict[str, List[dict]],
    state_servers: dict
) -> Dict[str, int]:
    """
    For each remote server, compute per-email traffic delta since last snapshot.
    Returns: {email: {"delta_up": X, "delta_down": Y}}
    Only processes remotes (master is excluded intentionally).
    """
    totals: Dict[str, dict] = {}

    for server_name, rows in remote_data.items():
        snap = state_servers.get(server_name, {})
        for row in rows:
            email = row["email"]
            # If this email has no prior snapshot on this server, it's either
            # a brand-new client or a new inbound just added. Treat delta as 0
            # so we don't add the entire accumulated traffic to master.
            if email not in snap:
                continue
            prev_up   = snap[email].get("up",   0)
            prev_down = snap[email].get("down", 0)
            d_up   = max(0, row["up"]   - prev_up)
            d_down = max(0, row["down"] - prev_down)
            if d_up or d_down:
                if email not in totals:
                    totals[email] = {"delta_up": 0, "delta_down": 0}
                totals[email]["delta_up"]   += d_up
                totals[email]["delta_down"] += d_down

    if totals:
        logger.info(f"  Remote deltas found for {len(totals)} clients")
    return totals


def build_merged(
    master_stats: List[dict],
    remote_deltas: Dict[str, dict],
    resets: set
) -> Dict[str, dict]:
    """
    Build the final merged dataset.

    Rules:
      - Base = master current values (expiry_time, total, enable always from master)
      - up/down = master_current + remote_deltas  (unless email in resets)
      - If email in resets → use master values as-is (delta ignored)
    """
    merged = {}
    for row in master_stats:
        email = row["email"]
        merged[email] = {
            "email":       email,
            "up":          row["up"],
            "down":        row["down"],
            "expiry_time": row["expiry_time"],
            "total":       row["total"],
            "enable":      row["enable"],
            "inbound_id":  row["inbound_id"],
        }

    # Add remote deltas (skip emails that were reset on master)
    for email, delta in remote_deltas.items():
        if email in resets:
            logger.info(f"  {email}: skipping remote delta (master reset)")
            continue
        if email in merged:
            merged[email]["up"]   += delta["delta_up"]
            merged[email]["down"] += delta["delta_down"]
        # Clients that exist on remote but NOT on master are ignored;
        # master is the only authority for which clients exist.

    logger.success(f"Merged {len(merged)} clients")
    return merged

# ── New-client inbound sync ───────────────────────────────────────────────────

def find_client_in_inbounds(email: str, inbounds: List[dict]):
    """
    Search all inbounds on master for a client entry matching email.
    Returns (inbound_row, client_json_obj) or (None, None).
    """
    for ib in inbounds:
        try:
            settings = json.loads(ib["settings"] or "{}")
            for client in settings.get("clients", []):
                if client.get("email") == email:
                    return ib, client
        except Exception:
            continue
    return None, None


def push_new_clients_to_remote(server: dict, new_clients: List[dict],
                               master_inbounds: List[dict], merged: Dict[str, dict]):
    """
    For each new client:
      1. Find their inbound on master (by inbound_id → tag).
      2. Find matching inbound on remote (by tag).
      3. Append client JSON to remote inbound settings.
      4. INSERT row into client_traffics on remote.
    All done in a single SSH call.
    """
    if not new_clients:
        return

    db_path      = server.get("db_path", "/etc/x-ui/x-ui.db")
    service_name = server.get("service_name", "x-ui")

    # Build a tag→inbound map for master
    master_ib_by_id = {ib["id"]: ib for ib in master_inbounds}

    # Prepare payload: list of {tag, client_obj, stats}
    payload = []
    for email in new_clients:
        m = merged[email]
        ib_id = m.get("inbound_id", 0)
        master_ib = master_ib_by_id.get(ib_id)
        if not master_ib:
            logger.warn(f"  New client {email}: inbound id={ib_id} not found on master, skip")
            continue
        _, client_obj = find_client_in_inbounds(email, [master_ib])
        if not client_obj:
            logger.warn(f"  New client {email}: not found in inbound settings, skip")
            continue
        payload.append({
            "tag":          master_ib["tag"],
            "client":       client_obj,
            "email":        email,
            "up":           m["up"],
            "down":         m["down"],
            "expiry_time":  m["expiry_time"],
            "total":        m["total"],
            "enable":       m["enable"],
            "inbound_full": master_ib,
        })

    if not payload:
        return

    import base64 as _b64
    payload_b64 = _b64.b64encode(json.dumps(payload).encode()).decode()
    logger.info(f"  Pushing {len(payload)} new client(s) to {server['name']}...")

    push_script = f"""import sqlite3, json, sys, time, os, base64

db_path = '{db_path}'
service = '{service_name}'
payload = json.loads(base64.b64decode('{payload_b64}').decode())

def db_connect(path, tries=8):
    for _ in range(tries):
        try:
            con = sqlite3.connect(path, timeout=10)
            con.execute('PRAGMA journal_mode=WAL')
            con.execute('PRAGMA busy_timeout=10000')
            return con
        except Exception as e:
            if 'locked' in str(e).lower():
                time.sleep(1)
            else:
                raise
    raise RuntimeError('DB locked after retries')

results = []
for item in payload:
    tag     = item['tag']
    client  = item['client']
    email   = item['email']
    stats   = {{k: item[k] for k in ('up','down','expiry_time','total','enable')}}
    try:
        con = db_connect(db_path)
        cur = con.cursor()

        # Find inbound by tag
        cur.execute('SELECT id, settings FROM inbounds WHERE tag=?', (tag,))
        row = cur.fetchone()
        if not row:
            # Inbound doesn't exist on remote yet — insert the full inbound row
            ib_data = item.get('inbound_full')
            if not ib_data:
                con.close()
                results.append({{'email': email, 'status': 'no_inbound', 'tag': tag}})
                continue
            cur.execute('''
                INSERT INTO inbounds
                (user_id, up, down, total, remark, enable, expiry_time, listen,
                 port, protocol, settings, stream_settings, tag, sniffing)
                VALUES (?,0,0,0,?,?,0,?,?,?,?,?,?,?)
            ''', (
                ib_data.get('user_id', 0),
                ib_data.get('remark', ''),
                int(ib_data.get('enable', 1)),
                ib_data.get('listen', ''),
                int(ib_data.get('port', 0)),
                ib_data.get('protocol', ''),
                ib_data.get('settings', '{{}}'),
                ib_data.get('stream_settings', '{{}}'),
                ib_data.get('tag', ''),
                ib_data.get('sniffing', '{{}}'),
            ))
            ib_id = cur.lastrowid
            # settings was already inserted with all clients from master
            # so we just need the traffic row
            cur.execute('''
                INSERT OR IGNORE INTO client_traffics
                (inbound_id, enable, email, up, down, expiry_time, total)
                VALUES (?,?,?,?,?,?,?)
            ''', (ib_id, stats['enable'], email,
                  stats['up'], stats['down'], stats['expiry_time'], stats['total']))
            con.commit()
            con.close()
            results.append({{'email': email, 'status': 'inbound_created'}})
            continue

        ib_id, settings_raw = row
        settings = json.loads(settings_raw or '{{}}')
        clients_list = settings.get('clients', [])

        # Skip if already exists in settings, but still ensure traffic row exists
        if any(c.get('email') == email for c in clients_list):
            cur.execute('''
                INSERT OR IGNORE INTO client_traffics
                (inbound_id, enable, email, up, down, expiry_time, total)
                VALUES (?,?,?,?,?,?,?)
            ''', (ib_id, stats['enable'], email,
                  stats['up'], stats['down'], stats['expiry_time'], stats['total']))
            con.commit()
            con.close()
            results.append({{'email': email, 'status': 'traffic_added'}})
            continue

        # Append client
        clients_list.append(client)
        settings['clients'] = clients_list
        new_settings = json.dumps(settings, ensure_ascii=False)

        cur.execute('UPDATE inbounds SET settings=? WHERE id=?', (new_settings, ib_id))

        # Insert traffic row — use the REMOTE's inbound_id (ib_id), not master's
        cur.execute('''
            INSERT OR IGNORE INTO client_traffics
            (inbound_id, enable, email, up, down, expiry_time, total)
            VALUES (?,?,?,?,?,?,?)
        ''', (ib_id, stats['enable'], email,
              stats['up'], stats['down'], stats['expiry_time'], stats['total']))

        con.commit()
        con.close()
        results.append({{'email': email, 'status': 'ok'}})

    except Exception as e:
        results.append({{'email': email, 'status': 'error', 'msg': str(e)}})

print(json.dumps(results))
"""

    out = run_ssh_script(server, push_script, timeout=60)
    try:
        results = json.loads(out)
        for r in results:
            if r["status"] == "ok":
                logger.success(f"  ✓ New client {r['email']} added to {server['name']}")
            elif r["status"] == "already_exists":
                logger.info(f"  {r['email']} already on {server['name']}")
            else:
                logger.warn(f"  {r['email']} on {server['name']}: {r['status']} {r.get('msg','')}")
    except Exception:
        logger.warn(f"  Could not parse push results from {server['name']}: {out[:200]}")

# ── Apply merged stats ────────────────────────────────────────────────────────

def _write_db(con, merged: Dict[str, dict]):
    """Execute all UPDATE statements inside a single transaction."""
    cur = con.cursor()
    cur.execute("BEGIN")
    for data in merged.values():
        cur.execute("""
            UPDATE client_traffics
            SET up=?, down=?, expiry_time=?, total=?, enable=?
            WHERE email=?
        """, (data["up"], data["down"], data["expiry_time"],
              data["total"], data["enable"], data["email"]))
    con.commit()


def apply_to_master(db_path: str, service_name: str, merged: Dict[str, dict]):
    logger.info("Applying merged stats to master...")
    for attempt in range(12):
        try:
            con = sqlite3.connect(db_path, timeout=30)
            con.execute("PRAGMA journal_mode=WAL")
            con.execute("PRAGMA busy_timeout=30000")
            _write_db(con, merged)
            con.close()
            logger.success("✓ Master updated")
            return
        except Exception as e:
            if "locked" in str(e).lower() or "busy" in str(e).lower():
                time.sleep(2)
                continue
            raise
    raise RuntimeError("Master DB still locked after retries — did not write")


def apply_to_remote(server: dict, merged: Dict[str, dict]):
    """Send merged stats to remote via a single SSH call (stdin pipe)."""
    logger.info(f"Applying merged stats to {server['name']}...")

    db_path      = server.get("db_path", "/etc/x-ui/x-ui.db")
    service_name = server.get("service_name", "x-ui")

    import base64 as _b64
    rows_b64 = _b64.b64encode(json.dumps(list(merged.values())).encode()).decode()

    update_script = f"""import sqlite3, json, sys, time, base64

db_path = '{db_path}'
rows    = json.loads(base64.b64decode('{rows_b64}').decode())

def try_write(db_path, rows, tries=12):
    for i in range(tries):
        try:
            con = sqlite3.connect(db_path, timeout=30)
            con.execute('PRAGMA journal_mode=WAL')
            con.execute('PRAGMA busy_timeout=30000')
            cur = con.cursor()
            cur.execute('BEGIN')
            for d in rows:
                cur.execute(
                    'UPDATE client_traffics SET up=?,down=?,expiry_time=?,total=?,enable=? WHERE email=?',
                    (d['up'], d['down'], d['expiry_time'], d['total'], d['enable'], d['email'])
                )
            con.commit()
            con.close()
            return True
        except Exception as e:
            if 'locked' in str(e).lower() or 'busy' in str(e).lower():
                time.sleep(2)
                continue
            print(f'ERROR: {{e}}', file=sys.stderr)
            sys.exit(1)
    print('ERROR: DB still locked after retries', file=sys.stderr)
    sys.exit(1)

try_write(db_path, rows)
print('SUCCESS')
"""

    out = run_ssh_script(server, update_script, timeout=90)
    if "SUCCESS" in out:
        logger.success(f"✓ {server['name']} stats updated")
    else:
        raise RuntimeError(f"Stats update failed on {server['name']}: {out[:200]}")

# ── State ─────────────────────────────────────────────────────────────────────

def save_state(merged: Dict[str, dict], remote_data: Dict[str, List[dict]]):
    """
    Save post-sync snapshot so next run calculates correct deltas.

    master snapshot  → merged values  (what was actually written)
    remote snapshots → current raw values from remotes (before our write;
                       after our write they reflect merged, which equals
                       master — so next delta starts from the right base)
    """
    state = {"timestamp": datetime.now().isoformat(), "servers": {}}

    # Master: save merged (= what we wrote to master)
    state["servers"]["master"] = {
        row["email"]: {
            "up":          row["up"],
            "down":        row["down"],
            "expiry_time": row["expiry_time"],
            "total":       row["total"],
            "enable":      row["enable"],
        }
        for row in merged.values()
    }

    # Remotes: save merged values too (they now equal master after apply)
    for server_name in remote_data:
        state["servers"][server_name] = state["servers"]["master"].copy()

    save_json(STATE_FILE, state)
    logger.info("State snapshot saved")

# ── Main ──────────────────────────────────────────────────────────────────────

def sync_all():
    logger.info("═" * 60)
    logger.info("XUI Multi-Server Delta-Based Sync v2")
    logger.info("═" * 60)

    try:
        config  = load_json(CONF_FILE)
        servers = load_json(SERVERS_FILE).get("servers", [])
        state   = load_json(STATE_FILE)

        local_db      = config.get("local_db_path", "")
        local_service = config.get("local_service_name", "x-ui")

        if not local_db or not os.path.exists(local_db):
            logger.error("Master DB not found: " + local_db)
            sys.exit(1)

        # ── 1. Fetch master ──────────────────────────────────────────────────
        master_stats, master_inbounds = fetch_master(local_db)
        master_emails = {r["email"] for r in master_stats}

        # ── 2. Fetch remotes in parallel ─────────────────────────────────────
        remote_data: Dict[str, List[dict]] = {}
        errors: Dict[str, str] = {}
        lock = threading.Lock()

        def fetch_one(srv):
            try:
                rows = fetch_remote_stats(srv)
                with lock:
                    remote_data[srv["name"]] = rows
            except Exception as e:
                with lock:
                    errors[srv["name"]] = str(e)
                logger.error(f"Fetch failed {srv['name']}: {e}")

        threads = [threading.Thread(target=fetch_one, args=(s,), daemon=True) for s in servers]
        for t in threads: t.start()
        for t in threads: t.join()

        if not remote_data:
            logger.warn("No remote servers reachable — nothing to sync")
            return

        # ── 3. First-sync detection ───────────────────────────────────────────
        is_first_sync = not state.get("servers")
        if is_first_sync:
            logger.warn("═" * 40)
            logger.warn("FIRST SYNC — establishing baseline snapshot.")
            logger.warn("No delta accumulation this round.")
            logger.warn("═" * 40)

        # ── 4. Detect master resets ───────────────────────────────────────────
        master_snap = state.get("servers", {}).get("master", {})
        if not is_first_sync:
            resets = detect_resets(master_stats, master_snap)
            if resets:
                logger.info("─" * 50)
                for email in sorted(resets):
                    logger.reset_ev(
                        f"  [RESET] {email} — traffic zeroed on master "
                        f"→ will force-reset all remotes"
                    )
        else:
            resets = set()

        # ── 5. Calculate remote deltas ────────────────────────────────────────
        if not is_first_sync:
            logger.info("─" * 50)
            logger.info("Calculating remote deltas...")
            remote_deltas = calculate_remote_deltas(remote_data, state.get("servers", {}))
            if remote_deltas:
                for email, d in sorted(remote_deltas.items()):
                    if d["delta_up"] or d["delta_down"]:
                        logger.traffic(
                            f"  [DELTA] {email} — "
                            f"+{fmt_bytes(d['delta_up'])} up  "
                            f"+{fmt_bytes(d['delta_down'])} down"
                        )
        else:
            remote_deltas = {}

        # ── 6. Build merged dataset ───────────────────────────────────────────
        logger.info("─" * 50)
        merged = build_merged(master_stats, remote_deltas, resets)

        # ── Detailed per-client report ────────────────────────────────────────
        logger.info("─" * 50)
        logger.info("📊 CLIENT REPORT:")
        new_count = reset_count = delta_count = 0
        for email, row in sorted(merged.items()):
            if email not in master_snap:
                status = "ENABLED ✓" if row["enable"] else "DISABLED ✗"
                logger.new_client(
                    f"  [NEW]     {email:<28} "
                    f"↑{fmt_bytes(row['up'])} ↓{fmt_bytes(row['down'])}  "
                    f"quota:{fmt_bytes(row['total'])}  {status}"
                )
                new_count += 1
            elif email in resets:
                logger.reset_ev(
                    f"  [RESET]   {email:<28} traffic zeroed on master"
                )
                reset_count += 1
            else:
                prev   = master_snap.get(email, {})
                d_up   = row["up"]   - prev.get("up",   0)
                d_down = row["down"] - prev.get("down", 0)
                if d_up > 0 or d_down > 0:
                    logger.traffic(
                        f"  [TRAFFIC] {email:<28} "
                        f"total ↑{fmt_bytes(row['up'])} ↓{fmt_bytes(row['down'])}  "
                        f"Δ +{fmt_bytes(d_up)} / +{fmt_bytes(d_down)}"
                    )
                    delta_count += 1
        logger.info(
            f"  ─ {new_count} new  |  {reset_count} resets  |  "
            f"{delta_count} with traffic Δ  |  {len(merged)} total"
        )

        # ── 7. Apply to master ────────────────────────────────────────────────
        logger.info("─" * 50)
        apply_to_master(local_db, local_service, merged)

        # ── 8. Apply to remotes ───────────────────────────────────────────────
        logger.info("─" * 50)
        write_errors = []
        for srv in servers:
            name = srv["name"]
            if name in errors:
                logger.warn(f"  ⚠ Skipping {name} (fetch failed: {errors[name][:80]})")
                continue
            try:
                remote_emails = {r["email"] for r in remote_data.get(name, [])}
                new_emails    = master_emails - remote_emails
                if new_emails:
                    logger.info(
                        f"  → {name}: pushing {len(new_emails)} new client(s): "
                        f"{', '.join(sorted(new_emails))}"
                    )
                    push_new_clients_to_remote(srv, list(new_emails), master_inbounds, merged)
                apply_to_remote(srv, merged)
            except Exception as e:
                write_errors.append(name)
                logger.error(f"  ✗ Failed writing to {name}: {e}")

        # ── 9. Save state ─────────────────────────────────────────────────────
        save_state(merged, remote_data)

        # ── Final summary ─────────────────────────────────────────────────────
        total_errors = len(errors) + len(write_errors)
        logger.info("═" * 60)
        if total_errors == 0:
            logger.success("✅ SYNC COMPLETED WITH NO ERRORS")
            logger.success(
                f"   {len(merged)} clients synced to "
                f"{len(remote_data)}/{len(servers)} remotes"
            )
        else:
            logger.warn(f"⚠️  SYNC COMPLETED WITH {total_errors} ERROR(S)")
            if errors:
                logger.error(f"   Fetch errors:  {', '.join(errors.keys())}")
            if write_errors:
                logger.error(f"   Write errors:  {', '.join(write_errors)}")
        logger.info("═" * 60)

    except Exception as e:
        logger.error(f"Sync failed: {e}")
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)


def quick_sync():
    """
    Quick structural sync triggered by inotify DB change.
    Detects: new clients, traffic resets (zeroed), enable/disable toggles,
             quota/expiry changes.
    Pushes those changes immediately to all remotes.
    Does NOT calculate traffic deltas. Does NOT update state.json.
    """
    logger.info("⚡ Quick Sync — checking for structural changes...")

    try:
        config  = load_json(CONF_FILE)
        servers = load_json(SERVERS_FILE).get("servers", [])
        state   = load_json(STATE_FILE)

        local_db = config.get("local_db_path", "")
        if not local_db or not os.path.exists(local_db):
            logger.error("Master DB not found: " + local_db)
            return
        if not servers:
            return

        master_stats, master_inbounds = fetch_master(local_db)
        master_snap = state.get("servers", {}).get("master", {})
        master_map  = {r["email"]: r for r in master_stats}

        new_emails:    set             = set(master_map.keys()) - set(master_snap.keys())
        resets:        set             = set()
        enable_changes: Dict[str, int]  = {}
        quota_changes:  Dict[str, dict] = {}

        for email, row in master_map.items():
            if email not in master_snap:
                continue
            prev = master_snap[email]
            # Reset: traffic dropped to zero (>1 MB prev threshold avoids noise)
            if row["up"] == 0 and row["down"] == 0:
                if prev.get("up", 0) > 1_048_576 or prev.get("down", 0) > 1_048_576:
                    resets.add(email)
            # Enable / disable toggled
            pe = prev.get("enable", None)
            if pe is not None and int(row["enable"]) != int(pe):
                enable_changes[email] = row["enable"]
            # Quota or expiry changed
            pt = prev.get("total",       None)
            px = prev.get("expiry_time", None)
            if (pt is not None and row["total"]       != pt) or \
               (px is not None and row["expiry_time"] != px):
                quota_changes[email] = row

        if not (new_emails or resets or enable_changes or quota_changes):
            logger.info("⚡ No structural changes — skipping push")
            return

        # Log detected changes
        logger.info("─" * 50)
        for email in sorted(new_emails):
            r = master_map[email]
            logger.new_client(
                f"  [NEW]    {email:<28} quota:{fmt_bytes(r['total'])}  "
                f"{'ENABLED ✓' if r['enable'] else 'DISABLED ✗'}"
            )
        for email in sorted(resets):
            logger.reset_ev(
                f"  [RESET]  {email:<28} traffic zeroed → pushing to remotes"
            )
        for email, val in sorted(enable_changes.items()):
            logger.change(
                f"  [TOGGLE] {email:<28} → {'ENABLED ✓' if val else 'DISABLED ✗'}"
            )
        for email in sorted(quota_changes.keys()):
            r = quota_changes[email]
            logger.change(
                f"  [QUOTA]  {email:<28} total:{fmt_bytes(r['total'])}"
            )

        # Build partial merged (only changed clients)
        def make_row(e: str) -> dict:
            r = master_map[e]
            return {
                "email": e, "up": r["up"], "down": r["down"],
                "expiry_time": r["expiry_time"], "total": r["total"],
                "enable": r["enable"], "inbound_id": r["inbound_id"],
            }

        changed = new_emails | resets | set(enable_changes) | set(quota_changes)
        partial = {e: make_row(e) for e in changed if e in master_map}

        # Push to all remotes in parallel
        logger.info("─" * 50)
        q_errors = []
        q_lock   = threading.Lock()

        def push_one(srv):
            try:
                if new_emails:
                    push_new_clients_to_remote(
                        srv, list(new_emails), master_inbounds, partial
                    )
                existing = (resets | set(enable_changes) | set(quota_changes)) - new_emails
                if existing:
                    apply_to_remote(srv, {e: partial[e] for e in existing if e in partial})
                logger.success(f"  ✓ {srv['name']}: quick sync applied")
            except Exception as e:
                with q_lock:
                    q_errors.append(srv["name"])
                logger.error(f"  ✗ {srv['name']}: {e}")

        threads = [
            threading.Thread(target=push_one, args=(s,), daemon=True) for s in servers
        ]
        for t in threads: t.start()
        for t in threads: t.join()

        logger.info("─" * 50)
        if not q_errors:
            logger.success("⚡ QUICK SYNC COMPLETED WITH NO ERRORS")
        else:
            logger.warn(
                f"⚡ Quick sync: {len(q_errors)} error(s) — {', '.join(q_errors)}"
            )

    except Exception as e:
        logger.error(f"Quick sync failed: {e}")
        import traceback
        logger.error(traceback.format_exc())


if __name__ == "__main__":
    mode = sys.argv[1] if len(sys.argv) > 1 else "--full"
    if mode == "--quick":
        quick_sync()
    else:
        sync_all()
PYSCRIPT

  chmod +x "$SYNC_SCRIPT"
  ok "$(msg sync_script_created)"
}

ensure_ssh_key() {
  mkdir -p "$ETC_DIR"
  if [[ ! -f "$SSH_KEY" ]]; then
    info "$(msg generating_key)"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N '' -C "xui-multi-sync" >/dev/null 2>&1
    ok "$(msg key_generated): $SSH_KEY"
  fi
  chmod 600 "$SSH_KEY"
}

init_config_files() {
  mkdir -p "$ETC_DIR" "$VAR_DIR"
  
  # Main config
  if [[ ! -f "$CONF" ]]; then
    local_db="$(detect_local_db || echo "/etc/x-ui/x-ui.db")"
    local_service="$(detect_local_service || echo "x-ui")"
    
    cat >"$CONF" <<EOF
{
  "local_db_path": "$local_db",
  "local_service_name": "$local_service",
  "sync_interval_minutes": 60,
  "is_master": true
}
EOF
    ok "$(msg config_created)"
  fi
  
  # Servers config
  if [[ ! -f "$SERVERS_CONF" ]]; then
    cat >"$SERVERS_CONF" <<'EOF'
{
  "servers": []
}
EOF
    ok "$(msg servers_created)"
  fi
}

write_systemd_units() {
  local interval_sec="$1"
  
  cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=XUI Multi-Server Sync Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 $SYNC_SCRIPT
StandardOutput=journal
StandardError=journal
EOF

  cat >"$TIMER_FILE" <<EOF
[Unit]
Description=XUI Multi-Server Sync Timer

[Timer]
OnBootSec=120
OnUnitActiveSec=${interval_sec}s
Persistent=true

[Install]
WantedBy=timers.target
EOF

  cat >"/etc/systemd/system/${SERVICE_NAME}-watcher.service" <<EOF
[Unit]
Description=XUI Multi-Server Sync Watcher (inotify)
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=$APP_DIR/watcher.sh
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

  cat >"$APP_DIR/watcher.sh" <<'WATCHSCRIPT'
#!/usr/bin/env bash
# inotify watcher: triggers quick-sync on master DB structural changes
CONF="/etc/xui-multi-sync/config.json"
SYNC_SCRIPT="/opt/xui-multi-sync/sync.py"
DEBOUNCE=3

DB_PATH=$(python3 -c "import json; print(json.load(open('$CONF'))['local_db_path'])" 2>/dev/null || true)
if [[ -z "$DB_PATH" ]] || [[ ! -f "$DB_PATH" ]]; then
  echo "Watcher: DB not found at: '$DB_PATH'" >&2
  exit 1
fi

# SQLite WAL mode: actual writes go to db-wal, not the main db file.
# Watch both so we catch all write activity.
WATCH_FILES=("$DB_PATH")
[[ -f "${DB_PATH}-wal" ]] && WATCH_FILES+=("${DB_PATH}-wal")

echo "Watcher: monitoring ${WATCH_FILES[*]}"
while true; do
  # Re-check WAL file existence each loop (created on first write)
  WATCH_FILES=("$DB_PATH")
  [[ -f "${DB_PATH}-wal" ]] && WATCH_FILES+=("${DB_PATH}-wal")

  inotifywait -q -e close_write,modify "${WATCH_FILES[@]}" 2>/dev/null || { sleep 5; continue; }
  sleep "$DEBOUNCE"
  # Drain rapid bursts
  while inotifywait -q -t 1 -e close_write,modify "${WATCH_FILES[@]}" 2>/dev/null; do
    sleep 1
  done
  /usr/bin/python3 "$SYNC_SCRIPT" --quick 2>&1 | systemd-cat -t xui-multi-sync-watcher || true
done
WATCHSCRIPT

  chmod +x "$APP_DIR/watcher.sh"
  systemctl daemon-reload
  ok "$(msg systemd_created)"
}

enable_timer() {
  systemctl enable --now "${SERVICE_NAME}.timer" >/dev/null 2>&1
  if command -v inotifywait >/dev/null 2>&1; then
    systemctl enable --now "${SERVICE_NAME}-watcher.service" >/dev/null 2>&1 || true
  fi
  ok "$(msg timer_enabled)"
}

disable_timer() {
  systemctl disable --now "${SERVICE_NAME}.timer" >/dev/null 2>&1
  systemctl disable --now "${SERVICE_NAME}-watcher.service" >/dev/null 2>&1 || true
  ok "$(msg timer_disabled)"
}

run_sync_now() {
  info "$(msg running_sync)"
  /usr/bin/python3 "$SYNC_SCRIPT"
  ok "$(msg sync_done)"
}

list_servers() {
  echo ""
  echo "═══════════════════════════════════════"
  echo "  $(msg server_list)"
  echo "═══════════════════════════════════════"
  
  if [[ ! -f "$SERVERS_CONF" ]]; then
    warn "$(msg no_servers_file)"
    return
  fi
  
  local count
  count=$(jq '.servers | length' "$SERVERS_CONF")
  
  if [[ "$count" -eq 0 ]]; then
    warn "$(msg no_servers)"
    return
  fi
  
  for i in $(seq 0 $((count - 1))); do
    local name host port user
    name=$(jq -r ".servers[$i].name" "$SERVERS_CONF")
    host=$(jq -r ".servers[$i].host" "$SERVERS_CONF")
    port=$(jq -r ".servers[$i].port" "$SERVERS_CONF")
    user=$(jq -r ".servers[$i].user" "$SERVERS_CONF")
    
    echo "[$((i+1))] $name"
    echo "    Host: $user@$host:$port"
  done
  echo ""
}

add_server() {
  echo ""
  info "$(msg add_server)"
  echo ""

  # ── Step 1: collect and validate inputs ─────────────────────────────────
  local name host port user

  # Name: non-empty + no duplicate
  while true; do
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      read -r -p "نام سرور (مثلاً: Server-1): " name
    else
      read -r -p "Server name (e.g., Server-1): " name
    fi
    if [[ -z "$name" ]]; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        warn "نام سرور نمی‌تواند خالی باشد."
      else
        warn "Server name cannot be empty."
      fi
      continue
    fi
    if jq -e --arg n "$name" '.servers[] | select(.name == $n)' "$SERVERS_CONF" >/dev/null 2>&1; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        warn "سروری با نام '$name' قبلاً وجود دارد. نام دیگری انتخاب کنید."
      else
        warn "A server named '$name' already exists. Choose a different name."
      fi
      continue
    fi
    break
  done

  # Host: non-empty; warn on duplicate but allow
  while true; do
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      read -r -p "آدرس IP/Host: " host
    else
      read -r -p "IP/Host address: " host
    fi
    if [[ -z "$host" ]]; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        warn "آدرس نمی‌تواند خالی باشد."
      else
        warn "Address cannot be empty."
      fi
      continue
    fi
    if jq -e --arg h "$host" '.servers[] | select(.host == $h)' "$SERVERS_CONF" >/dev/null 2>&1; then
      local dup_ok
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        read -r -p "⚠ این آدرس قبلاً اضافه شده. ادامه می‌دهید؟ [y/N]: " dup_ok
      else
        read -r -p "⚠ This host is already in the servers list. Continue? [y/N]: " dup_ok
      fi
      [[ "$dup_ok" =~ ^[Yy]$ ]] || continue
    fi
    break
  done

  # Port: numeric, 1-65535
  while true; do
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      read -r -p "پورت SSH [22]: " port
    else
      read -r -p "SSH port [22]: " port
    fi
    port="${port:-22}"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        warn "پورت باید عددی بین ۱ تا ۶۵۵۳۵ باشد."
      else
        warn "Port must be a number between 1 and 65535."
      fi
      port=""
      continue
    fi
    break
  done

  # User: default root
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    read -r -p "کاربر SSH [root]: " user
  else
    read -r -p "SSH user [root]: " user
  fi
  user="${user:-root}"

  # ── Helper: remove conflicting known_hosts entry ──────────────────────────
  _fix_known_hosts() {
    ssh-keygen -R "${host}" -f ~/.ssh/known_hosts >/dev/null 2>&1 || true
    if [[ "$port" != "22" ]]; then
      ssh-keygen -R "[${host}]:${port}" -f ~/.ssh/known_hosts >/dev/null 2>&1 || true
    fi
    # Also check system-wide known_hosts
    [[ -f /etc/ssh/ssh_known_hosts ]] && \
      ssh-keygen -R "${host}" -f /etc/ssh/ssh_known_hosts >/dev/null 2>&1 || true
  }

  # ── Helper: detect known_hosts conflict in SSH error output ───────────────
  _is_known_hosts_error() {
    local output="$1"
    echo "$output" | grep -qiE "REMOTE HOST IDENTIFICATION|Host key verification failed|WARNING.*IDENTIFICATION HAS CHANGED"
  }

  # ── Step 2: copy SSH key first (needed for auto-detect) ───────────────────
  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "کپی کلید SSH به $host..."
  else
    info "Copying SSH key to $host..."
  fi

  local copy_err
  copy_err=$(ssh-copy-id \
    -i "${SSH_KEY}.pub" \
    -p "$port" \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    "${user}@${host}" 2>&1)
  local copy_rc=$?

  if [[ $copy_rc -ne 0 ]]; then
    if _is_known_hosts_error "$copy_err"; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        warn "کلید هاست در known_hosts تغییر کرده. در حال حذف خودکار و تلاش مجدد..."
      else
        warn "Host key conflict in known_hosts. Removing old entry and retrying..."
      fi
      _fix_known_hosts
      copy_err=$(ssh-copy-id \
        -i "${SSH_KEY}.pub" \
        -p "$port" \
        -o StrictHostKeyChecking=accept-new \
        -o ConnectTimeout=10 \
        "${user}@${host}" 2>&1)
      copy_rc=$?
    fi

    if [[ $copy_rc -ne 0 ]]; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        warn "کپی خودکار کلید ناموفق بود:"
        warn "  $copy_err"
        warn "لطفاً کلید را دستی کپی کنید:"
      else
        warn "Auto key-copy failed:"
        warn "  $copy_err"
        warn "Copy the key manually:"
      fi
      echo "  ssh-copy-id -i ${SSH_KEY}.pub -p $port ${user}@${host}"
      echo ""
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        read -r -p "بعد از کپی دستی Enter بزنید تا ادامه دهیم (یا Ctrl+C برای لغو): " _
      else
        read -r -p "Press Enter after copying manually (or Ctrl+C to cancel): " _
      fi
    fi
  fi

  # ── Step 3: test SSH connection ────────────────────────────────────────────
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "تست اتصال SSH به $host..."
  else
    info "Testing SSH connection to $host..."
  fi

  local ssh_test ssh_rc
  ssh_test=$(ssh \
    -i "$SSH_KEY" \
    -p "$port" \
    -o BatchMode=yes \
    -o StrictHostKeyChecking=accept-new \
    -o ConnectTimeout=10 \
    "${user}@${host}" \
    "echo OK" 2>&1)
  ssh_rc=$?

  # Auto-fix known_hosts conflict on the test connection too
  if [[ $ssh_rc -ne 0 ]] && _is_known_hosts_error "$ssh_test"; then
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      warn "مشکل known_hosts شناسایی شد. در حال حذف خودکار و تلاش مجدد..."
    else
      warn "known_hosts conflict detected. Removing old entry and retrying..."
    fi
    _fix_known_hosts
    ssh_test=$(ssh \
      -i "$SSH_KEY" \
      -p "$port" \
      -o BatchMode=yes \
      -o StrictHostKeyChecking=accept-new \
      -o ConnectTimeout=10 \
      "${user}@${host}" \
      "echo OK" 2>&1)
    ssh_rc=$?
  fi

  if [[ $ssh_rc -ne 0 ]]; then
    err ""
    # Detect specific failure reason
    local _reason
    if echo "$ssh_test" | grep -qiE "timed out|Connection timed out"; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        _reason="اتصال SSH بعد از ۱۰ ثانیه قطع شد. سرور در دسترس نیست یا پورت اشتباه است."
      else
        _reason="SSH connection timed out after 10 seconds. Server unreachable or wrong port ($port)."
      fi
    elif echo "$ssh_test" | grep -qiE "Connection refused"; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        _reason="اتصال رد شد. آیا SSH روی پورت $port در حال اجراست؟"
      else
        _reason="Connection refused. Is SSH running on port $port?"
      fi
    elif echo "$ssh_test" | grep -qiE "No route to host|Network is unreachable|Could not resolve"; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        _reason="مسیری به $host وجود ندارد. آدرس IP را بررسی کنید."
      else
        _reason="No route to $host. Check the IP address."
      fi
    elif echo "$ssh_test" | grep -qiE "Permission denied|Authentication failed"; then
      if [[ "$LANG_CURRENT" == "fa" ]]; then
        _reason="احراز هویت ناموفق. کلید SSH در authorized_keys سرور نیست."
      else
        _reason="Authentication failed. SSH key not in server's authorized_keys."
      fi
    else
      _reason="$ssh_test"
    fi
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      err "اتصال SSH به $host ناموفق بود:"
      err "  $_reason"
      err "سرور اضافه نشد."
    else
      err "SSH connection to $host failed:"
      err "  $_reason"
      err "Server not added."
    fi
    return 1
  fi

  # ── Step 4: auto-detect service name and DB path on remote ────────────────
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "تشخیص خودکار سرویس و دیتابیس در سرور $host..."
  else
    info "Auto-detecting service and database on $host..."
  fi

  local detect_cmd
  detect_cmd='SERVICE=""; for s in x-ui xui 3x-ui xray-ui; do systemctl list-unit-files 2>/dev/null | grep -q "${s}.service" && SERVICE="$s" && break; done; echo "${SERVICE:-x-ui}"; DB=""; for p in /etc/x-ui/x-ui.db /usr/local/x-ui/x-ui.db /var/lib/x-ui/x-ui.db /opt/x-ui/x-ui.db /etc/3x-ui/x-ui.db; do [ -f "$p" ] && DB="$p" && break; done; echo "${DB:-/etc/x-ui/x-ui.db}"'

  local detect_out detect_rc
  detect_out=$(ssh \
    -i "$SSH_KEY" \
    -p "$port" \
    -o BatchMode=yes \
    -o ConnectTimeout=10 \
    "${user}@${host}" \
    "$detect_cmd" 2>&1)
  detect_rc=$?

  if [[ $detect_rc -ne 0 ]]; then
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      warn "تشخیص خودکار ناموفق بود (خطا: $detect_out). از مقادیر پیش‌فرض استفاده می‌شود."
    else
      warn "Auto-detect failed ($detect_out). Falling back to defaults."
    fi
    detect_out="x-ui
/etc/x-ui/x-ui.db"
  fi

  local service_name db_path _svc_detected=true _db_detected=true
  service_name=$(echo "$detect_out" | sed -n '1p')
  db_path=$(echo "$detect_out" | sed -n '2p')

  # Check if service detection fell back (empty result means none found)
  if [[ -z "$service_name" ]]; then
    service_name="x-ui"
    _svc_detected=false
  fi
  if [[ -z "$db_path" ]]; then
    db_path="/etc/x-ui/x-ui.db"
    _db_detected=false
  fi

  if [[ "$_svc_detected" == true ]]; then
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      ok "سرویس تشخیص داده شد: $service_name"
    else
      ok "Detected service: $service_name"
    fi
  else
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      warn "سرویس x-ui پیدا نشد. مقدار پیش‌فرض 'x-ui' استفاده می‌شود."
    else
      warn "No x-ui service found on remote. Defaulting to 'x-ui'."
    fi
  fi

  if [[ "$_db_detected" == true ]]; then
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      ok "مسیر دیتابیس: $db_path"
    else
      ok "Detected database: $db_path"
    fi
  else
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      warn "فایل دیتابیس پیدا نشد. مسیر پیش‌فرض '/etc/x-ui/x-ui.db' استفاده می‌شود."
      warn "اگر این مسیر اشتباه است، بعداً سرور را حذف و دوباره اضافه کنید."
    else
      warn "Database file not found on remote. Defaulting to '/etc/x-ui/x-ui.db'."
      warn "If this is wrong, remove and re-add this server after fixing the path."
    fi
  fi

  # ── Step 5: save to config ─────────────────────────────────────────────────
  local new_server
  new_server=$(jq -n \
    --arg name "$name" \
    --arg host "$host" \
    --arg port "$port" \
    --arg user "$user" \
    --arg db "$db_path" \
    --arg svc "$service_name" \
    --arg key "$SSH_KEY" \
    '{
      name: $name,
      host: $host,
      port: ($port | tonumber),
      user: $user,
      db_path: $db,
      service_name: $svc,
      ssh_key: $key
    }')

  local tmp
  tmp=$(mktemp)
  jq ".servers += [$new_server]" "$SERVERS_CONF" > "$tmp"
  mv "$tmp" "$SERVERS_CONF"

  echo ""
  ok "$(msg server_added): $name"
}

remove_server() {
  list_servers
  
  local count
  count=$(jq '.servers | length' "$SERVERS_CONF")
  
  if [[ "$count" -eq 0 ]]; then
    return
  fi
  
  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    read -r -p "شماره سروری که می‌خواهید حذف کنید: " num
  else
    read -r -p "Server number to remove: " num
  fi
  
  if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -lt 1 ]] || [[ "$num" -gt "$count" ]]; then
    warn "Invalid number"
    return
  fi
  
  local index=$((num - 1))
  local name
  name=$(jq -r ".servers[$index].name" "$SERVERS_CONF")
  
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    read -r -p "آیا مطمئن هستید که می‌خواهید '$name' را حذف کنید؟ [y/N]: " confirm
  else
    read -r -p "Are you sure you want to remove '$name'? [y/N]: " confirm
  fi
  
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    local tmp
    tmp=$(mktemp)
    jq "del(.servers[$index])" "$SERVERS_CONF" > "$tmp"
    mv "$tmp" "$SERVERS_CONF"
    ok "Server $name removed"
  fi
}

change_interval() {
  local current
  current=$(jq -r '.sync_interval_minutes' "$CONF" 2>/dev/null || echo "60")
  
  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "بازه زمانی فعلی: $current دقیقه"
    read -r -p "بازه زمانی جدید (به دقیقه) [$current]: " new_interval
  else
    info "Current interval: $current minutes"
    read -r -p "New interval (minutes) [$current]: " new_interval
  fi
  new_interval="${new_interval:-$current}"
  
  if ! [[ "$new_interval" =~ ^[0-9]+$ ]] || [[ "$new_interval" -lt 1 ]]; then
    warn "Interval must be positive number"
    return
  fi
  
  # Update config
  local tmp
  tmp=$(mktemp)
  jq ".sync_interval_minutes = $new_interval" "$CONF" > "$tmp"
  mv "$tmp" "$CONF"
  
  # Update timer
  local interval_sec=$((new_interval * 60))
  write_systemd_units "$interval_sec"
  systemctl daemon-reload
  
  # Restart timer if active
  if systemctl is-active "${SERVICE_NAME}.timer" >/dev/null 2>&1; then
    systemctl restart "${SERVICE_NAME}.timer"
  fi
  
  ok "Interval changed to $new_interval minutes"
}

show_status() {
  echo ""
  echo "═══════════════════════════════════════"
  echo "  $(msg system_status)"
  echo "═══════════════════════════════════════"
  
  local interval
  interval=$(jq -r '.sync_interval_minutes' "$CONF" 2>/dev/null || echo "N/A")
  echo "$(msg sync_interval): $interval min"
  
  local count
  count=$(jq '.servers | length' "$SERVERS_CONF" 2>/dev/null || echo "0")
  echo "$(msg server_count): $count"
  
  local is_master
  is_master=$(jq -r '.is_master // true' "$CONF" 2>/dev/null)
  if [[ "$is_master" == "true" ]]; then
    info "$(msg master_server)"
  fi
  
  echo ""
  if systemctl is-active "${SERVICE_NAME}.timer" >/dev/null 2>&1; then
    ok "$(msg timer_active)"
    echo ""
    systemctl status "${SERVICE_NAME}.timer" --no-pager -l | head -n 10
  else
    warn "$(msg timer_inactive)"
  fi

  echo ""
  if systemctl is-active "${SERVICE_NAME}-watcher.service" >/dev/null 2>&1; then
    ok "Watcher (inotify): Active ✓"
  else
    warn "Watcher (inotify): Inactive ✗"
    if ! command -v inotifywait >/dev/null 2>&1; then
      warn "  inotify-tools not installed — run: apt-get install inotify-tools"
    fi
  fi

  echo ""
  echo "$(msg recent_logs):"
  journalctl -u "${SERVICE_NAME}.service" -n 5 --no-pager 2>/dev/null || echo "  (No logs)"
  echo ""
}

show_logs() {
  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "نمایش لاگ‌های اخیر..."
  else
    info "Showing recent logs..."
  fi
  echo ""
  
  if [[ -f "$LOG_FILE" ]]; then
    tail -n 50 "$LOG_FILE"
  else
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      warn "فایل لاگ وجود ندارد"
    else
      warn "Log file does not exist"
    fi
  fi
  
  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    read -r -p "برای بازگشت Enter بزنید..." _
  else
    read -r -p "Press Enter to continue..." _
  fi
}

run_uninstaller() {
  clear
  echo "╔═══════════════════════════════════════╗"
  echo "║  XUI Multi-Server Sync - Uninstall   ║"
  echo "╚═══════════════════════════════════════╝"
  echo ""

  if [[ "$LANG_CURRENT" == "fa" ]]; then
    warn "این عملیات تمام فایل‌ها، سرویس‌ها و تنظیمات را حذف می‌کند!"
    echo ""
    read -r -p "آیا مطمئن هستید؟ [y/N]: " confirm
  else
    warn "This will remove all files, services and configuration!"
    echo ""
    read -r -p "Are you sure? [y/N]: " confirm
  fi

  [[ ! "$confirm" =~ ^[Yy]$ ]] && {
    if [[ "$LANG_CURRENT" == "fa" ]]; then info "عملیات لغو شد."
    else info "Cancelled."; fi
    return 0
  }

  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "توقف و غیرفعال‌سازی سرویس‌ها..."
  else
    info "Stopping and disabling services..."
  fi
  systemctl disable --now "${SERVICE_NAME}.timer"            2>/dev/null || true
  systemctl disable --now "${SERVICE_NAME}-watcher.service"  2>/dev/null || true
  systemctl stop        "${SERVICE_NAME}.service"            2>/dev/null || true

  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "حذف فایل‌های systemd..."
  else
    info "Removing systemd units..."
  fi
  rm -f "$SERVICE_FILE" "$TIMER_FILE" "/etc/systemd/system/${SERVICE_NAME}-watcher.service"
  systemctl daemon-reload

  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "حذف فایل‌های برنامه..."
  else
    info "Removing application files..."
  fi
  rm -rf "$APP_DIR" "$VAR_DIR"
  rm -f  "$BIN" "$BINCMD"
  rm -f  /var/log/xui-multi-sync.log

  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    read -r -p "فایل‌های پیکربندی ($ETC_DIR) هم حذف شود؟ [y/N]: " del_conf
  else
    read -r -p "Also remove configuration files ($ETC_DIR)? [y/N]: " del_conf
  fi

  if [[ "$del_conf" =~ ^[Yy]$ ]]; then
    rm -rf "$ETC_DIR"
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      ok "فایل‌های پیکربندی حذف شدند"
    else
      ok "Configuration files removed"
    fi
  else
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      info "فایل‌های پیکربندی نگه داشته شدند: $ETC_DIR"
    else
      info "Configuration files kept: $ETC_DIR"
    fi
  fi

  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    ok "حذف با موفقیت انجام شد!"
  else
    ok "Uninstallation completed!"
  fi
  exit 0
}

run_update() {
  local url="https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-multi-sync-installer.sh"
  local script_dst="$APP_DIR/xuisync.sh"

  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "دریافت آخرین نسخه از GitHub..."
  else
    info "Fetching latest version from GitHub..."
  fi

  local tmp
  tmp=$(mktemp)
  if ! curl -fsSL "$url" -o "$tmp"; then
    rm -f "$tmp"
    if [[ "$LANG_CURRENT" == "fa" ]]; then
      err "دانلود ناموفق بود. اتصال اینترنت را بررسی کنید."
    else
      err "Download failed. Check your internet connection."
    fi
    return 1
  fi

  if [[ ! -s "$tmp" ]]; then
    rm -f "$tmp"
    err "Downloaded file is empty."
    return 1
  fi

  # Put new script in place first
  cp -f "$tmp" "$script_dst"
  chmod +x "$script_dst"
  rm -f "$tmp"
  ln -sf "$script_dst" "$BIN"
  ln -sf "$script_dst" "$BINCMD"

  # Full reinstall from the new script — preserves all user data
  bash "$script_dst" --reinstall

  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    ok "بروزرسانی با موفقیت انجام شد!"
    info "برای اجرا دستور زیر را وارد کنید: sudo xuisync"
  else
    ok "Update completed successfully!"
    info "Run: sudo xuisync"
  fi
  sleep 2
}

main_menu() {
  while true; do
    clear
    echo "╔═══════════════════════════════════════╗"
    echo "║   XUI Multi-Server Sync Manager      ║"
    echo "║   $(msg menu_title)   ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
    echo "1) $(msg menu_1)"
    echo "2) $(msg menu_2)"
    echo "3) $(msg menu_3)"
    echo "4) $(msg menu_4)"
    echo "5) $(msg menu_5)"
    echo "6) $(msg menu_6)"
    echo "7) $(msg menu_7)"
    echo "8) $(msg menu_8)"
    echo "9) $(msg menu_9)"
    echo "U) $(msg menu_update)"
    echo "remove) $(msg menu_u)"
    echo "0) $(msg menu_0)"
    echo ""
    read -r -p "Select / انتخاب [0-9, U, remove]: " choice
    
    case "$choice" in
      1) show_status; 
         if [[ "$LANG_CURRENT" == "fa" ]]; then
           read -r -p "برای بازگشت Enter بزنید..." _
         else
           read -r -p "Press Enter to continue..." _
         fi
         ;;
      2) list_servers; 
         if [[ "$LANG_CURRENT" == "fa" ]]; then
           read -r -p "برای بازگشت Enter بزنید..." _
         else
           read -r -p "Press Enter to continue..." _
         fi
         ;;
      3) add_server ;;
      4) remove_server ;;
      5) change_interval ;;
      6)
        if systemctl is-active "${SERVICE_NAME}.timer" >/dev/null 2>&1; then
          disable_timer
        else
          enable_timer
        fi
        sleep 1
        ;;
      7) run_sync_now; 
         if [[ "$LANG_CURRENT" == "fa" ]]; then
           read -r -p "برای بازگشت Enter بزنید..." _
         else
           read -r -p "Press Enter to continue..." _
         fi
         ;;
      8) show_logs ;;
      9) choose_language ;;
      [Uu]) run_update ;;
      remove|REMOVE|Remove) run_uninstaller ;;
      0) ok "$(msg exit)"; exit 0 ;;
      *) warn "Invalid choice" ;;
    esac
  done
}

install_mode() {
  # Choose language first
  choose_language
  
  clear
  echo "╔═══════════════════════════════════════╗"
  echo "║   XUI Multi-Server Sync - Installer  ║"
  echo "╚═══════════════════════════════════════╝"
  echo ""
  
  need_root
  install_deps
  ensure_ssh_key
  write_sync_script
  init_config_files
  
  # Get interval
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    read -r -p "بازه زمانی همگام‌سازی (دقیقه) [60]: " interval_min
  else
    read -r -p "Sync interval (minutes) [60]: " interval_min
  fi
  interval_min="${interval_min:-60}"
  [[ ! "$interval_min" =~ ^[0-9]+$ ]] && interval_min=60
  [[ "$interval_min" -lt 1 ]] && interval_min=1
  
  local interval_sec=$((interval_min * 60))
  
  # Update config
  local tmp
  tmp=$(mktemp)
  jq ".sync_interval_minutes = $interval_min" "$CONF" > "$tmp"
  mv "$tmp" "$CONF"
  
  write_systemd_units "$interval_sec"
  enable_timer

  # Install script to permanent location and create global commands
  _install_commands

  echo ""
  ok "$(msg install_complete)"
  echo ""
  if [[ "$LANG_CURRENT" == "fa" ]]; then
    info "کلید عمومی SSH شما:"
    cat "${SSH_KEY}.pub"
    echo ""
    warn "این کلید را روی سرورهای دیگر در ~/.ssh/authorized_keys قرار دهید"
    echo ""
    info "برای مدیریت سیستم از هر جایی دستور زیر را اجرا کنید:"
    echo "  sudo xuisync"
    echo ""

    read -r -p "می‌خواهید الان سرورها را اضافه کنید؟ [Y/n]: " add_now
  else
    info "Your SSH public key:"
    cat "${SSH_KEY}.pub"
    echo ""
    warn "Add this key to ~/.ssh/authorized_keys on other servers"
    echo ""
    info "To manage the system from anywhere, run:"
    echo "  sudo xuisync"
    echo ""

    read -r -p "Add servers now? [Y/n]: " add_now
  fi
  add_now="${add_now:-Y}"
  
  if [[ "$add_now" =~ ^[Yy]$ ]]; then
    add_server
    main_menu
  fi
}

# ── Ensure permanent script copy and symlinks ─────────────────────────────
_install_commands() {
  local _dst="$APP_DIR/xuisync.sh"
  local _self
  _self="$(readlink -f "$0" 2>/dev/null || true)"

  # If $0 is a real script file (not bash/sh itself), copy it
  if [[ -f "$_self" ]] && [[ "$_self" != */bash ]] && [[ "$_self" != */sh ]] && [[ "$_self" != */dash ]]; then
    cp -f "$_self" "$_dst" && chmod +x "$_dst"
  # If permanent copy already exists, just reuse it
  elif [[ -f "$_dst" ]]; then
    chmod +x "$_dst"
  # Last resort: re-download from GitHub
  else
    curl -fsSL "https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-multi-sync-installer.sh" \
      -o "$_dst" && chmod +x "$_dst"
  fi

  ln -sf "$_dst" "$BIN"    2>/dev/null || true
  ln -sf "$_dst" "$BINCMD" 2>/dev/null || true
}

# Main entry point
if [[ "${1:-}" == "--write-sync" ]]; then
  write_sync_script
  exit 0
fi

if [[ "${1:-}" == "--write-units" ]]; then
  _interval_sec=$(python3 -c "
import json
try:
  c = json.load(open('$CONF'))
  print(int(c.get('sync_interval_minutes', 60)) * 60)
except:
  print(3600)
" 2>/dev/null || echo 3600)
  write_systemd_units "$_interval_sec"
  systemctl enable "${SERVICE_NAME}-watcher.service" 2>/dev/null || true
  exit 0
fi

if [[ "${1:-}" == "--reinstall" ]]; then
  # Full reinstall preserving all user data:
  #   /etc/xui-multi-sync/config.json      ← kept
  #   /etc/xui-multi-sync/servers.json     ← kept
  #   /etc/xui-multi-sync/id_ed25519(.pub) ← kept
  #   /etc/xui-multi-sync/language         ← kept
  #   /var/lib/xui-multi-sync/state.json   ← kept
  need_root
  load_language

  info "Stopping services..."
  systemctl disable --now "${SERVICE_NAME}.timer"           2>/dev/null || true
  systemctl disable --now "${SERVICE_NAME}-watcher.service" 2>/dev/null || true
  systemctl stop        "${SERVICE_NAME}.service"           2>/dev/null || true

  info "Installing/updating dependencies..."
  install_deps

  info "Deploying sync engine..."
  write_sync_script

  info "Deploying systemd units..."
  _interval_sec=$(python3 -c "
import json
try:
  c = json.load(open('$CONF'))
  print(int(c.get('sync_interval_minutes', 60)) * 60)
except:
  print(3600)
" 2>/dev/null || echo 3600)
  write_systemd_units "$_interval_sec"

  info "Enabling services..."
  enable_timer

  _install_commands
  ok "Reinstall complete."
  exit 0
fi

if [[ ! -f "$CONF" ]] || [[ ! -f "$SERVERS_CONF" ]]; then
  install_mode
else
  need_root
  load_language
  # Self-repair: always ensure symlinks exist and point to a valid copy
  _install_commands
  main_menu
fi
