#!/usr/bin/env bash
# XUI Panel Manager - Complete Installer with Web Dashboard
# Multi-language, Package Management, Telegram Notifications, Backup, Monitoring

set -euo pipefail

APP_DIR="/opt/xui-panel-manager"
ETC_DIR="/etc/xui-panel-manager"
VAR_DIR="/var/lib/xui-panel-manager"
WEB_DIR="$APP_DIR/web"
BACKUP_DIR="$VAR_DIR/backups"
BIN="/usr/local/bin/xui-panel-manager"
CONF="$ETC_DIR/config.json"
SERVERS_CONF="$ETC_DIR/servers.json"
PACKAGES_CONF="$ETC_DIR/packages.json"
SSH_KEY="$ETC_DIR/id_ed25519"
SYNC_SCRIPT="$APP_DIR/sync.py"
WEB_APP="$APP_DIR/web_app.py"
SERVICE_NAME="xui-panel-manager"
SYNC_SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}-sync.service"
SYNC_TIMER_FILE="/etc/systemd/system/${SERVICE_NAME}-sync.timer"
WEB_SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}-web.service"
LOG_FILE="/var/log/xui-panel-manager.log"

# Language system
LANG_FILE="$ETC_DIR/language.conf"
declare -A TEXTS_EN TEXTS_FA
CURRENT_LANG="en"

# English texts
TEXTS_EN=(
  [install_deps]="Installing dependencies..."
  [deps_installed]="Dependencies installed."
  [generating_key]="Generating SSH key..."
  [key_generated]="SSH key generated:"
  [config_created]="Configuration created"
  [systemd_created]="Systemd units created"
  [timer_enabled]="Timer enabled"
  [timer_disabled]="Timer disabled"
  [sync_running]="Running synchronization..."
  [sync_done]="Synchronization completed"
  [server_list]="Server List"
  [no_servers]="No servers defined"
  [add_server]="Add New Server"
  [server_name]="Server name (e.g., Server-1):"
  [server_host]="IP Address/Host:"
  [server_port]="SSH Port [22]:"
  [server_user]="SSH User [root]:"
  [server_db_path]="Database path [/etc/x-ui/x-ui.db]:"
  [server_service]="Service name [x-ui]:"
  [server_added]="Server added:"
  [copy_ssh_key]="Copy SSH key to this server? [Y/n]:"
  [remove_server]="Enter server number to remove:"
  [confirm_remove]="Are you sure you want to remove '%s'? [y/N]:"
  [server_removed]="Server removed:"
  [interval_current]="Current interval: %s minutes"
  [interval_new]="New interval (minutes) [%s]:"
  [interval_changed]="Interval changed to %s minutes"
  [status_title]="System Status"
  [sync_interval]="Sync interval: %s minutes"
  [server_count]="Server count: %s"
  [timer_active]="Timer: Active ✓"
  [timer_inactive]="Timer: Inactive ✗"
  [web_panel]="Web Panel: http://localhost:%s"
  [recent_logs]="Recent logs:"
  [menu_title]="XUI Panel Manager"
  [menu_status]="Show system status"
  [menu_servers_list]="List servers"
  [menu_servers_add]="Add server"
  [menu_servers_remove]="Remove server"
  [menu_interval]="Change sync interval"
  [menu_timer]="Enable/Disable auto timer"
  [menu_sync_now]="Run sync now"
  [menu_packages]="Manage packages"
  [menu_web_panel]="Web panel settings"
  [menu_telegram]="Telegram bot settings"
  [menu_logs]="Show logs"
  [menu_exit]="Exit"
  [press_enter]="Press Enter to continue..."
  [invalid_choice]="Invalid choice"
  [need_root]="This script must be run as root."
  [install_title]="XUI Panel Manager - Installer"
  [install_complete]="Installation completed successfully!"
  [web_panel_info]="Web Panel URL: http://YOUR_IP:%s"
  [web_default_creds]="Default credentials: admin / admin123"
  [change_password]="Please change the password after first login!"
  [setup_telegram]="Setup Telegram notifications? [y/N]:"
  [telegram_bot_token]="Telegram Bot Token:"
  [telegram_chat_id]="Telegram Chat ID:"
  [web_port]="Web Panel Port [8080]:"
  [web_host]="Web Panel Host [0.0.0.0]:"
  [package_menu_title]="Package Management"
  [package_list]="List packages"
  [package_add]="Add package"
  [package_remove]="Remove package"
  [package_back]="Back"
  [pkg_name]="Package name:"
  [pkg_days]="Days:"
  [pkg_traffic_gb]="Traffic (GB):"
  [pkg_price]="Price (optional):"
  [pkg_added]="Package added:"
  [no_packages]="No packages defined"
  [language_select]="Select Language / انتخاب زبان"
  [language_en]="English"
  [language_fa]="فارسی"
)

