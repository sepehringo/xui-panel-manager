#!/usr/bin/env bash
# XUI Multi-Server Sync - Installer & Manager
# Synchronizes traffic and expiry data across multiple x-ui/3x-ui panels
# Takes MAX traffic consumption and MIN remaining days across all servers

set -euo pipefail

APP_DIR="/opt/xui-multi-sync"
ETC_DIR="/etc/xui-multi-sync"
VAR_DIR="/var/lib/xui-multi-sync"
BIN="/usr/local/bin/xui-multi-sync"
CONF="$ETC_DIR/config.json"
SERVERS_CONF="$ETC_DIR/servers.json"
SSH_KEY="$ETC_DIR/id_ed25519"
SYNC_SCRIPT="$APP_DIR/sync.py"
SERVICE_NAME="xui-multi-sync"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}.timer"

# Colors
color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info() { color "36" "[•] $*"; }
ok() { color "32" "[✓] $*"; }
warn() { color "33" "[⚠] $*"; }
err() { color "31" "[✗] $*"; }

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "این اسکریپت باید با root اجرا شود."
    exit 1
  fi
}

install_deps() {
  info "نصب وابستگی‌ها..."
  apt-get update -qq >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get install -y python3 sqlite3 openssh-client jq >/dev/null 2>&1
  ok "وابستگی‌ها نصب شدند."
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
XUI Multi-Server Sync
Compares all server databases and syncs:
- MAX traffic (up/down) across all servers
- MIN expiry_time (remaining days) across all servers
- MAX total bandwidth
- MIN enable status (if any disabled, disable everywhere)
"""

import json
import os
import sys
import sqlite3
import subprocess
import tempfile
import time
from typing import Dict, List, Optional
from datetime import datetime

CONF_FILE = "/etc/xui-multi-sync/config.json"
SERVERS_FILE = "/etc/xui-multi-sync/servers.json"
LOG_FILE = "/var/log/xui-multi-sync.log"

class Logger:
    def __init__(self, log_file):
        self.log_file = log_file
        
    def log(self, level, msg):
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        line = f"[{timestamp}] [{level}] {msg}\n"
        print(line.rstrip())
        try:
            with open(self.log_file, "a", encoding="utf-8") as f:
                f.write(line)
        except:
            pass
    
    def info(self, msg): self.log("INFO", msg)
    def warn(self, msg): self.log("WARN", msg)
    def error(self, msg): self.log("ERROR", msg)
    def success(self, msg): self.log("SUCCESS", msg)

logger = Logger(LOG_FILE)

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def run_ssh_command(server, command, timeout=30):
    """Execute command on remote server via SSH"""
    ssh_key = server.get("ssh_key", "/etc/xui-multi-sync/id_ed25519")
    host = server["host"]
    port = server.get("port", 22)
    user = server.get("user", "root")
    
    cmd = [
        "ssh",
        "-i", ssh_key,
        "-p", str(port),
        "-o", "BatchMode=yes",
        "-o", "StrictHostKeyChecking=accept-new",
        "-o", "ConnectTimeout=10",
        f"{user}@{host}",
        command
    ]
    
    result = subprocess.run(
        cmd,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        timeout=timeout,
        text=True
    )
    
    if result.returncode != 0:
        raise RuntimeError(f"SSH failed to {host}: {result.stderr}")
    
    return result.stdout

def fetch_remote_db(server):
    """Fetch database from remote server and return rows"""
    db_path = server.get("db_path", "/etc/x-ui/x-ui.db")
    
    logger.info(f"جمع‌آوری داده از {server['name']} ({server['host']})...")
    
    # Read database via SSH and parse
    python_reader = f"""
python3 -c "
import sqlite3, json, sys
try:
    con = sqlite3.connect('{db_path}', timeout=5)
    cur = con.cursor()
    cur.execute('SELECT email, up, down, expiry_time, total, enable FROM client_traffics')
    rows = []
    for r in cur.fetchall():
        rows.append({{
            'email': r[0],
            'up': int(r[1] or 0),
            'down': int(r[2] or 0),
            'expiry_time': int(r[3] or 0),
            'total': int(r[4] or 0),
            'enable': int(r[5] or 0)
        }})
    con.close()
    print(json.dumps(rows, ensure_ascii=False))
except Exception as e:
    print(json.dumps({{'error': str(e)}}), file=sys.stderr)
    sys.exit(1)
"
"""
    
    output = run_ssh_command(server, python_reader)
    data = json.loads(output)
    
    logger.success(f"✓ {server['name']}: {len(data)} کلاینت")
    return data

def fetch_local_db(db_path):
    """Fetch database from local server"""
    logger.info(f"جمع‌آوری داده محلی از {db_path}...")
    
    con = sqlite3.connect(db_path, timeout=5)
    con.row_factory = sqlite3.Row
    cur = con.cursor()
    cur.execute("SELECT email, up, down, expiry_time, total, enable FROM client_traffics")
    
    rows = []
    for r in cur.fetchall():
        rows.append({
            "email": r["email"],
            "up": int(r["up"] or 0),
            "down": int(r["down"] or 0),
            "expiry_time": int(r["expiry_time"] or 0),
            "total": int(r["total"] or 0),
            "enable": int(r["enable"] or 0),
        })
    
    con.close()
    logger.success(f"✓ سرور محلی: {len(rows)} کلاینت")
    return rows

def merge_client_data(all_data: Dict[str, List[dict]]) -> Dict[str, dict]:
    """
    Merge client data from all servers:
    - MAX(up, down, total) 
    - MIN(expiry_time) where expiry_time > 0
    - MIN(enable)
    """
    logger.info("ادغام و مقایسه داده‌ها...")
    
    merged = {}
    
    for server_name, rows in all_data.items():
        for row in rows:
            email = row["email"]
            
            if email not in merged:
                merged[email] = {
                    "email": email,
                    "up": row["up"],
                    "down": row["down"],
                    "expiry_time": row["expiry_time"],
                    "total": row["total"],
                    "enable": row["enable"],
                }
            else:
                # MAX traffic
                merged[email]["up"] = max(merged[email]["up"], row["up"])
                merged[email]["down"] = max(merged[email]["down"], row["down"])
                
                # MIN expiry_time (only if > 0)
                if row["expiry_time"] > 0:
                    if merged[email]["expiry_time"] == 0:
                        merged[email]["expiry_time"] = row["expiry_time"]
                    else:
                        merged[email]["expiry_time"] = min(
                            merged[email]["expiry_time"], 
                            row["expiry_time"]
                        )
                
                # MAX total
                merged[email]["total"] = max(merged[email]["total"], row["total"])
                
                # MIN enable (if anyone disabled, disable everywhere)
                merged[email]["enable"] = min(merged[email]["enable"], row["enable"])
    
    logger.success(f"✓ داده {len(merged)} کلاینت یونیک ادغام شد")
    return merged

def apply_to_remote(server, merged_data: dict):
    """Apply merged data to remote server"""
    logger.info(f"اعمال تغییرات به {server['name']}...")
    
    db_path = server.get("db_path", "/etc/x-ui/x-ui.db")
    service_name = server.get("service_name", "x-ui")
    
    # Generate SQL update statements
    sql_statements = ["PRAGMA busy_timeout=10000;", "BEGIN TRANSACTION;"]
    
    for email, data in merged_data.items():
        email_escaped = email.replace("'", "''")
        sql = (
            f"UPDATE client_traffics SET "
            f"up={data['up']}, "
            f"down={data['down']}, "
            f"expiry_time={data['expiry_time']}, "
            f"total={data['total']}, "
            f"enable={data['enable']} "
            f"WHERE email='{email_escaped}';"
        )
        sql_statements.append(sql)
    
    sql_statements.append("COMMIT;")
    full_sql = "\n".join(sql_statements)
    
    # Execute via SSH
    python_updater = f"""
python3 -c "
import sqlite3, sys, time
sql = '''
{full_sql}
'''

db_path = '{db_path}'
service = '{service_name}'

tries = 0
max_tries = 8

while tries < max_tries:
    try:
        con = sqlite3.connect(db_path, timeout=10)
        cur = con.cursor()
        cur.executescript(sql)
        con.commit()
        con.close()
        print('SUCCESS')
        sys.exit(0)
    except Exception as e:
        if 'locked' in str(e).lower() or 'busy' in str(e).lower():
            tries += 1
            time.sleep(1)
            continue
        print(f'ERROR: {{e}}', file=sys.stderr)
        sys.exit(1)

# If still locked, try stopping service
import os
os.system(f'systemctl stop {{service}} 2>/dev/null')
time.sleep(1)
try:
    con = sqlite3.connect(db_path, timeout=5)
    cur = con.cursor()
    cur.executescript(sql)
    con.commit()
    con.close()
    print('SUCCESS_WITH_RESTART')
finally:
    os.system(f'systemctl start {{service}} 2>/dev/null')
"
"""
    
    result = run_ssh_command(server, python_updater, timeout=60)
    
    if "SUCCESS" in result:
        logger.success(f"✓ {server['name']} به‌روزرسانی شد")
    else:
        raise RuntimeError(f"Update failed on {server['name']}")

def apply_to_local(db_path, service_name, merged_data: dict):
    """Apply merged data to local server"""
    logger.info(f"اعمال تغییرات به سرور محلی...")
    
    sql_statements = ["PRAGMA busy_timeout=10000;", "BEGIN TRANSACTION;"]
    
    for email, data in merged_data.items():
        email_escaped = email.replace("'", "''")
        sql = (
            f"UPDATE client_traffics SET "
            f"up={data['up']}, "
            f"down={data['down']}, "
            f"expiry_time={data['expiry_time']}, "
            f"total={data['total']}, "
            f"enable={data['enable']} "
            f"WHERE email='{email_escaped}';"
        )
        sql_statements.append(sql)
    
    sql_statements.append("COMMIT;")
    full_sql = "\n".join(sql_statements)
    
    # Try to apply
    tries = 0
    max_tries = 8
    
    while tries < max_tries:
        try:
            con = sqlite3.connect(db_path, timeout=10)
            cur = con.cursor()
            cur.executescript(full_sql)
            con.commit()
            con.close()
            logger.success("✓ سرور محلی به‌روزرسانی شد")
            return
        except Exception as e:
            if "locked" in str(e).lower() or "busy" in str(e).lower():
                tries += 1
                time.sleep(1)
                continue
            raise
    
    # Last resort: stop service
    logger.warn("دیتابیس قفل است، توقف موقت سرویس...")
    os.system(f"systemctl stop {service_name} 2>/dev/null")
    time.sleep(1)
    
    try:
        con = sqlite3.connect(db_path, timeout=5)
        cur = con.cursor()
        cur.executescript(full_sql)
        con.commit()
        con.close()
        logger.success("✓ سرور محلی به‌روزرسانی شد (با ریستارت)")
    finally:
        os.system(f"systemctl start {service_name} 2>/dev/null")

def sync_all():
    """Main sync function"""
    logger.info("=" * 60)
    logger.info("شروع همگام‌سازی چند-سرور XUI")
    logger.info("=" * 60)
    
    try:
        config = load_json(CONF_FILE)
        servers = load_json(SERVERS_FILE)
        
        all_data = {}
        
        # Fetch from all remote servers
        for server in servers.get("servers", []):
            try:
                all_data[server["name"]] = fetch_remote_db(server)
            except Exception as e:
                logger.error(f"خطا در دریافت از {server['name']}: {e}")
                continue
        
        # Fetch from local server
        local_db = config.get("local_db_path")
        if local_db and os.path.exists(local_db):
            all_data["LOCAL"] = fetch_local_db(local_db)
        
        if not all_data:
            logger.error("هیچ داده‌ای از سرورها دریافت نشد!")
            return
        
        # Merge data
        merged = merge_client_data(all_data)
        
        # Apply to all servers
        logger.info("=" * 60)
        logger.info("اعمال داده‌های ادغام‌شده به همه سرورها...")
        logger.info("=" * 60)
        
        for server in servers.get("servers", []):
            try:
                apply_to_remote(server, merged)
            except Exception as e:
                logger.error(f"خطا در اعمال به {server['name']}: {e}")
        
        # Apply to local
        if local_db and os.path.exists(local_db):
            try:
                apply_to_local(
                    local_db,
                    config.get("local_service_name", "x-ui"),
                    merged
                )
            except Exception as e:
                logger.error(f"خطا در اعمال به سرور محلی: {e}")
        
        logger.success("=" * 60)
        logger.success(f"همگام‌سازی با موفقیت انجام شد! {len(merged)} کلاینت")
        logger.success("=" * 60)
        
    except Exception as e:
        logger.error(f"خطای کلی: {e}")
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    sync_all()
PYSCRIPT

  chmod +x "$SYNC_SCRIPT"
  ok "اسکریپت همگام‌سازی ایجاد شد"
}

ensure_ssh_key() {
  mkdir -p "$ETC_DIR"
  if [[ ! -f "$SSH_KEY" ]]; then
    info "ایجاد کلید SSH..."
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N '' -C "xui-multi-sync" >/dev/null 2>&1
    ok "کلید SSH ایجاد شد: $SSH_KEY"
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
  "sync_interval_minutes": 60
}
EOF
    ok "فایل پیکربندی اصلی ایجاد شد"
  fi
  
  # Servers config
  if [[ ! -f "$SERVERS_CONF" ]]; then
    cat >"$SERVERS_CONF" <<'EOF'
{
  "servers": []
}
EOF
    ok "فایل لیست سرورها ایجاد شد"
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

  systemctl daemon-reload
  ok "واحدهای systemd ایجاد شدند"
}

enable_timer() {
  systemctl enable --now "${SERVICE_NAME}.timer" >/dev/null 2>&1
  ok "تایمر فعال شد"
}

disable_timer() {
  systemctl disable --now "${SERVICE_NAME}.timer" >/dev/null 2>&1
  ok "تایمر غیرفعال شد"
}

run_sync_now() {
  info "اجرای همگام‌سازی..."
  /usr/bin/python3 "$SYNC_SCRIPT"
  ok "همگام‌سازی انجام شد"
}

list_servers() {
  echo ""
  echo "═══════════════════════════════════════"
  echo "  لیست سرورها"
  echo "═══════════════════════════════════════"
  
  if [[ ! -f "$SERVERS_CONF" ]]; then
    warn "فایل سرورها وجود ندارد"
    return
  fi
  
  local count
  count=$(jq '.servers | length' "$SERVERS_CONF")
  
  if [[ "$count" -eq 0 ]]; then
    warn "هیچ سروری تعریف نشده"
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
  info "اضافه کردن سرور جدید"
  echo ""
  
  read -r -p "نام سرور (مثلاً: Server-1): " name
  [[ -z "$name" ]] && { warn "نام سرور نمی‌تواند خالی باشد"; return; }
  
  read -r -p "آدرس IP/Host: " host
  [[ -z "$host" ]] && { warn "آدرس نمی‌تواند خالی باشد"; return; }
  
  read -r -p "پورت SSH [22]: " port
  port="${port:-22}"
  
  read -r -p "کاربر SSH [root]: " user
  user="${user:-root}"
  
  read -r -p "مسیر دیتابیس [/etc/x-ui/x-ui.db]: " db_path
  db_path="${db_path:-/etc/x-ui/x-ui.db}"
  
  read -r -p "نام سرویس [x-ui]: " service_name
  service_name="${service_name:-x-ui}"
  
  # Add to config
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
  
  ok "سرور $name اضافه شد"
  
  # Setup SSH
  echo ""
  read -r -p "می‌خواهید کلید SSH را به این سرور کپی کنید؟ [Y/n]: " copy_key
  copy_key="${copy_key:-Y}"
  
  if [[ "$copy_key" =~ ^[Yy]$ ]]; then
    info "کپی کلید SSH به $host..."
    ssh-copy-id -i "${SSH_KEY}.pub" -p "$port" "${user}@${host}" || {
      warn "خطا در کپی کلید. لطفاً به صورت دستی این کار را انجام دهید:"
      echo "  ssh-copy-id -i ${SSH_KEY}.pub -p $port ${user}@${host}"
    }
  fi
}

remove_server() {
  list_servers
  
  local count
  count=$(jq '.servers | length' "$SERVERS_CONF")
  
  if [[ "$count" -eq 0 ]]; then
    return
  fi
  
  echo ""
  read -r -p "شماره سروری که می‌خواهید حذف کنید: " num
  
  if ! [[ "$num" =~ ^[0-9]+$ ]] || [[ "$num" -lt 1 ]] || [[ "$num" -gt "$count" ]]; then
    warn "شماره نامعتبر"
    return
  fi
  
  local index=$((num - 1))
  local name
  name=$(jq -r ".servers[$index].name" "$SERVERS_CONF")
  
  read -r -p "آیا مطمئن هستید که می‌خواهید '$name' را حذف کنید؟ [y/N]: " confirm
  
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    local tmp
    tmp=$(mktemp)
    jq "del(.servers[$index])" "$SERVERS_CONF" > "$tmp"
    mv "$tmp" "$SERVERS_CONF"
    ok "سرور $name حذف شد"
  fi
}

change_interval() {
  local current
  current=$(jq -r '.sync_interval_minutes' "$CONF" 2>/dev/null || echo "60")
  
  echo ""
  info "بازه زمانی فعلی: $current دقیقه"
  read -r -p "بازه زمانی جدید (به دقیقه) [$current]: " new_interval
  new_interval="${new_interval:-$current}"
  
  if ! [[ "$new_interval" =~ ^[0-9]+$ ]] || [[ "$new_interval" -lt 1 ]]; then
    warn "بازه زمانی باید عدد مثبت باشد"
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
  
  ok "بازه زمانی به $new_interval دقیقه تغییر یافت"
}

show_status() {
  echo ""
  echo "═══════════════════════════════════════"
  echo "  وضعیت سیستم"
  echo "═══════════════════════════════════════"
  
  local interval
  interval=$(jq -r '.sync_interval_minutes' "$CONF" 2>/dev/null || echo "N/A")
  echo "بازه همگام‌سازی: $interval دقیقه"
  
  local count
  count=$(jq '.servers | length' "$SERVERS_CONF" 2>/dev/null || echo "0")
  echo "تعداد سرورها: $count"
  
  echo ""
  if systemctl is-active "${SERVICE_NAME}.timer" >/dev/null 2>&1; then
    ok "تایمر: فعال ✓"
    echo ""
    systemctl status "${SERVICE_NAME}.timer" --no-pager -l | head -n 10
  else
    warn "تایمر: غیرفعال ✗"
  fi
  
  echo ""
  echo "آخرین اجراها:"
  journalctl -u "${SERVICE_NAME}.service" -n 5 --no-pager 2>/dev/null || echo "  (لاگی موجود نیست)"
  echo ""
}

show_logs() {
  echo ""
  info "نمایش لاگ‌های اخیر..."
  echo ""
  
  if [[ -f "$LOG_FILE" ]]; then
    tail -n 50 "$LOG_FILE"
  else
    warn "فایل لاگ وجود ندارد"
  fi
  
  echo ""
  read -r -p "برای بازگشت Enter بزنید..." _
}

main_menu() {
  while true; do
    clear
    echo "╔═══════════════════════════════════════╗"
    echo "║   XUI Multi-Server Sync Manager      ║"
    echo "║   مدیریت همگام‌سازی چند-سرور        ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
    echo "1) نمایش وضعیت سیستم"
    echo "2) لیست سرورها"
    echo "3) اضافه کردن سرور"
    echo "4) حذف سرور"
    echo "5) تغییر بازه زمانی"
    echo "6) فعال/غیرفعال کردن تایمر خودکار"
    echo "7) اجرای دستی همگام‌سازی (الان)"
    echo "8) نمایش لاگ‌ها"
    echo "9) خروج"
    echo ""
    read -r -p "انتخاب شما [1-9]: " choice
    
    case "$choice" in
      1) show_status; read -r -p "برای بازگشت Enter بزنید..." _ ;;
      2) list_servers; read -r -p "برای بازگشت Enter بزنید..." _ ;;
      3) add_server ;;
      4) remove_server ;;
      5) change_interval ;;
      6)
        if systemctl is-active "${SERVICE_NAME}.timer" >/dev/null 2>&1; then
          disable_timer
        else
          enable_timer
        fi
        ;;
      7) run_sync_now; read -r -p "برای بازگشت Enter بزنید..." _ ;;
      8) show_logs ;;
      9) ok "خروج..."; exit 0 ;;
      *) warn "انتخاب نامعتبر" ;;
    esac
  done
}

install_mode() {
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
  read -r -p "بازه زمانی همگام‌سازی (دقیقه) [60]: " interval_min
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
  
  # Create symlink
  ln -sf "$0" "$BIN" 2>/dev/null || true
  
  echo ""
  ok "نصب با موفقیت انجام شد!"
  echo ""
  info "کلید عمومی SSH شما:"
  cat "${SSH_KEY}.pub"
  echo ""
  warn "این کلید را روی سرورهای دیگر در ~/.ssh/authorized_keys قرار دهید"
  echo ""
  info "برای مدیریت سیستم دستور زیر را اجرا کنید:"
  echo "  sudo xui-multi-sync"
  echo ""
  
  read -r -p "می‌خواهید الان سرورها را اضافه کنید؟ [Y/n]: " add_now
  add_now="${add_now:-Y}"
  
  if [[ "$add_now" =~ ^[Yy]$ ]]; then
    main_menu
  fi
}

# Main entry point
if [[ ! -f "$CONF" ]] || [[ ! -f "$SERVERS_CONF" ]]; then
  install_mode
else
  need_root
  main_menu
fi