# Persian texts
TEXTS_FA=(
  [install_deps]="نصب وابستگی‌ها..."
  [deps_installed]="وابستگی‌ها نصب شدند."
  [generating_key]="ایجاد کلید SSH..."
  [key_generated]="کلید SSH ایجاد شد:"
  [config_created]="فایل پیکربندی ایجاد شد"
  [systemd_created]="واحدهای systemd ایجاد شدند"
  [timer_enabled]="تایمر فعال شد"
  [timer_disabled]="تایمر غیرفعال شد"
  [sync_running]="اجرای همگام‌سازی..."
  [sync_done]="همگام‌سازی انجام شد"
  [server_list]="لیست سرورها"
  [no_servers]="هیچ سروری تعریف نشده"
  [add_server]="اضافه کردن سرور جدید"
  [server_name]="نام سرور (مثلاً: Server-1):"
  [server_host]="آدرس IP/Host:"
  [server_port]="پورت SSH [22]:"
  [server_user]="کاربر SSH [root]:"
  [server_db_path]="مسیر دیتابیس [/etc/x-ui/x-ui.db]:"
  [server_service]="نام سرویس [x-ui]:"
  [server_added]="سرور اضافه شد:"
  [copy_ssh_key]="کپی کلید SSH به این سرور؟ [Y/n]:"
  [remove_server]="شماره سرور برای حذف:"
  [confirm_remove]="مطمئنید می‌خواهید '%s' را حذف کنید؟ [y/N]:"
  [server_removed]="سرور حذف شد:"
  [interval_current]="بازه فعلی: %s دقیقه"
  [interval_new]="بازه جدید (دقیقه) [%s]:"
  [interval_changed]="بازه به %s دقیقه تغییر یافت"
  [status_title]="وضعیت سیستم"
  [sync_interval]="بازه همگام‌سازی: %s دقیقه"
  [server_count]="تعداد سرورها: %s"
  [timer_active]="تایمر: فعال ✓"
  [timer_inactive]="تایمر: غیرفعال ✗"
  [web_panel]="پنل وب: http://localhost:%s"
  [recent_logs]="لاگ‌های اخیر:"
  [menu_title]="مدیریت پنل XUI"
  [menu_status]="نمایش وضعیت سیستم"
  [menu_servers_list]="لیست سرورها"
  [menu_servers_add]="اضافه کردن سرور"
  [menu_servers_remove]="حذف سرور"
  [menu_interval]="تغییر بازه همگام‌سازی"
  [menu_timer]="فعال/غیرفعال کردن تایمر"
  [menu_sync_now]="اجرای دستی همگام‌سازی"
  [menu_packages]="مدیریت پکیج‌ها"
  [menu_web_panel]="تنظیمات پنل وب"
  [menu_telegram]="تنظیمات تلگرام"
  [menu_logs]="نمایش لاگ‌ها"
  [menu_exit]="خروج"
  [press_enter]="برای بازگشت Enter بزنید..."
  [invalid_choice]="انتخاب نامعتبر"
  [need_root]="این اسکریپت باید با root اجرا شود."
  [install_title]="نصب مدیریت پنل XUI"
  [install_complete]="نصب با موفقیت انجام شد!"
  [web_panel_info]="آدرس پنل وب: http://YOUR_IP:%s"
  [web_default_creds]="نام‌کاربری/رمز پیش‌فرض: admin / admin123"
  [change_password]="لطفاً بعد از اولین ورود رمز را تغییر دهید!"
  [setup_telegram]="راه‌اندازی اعلان‌های تلگرام؟ [y/N]:"
  [telegram_bot_token]="توکن ربات تلگرام:"
  [telegram_chat_id]="Chat ID تلگرام:"
  [web_port]="پورت پنل وب [8080]:"
  [web_host]="هاست پنل وب [0.0.0.0]:"
  [package_menu_title]="مدیریت پکیج‌ها"
  [package_list]="لیست پکیج‌ها"
  [package_add]="اضافه کردن پکیج"
  [package_remove]="حذف پکیج"
  [package_back]="بازگشت"
  [pkg_name]="نام پکیج:"
  [pkg_days]="تعداد روز:"
  [pkg_traffic_gb]="حجم ترافیک (گیگابایت):"
  [pkg_price]="قیمت (اختیاری):"
  [pkg_added]="پکیج اضافه شد:"
  [no_packages]="پکیجی تعریف نشده"
  [language_select]="Select Language / انتخاب زبان"
  [language_en]="English"
  [language_fa]="فارسی"
)

# Color functions
color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info() { color "36" "[•] $*"; }
ok() { color "32" "[✓] $*"; }
warn() { color "33" "[⚠] $*"; }
err() { color "31" "[✗] $*"; }

# Header display
header() {
  clear
  echo "================================================"
  color "36" "   XUI Panel Manager - Installation"
  echo "================================================"
  echo ""
}

# Translation function
t() {
  local key="$1"
  shift
  local text=""
  
  if [[ "$CURRENT_LANG" == "fa" ]]; then
    text="${TEXTS_FA[$key]:-$key}"
  else
    text="${TEXTS_EN[$key]:-$key}"
  fi
  
  # Support for printf formatting
  if [[ $# -gt 0 ]]; then
    printf "$text" "$@"
  else
    echo "$text"
  fi
}

load_language() {
  if [[ -f "$LANG_FILE" ]]; then
    CURRENT_LANG=$(cat "$LANG_FILE")
  fi
}

save_language() {
  mkdir -p "$ETC_DIR"
  echo "$CURRENT_LANG" > "$LANG_FILE"
}

select_language() {
  clear
  echo "╔════════════════════════════════════════╗"
  echo "║  $(t language_select)  ║"
  echo "╚════════════════════════════════════════╝"
  echo ""
  echo "1) $(t language_en)"
  echo "2) $(t language_fa)"
  echo ""
  read -r -p "Choice/انتخاب [1-2]: " lang_choice
  
  case "$lang_choice" in
    1) CURRENT_LANG="en" ;;
    2) CURRENT_LANG="fa" ;;
    *) CURRENT_LANG="en" ;;
  esac
  
  save_language
}

need_root() {
  if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
    err "$(t need_root)"
    exit 1
  fi
}

install_deps() {
  info "$(t install_deps)"
  apt-get update -qq >/dev/null 2>&1
  DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 python3-pip python3-venv \
    sqlite3 openssh-client jq curl \
    >/dev/null 2>&1
  ok "$(t deps_installed)"
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
  mkdir -p "$APP_DIR" "$ETC_DIR" "$VAR_DIR" "$BACKUP_DIR"
  
  cat >"$SYNC_SCRIPT" <<'PYSCRIPT'
#!/usr/bin/env python3
"""XUI Panel Manager - Sync Engine with Backup & Notifications"""

import json
import os
import sys
import sqlite3
import subprocess
import time
import shutil
from typing import Dict, List
from datetime import datetime
import requests

CONF_FILE = "/etc/xui-panel-manager/config.json"
SERVERS_FILE = "/etc/xui-panel-manager/servers.json"
LOG_FILE = "/var/log/xui-panel-manager.log"
BACKUP_DIR = "/var/lib/xui-panel-manager/backups"

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

def send_telegram_notification(config, message):
    """Send notification via Telegram"""
    telegram = config.get("telegram", {})
    if not telegram.get("enabled") or not telegram.get("bot_token"):
        return
    
    try:
        bot_token = telegram["bot_token"]
        chat_id = telegram["chat_id"]
        url = f"https://api.telegram.org/bot{bot_token}/sendMessage"
        
        data = {
            "chat_id": chat_id,
            "text": f"🔔 XUI Panel Manager\n\n{message}",
            "parse_mode": "HTML"
        }
        
        requests.post(url, json=data, timeout=10)
    except Exception as e:
        logger.warn(f"Failed to send Telegram notification: {e}")

def backup_database(db_path, server_name="local"):
    """Create backup of database before sync"""
    try:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_name = f"{server_name}_{timestamp}.db"
        backup_path = os.path.join(BACKUP_DIR, backup_name)
        
        shutil.copy2(db_path, backup_path)
        logger.info(f"Backup created: {backup_name}")
        
        # Keep only last 10 backups per server
        backups = sorted([f for f in os.listdir(BACKUP_DIR) if f.startswith(server_name)])
        if len(backups) > 10:
            for old_backup in backups[:-10]:
                os.remove(os.path.join(BACKUP_DIR, old_backup))
        
        return backup_path
    except Exception as e:
        logger.warn(f"Backup failed: {e}")
        return None

def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)

def run_ssh_command(server, command, timeout=30):
    """Execute command on remote server via SSH"""
    ssh_key = server.get("ssh_key", "/etc/xui-panel-manager/id_ed25519")
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
    """Fetch database from remote server"""
    db_path = server.get("db_path", "/etc/x-ui/x-ui.db")
    
    logger.info(f"Fetching data from {server['name']} ({server['host']})...")
    
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
    
    logger.success(f"✓ {server['name']}: {len(data)} clients")
    return data

def fetch_local_db(db_path):
    """Fetch database from local server"""
    logger.info(f"Fetching local data from {db_path}...")
    
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
    logger.success(f"✓ Local server: {len(rows)} clients")
    return rows

def merge_client_data(all_data: Dict[str, List[dict]]) -> Dict[str, dict]:
    """Merge client data: MAX(traffic), MIN(expiry), MAX(total), MIN(enable)"""
    logger.info("Merging and comparing data...")
    
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
                merged[email]["up"] = max(merged[email]["up"], row["up"])
                merged[email]["down"] = max(merged[email]["down"], row["down"])
                
                if row["expiry_time"] > 0:
                    if merged[email]["expiry_time"] == 0:
                        merged[email]["expiry_time"] = row["expiry_time"]
                    else:
                        merged[email]["expiry_time"] = min(
                            merged[email]["expiry_time"], 
                            row["expiry_time"]
                        )
                
                merged[email]["total"] = max(merged[email]["total"], row["total"])
                merged[email]["enable"] = min(merged[email]["enable"], row["enable"])
    
    logger.success(f"✓ Merged {len(merged)} unique clients")
    return merged

def apply_to_remote(server, merged_data: dict):
    """Apply merged data to remote server"""
    logger.info(f"Applying changes to {server['name']}...")
    
    db_path = server.get("db_path", "/etc/x-ui/x-ui.db")
    service_name = server.get("service_name", "x-ui")
    
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
    
    python_updater = f"""
python3 -c "
import sqlite3, sys, time, os
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
        logger.success(f"✓ {server['name']} updated")
    else:
        raise RuntimeError(f"Update failed on {server['name']}")

def apply_to_local(db_path, service_name, merged_data: dict):
    """Apply merged data to local server"""
    logger.info(f"Applying changes to local server...")
    
    # Backup first
    backup_database(db_path, "local")
    
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
    
    tries = 0
    max_tries = 8
    
    while tries < max_tries:
        try:
            con = sqlite3.connect(db_path, timeout=10)
            cur = con.cursor()
            cur.executescript(full_sql)
            con.commit()
            con.close()
            logger.success("✓ Local server updated")
            return
        except Exception as e:
            if "locked" in str(e).lower() or "busy" in str(e).lower():
                tries += 1
                time.sleep(1)
                continue
            raise
    
    logger.warn("Database locked, stopping service temporarily...")
    os.system(f"systemctl stop {service_name} 2>/dev/null")
    time.sleep(1)
    
    try:
        con = sqlite3.connect(db_path, timeout=5)
        cur = con.cursor()
        cur.executescript(full_sql)
        con.commit()
        con.close()
        logger.success("✓ Local server updated (with restart)")
    finally:
        os.system(f"systemctl start {service_name} 2>/dev/null")

def sync_all():
    """Main sync function"""
    logger.info("=" * 60)
    logger.info("Starting XUI Panel Manager Sync")
    logger.info("=" * 60)
    
    try:
        config = load_json(CONF_FILE)
        servers = load_json(SERVERS_FILE)
        
        all_data = {}
        failed_servers = []
        
        # Fetch from all remote servers
        for server in servers.get("servers", []):
            try:
                all_data[server["name"]] = fetch_remote_db(server)
            except Exception as e:
                logger.error(f"Failed to fetch from {server['name']}: {e}")
                failed_servers.append(server["name"])
                continue
        
        # Fetch from local server
        local_db = config.get("local_db_path")
        if local_db and os.path.exists(local_db):
            all_data["LOCAL"] = fetch_local_db(local_db)
        
        if not all_data:
            msg = "No data fetched from any server!"
            logger.error(msg)
            send_telegram_notification(config, f"❌ Sync Failed\n{msg}")
            return
        
        # Merge data
        merged = merge_client_data(all_data)
        
        # Apply to all servers
        logger.info("=" * 60)
        logger.info("Applying merged data to all servers...")
        logger.info("=" * 60)
        
        for server in servers.get("servers", []):
            if server["name"] in failed_servers:
                continue
            try:
                # Backup remote DB via SSH
                apply_to_remote(server, merged)
            except Exception as e:
                logger.error(f"Failed to apply to {server['name']}: {e}")
                failed_servers.append(server["name"])
        
        # Apply to local
        if local_db and os.path.exists(local_db):
            try:
                apply_to_local(
                    local_db,
                    config.get("local_service_name", "x-ui"),
                    merged
                )
            except Exception as e:
                logger.error(f"Failed to apply to local: {e}")
        
        logger.success("=" * 60)
        logger.success(f"Sync completed! {len(merged)} clients synced")
        logger.success("=" * 60)
        
        # Send success notification
        msg = f"✅ Sync Successful\n\nClients synced: {len(merged)}"
        if failed_servers:
            msg += f"\n\n⚠️ Failed servers: {', '.join(failed_servers)}"
        send_telegram_notification(config, msg)
        
    except Exception as e:
        msg = f"❌ Sync Error\n\n{str(e)}"
        logger.error(f"Sync error: {e}")
        send_telegram_notification(config, msg)
        import traceback
        logger.error(traceback.format_exc())
        sys.exit(1)

if __name__ == "__main__":
    sync_all()
PYSCRIPT

  chmod +x "$SYNC_SCRIPT"
  ok "$(t config_created)"
}

ensure_ssh_key() {
  mkdir -p "$ETC_DIR"
  if [[ ! -f "$SSH_KEY" ]]; then
    info "$(t generating_key)"
    ssh-keygen -t ed25519 -f "$SSH_KEY" -N '' -C "xui-panel-manager" >/dev/null 2>&1
    ok "$(t key_generated)"
    cat "${SSH_KEY}.pub"
  fi
  chmod 600 "$SSH_KEY"
}

init_config_files() {
  mkdir -p "$ETC_DIR" "$VAR_DIR" "$BACKUP_DIR"
  
  # Main config
  if [[ ! -f "$CONF" ]]; then
    local_db="$(detect_local_db || echo "/etc/x-ui/x-ui.db")"
    local_service="$(detect_local_service || echo "x-ui")"
    
    cat >"$CONF" <<EOF
{
  "local_db_path": "$local_db",
  "local_service_name": "$local_service",
  "sync_interval_minutes": 60,
  "web_panel": {
    "enabled": true,
    "host": "0.0.0.0",
    "port": 8080,
    "secret_key": "$(openssl rand -hex 32)"
  },
  "telegram": {
    "enabled": false,
    "bot_token": "",
    "chat_id": ""
  },
  "backup": {
    "enabled": true,
    "keep_count": 10
  }
}
EOF
    ok "$(t config_created)"
  fi
  
  # Servers config
  if [[ ! -f "$SERVERS_CONF" ]]; then
    cat >"$SERVERS_CONF" <<'EOF'
{
  "servers": []
}
EOF
  fi
  
  # Packages config
  if [[ ! -f "$PACKAGES_CONF" ]]; then
    cat >"$PACKAGES_CONF" <<'EOF'
{
  "packages": [
    {
      "id": "basic_30",
      "name": "Basic - 30 Days",
      "days": 30,
      "traffic_gb": 50,
      "price": "10"
    },
    {
      "id": "standard_30",
      "name": "Standard - 30 Days",
      "days": 30,
      "traffic_gb": 100,
      "price": "15"
    },
    {
      "id": "premium_30",
      "name": "Premium - 30 Days",
      "days": 30,
      "traffic_gb": 200,
      "price": "25"
    },
    {
      "id": "unlimited_30",
      "name": "Unlimited - 30 Days",
      "days": 30,
      "traffic_gb": 1000,
      "price": "50"
    }
  ]
}
EOF
  fi
}

write_systemd_units() {
  local interval_sec="$1"
  
  # Web service
  cat >"$WEB_SERVICE_FILE" <<EOF
[Unit]
Description=XUI Panel Manager Web Interface
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/python3 $APP_DIR/web_app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

  # Sync service
  cat >"$SYNC_SERVICE_FILE" <<EOF
[Unit]
Description=XUI Panel Manager Sync Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 $SYNC_SCRIPT
StandardOutput=journal
StandardError=journal
EOF

  # Sync timer
  cat >"$SYNC_TIMER_FILE" <<EOF
[Unit]
Description=XUI Panel Manager Sync Timer

[Timer]
OnBootSec=120
OnUnitActiveSec=${interval_sec}s
Persistent=true

[Install]
WantedBy=timers.target
EOF

  systemctl daemon-reload
  ok "$(t systemd_created)"
}

enable_timer() {
  systemctl enable --now "${SERVICE_NAME}-sync.timer" >/dev/null 2>&1
  ok "$(t timer_enabled)"
}

disable_timer() {
  systemctl disable --now "${SERVICE_NAME}-sync.timer" >/dev/null 2>&1
  ok "$(t timer_disabled)"
}

# ==========================================
# Main Installation Function
# ==========================================

main_install() {
  header
  select_language
  
  info "$(t starting_install)"
  
  # Install dependencies
  install_deps
  
  # Detect local X-UI
  detect_local_db
  detect_local_service
  
  # Create directory structure
  mkdir -p "$APP_DIR" "$ETC_DIR" "$VAR_DIR" "$BACKUP_DIR"
  
  # Generate SSH key
  ensure_ssh_key
  
  # Ask for sync interval
  echo ""
  info "$(t sync_interval_prompt)"
  read -p "$(t sync_interval_input) [60]: " SYNC_INTERVAL
  SYNC_INTERVAL=${SYNC_INTERVAL:-60}
  
  # Initialize config files
  init_config_files "$SYNC_INTERVAL"
  
  # Write sync script
  write_sync_script
  
  # Copy web app
  if [[ -f "web_app.py" ]]; then
    cp web_app.py "$APP_DIR/"
    cp -r templates "$APP_DIR/" 2>/dev/null || true
  fi
  
  # Create systemd units
  local interval_sec=$((SYNC_INTERVAL * 60))
  write_systemd_units "$interval_sec"
  
  # Enable timer
  enable_timer
  
  # Create symlink
  ln -sf "$APP_DIR/web_app.py" /usr/local/bin/xui-panel-manager 2>/dev/null || true
  
  echo ""
  success "$(t install_complete)"
  echo ""
  info "$(t next_steps)"
  echo ""
  echo "  1. $(t step_copy_key)"
  echo "     cat $SSH_KEY.pub"
  echo ""
  echo "  2. $(t step_add_servers)"
  echo "     # Edit: $SERVERS_FILE"
  echo ""
  echo "  3. $(t step_start_web)"
  echo "     systemctl start xui-panel-manager-web"
  echo "     # Web panel: http://YOUR_IP:8080"
  echo "     # Default login: admin / admin123"
  echo ""
  echo "  4. $(t step_test_sync)"
  echo "     python3 $SYNC_SCRIPT"
  echo ""
}

# ==========================================
# Main Execution
# ==========================================

if [[ "$EUID" -ne 0 ]]; then
  echo "Error: This script must be run as root (sudo)"
  exit 1
fi

# Run installation
main_install

exit 0
