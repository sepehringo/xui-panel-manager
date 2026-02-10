#!/usr/bin/env bash
# XUI Multi-Server Sync - Uninstaller
set -euo pipefail

color() { printf "\033[%sm%s\033[0m\n" "$1" "$2"; }
info() { color "36" "[•] $*"; }
ok() { color "32" "[✓] $*"; }
warn() { color "33" "[⚠] $*"; }
err() { color "31" "[✗] $*"; }

if [[ "${EUID:-$(id -u)}" -ne 0 ]]; then
  err "این اسکریپت باید با root اجرا شود."
  exit 1
fi

echo "╔═══════════════════════════════════════╗"
echo "║  XUI Multi-Server Sync - Uninstaller ║"
echo "╚═══════════════════════════════════════╝"
echo ""
warn "این عملیات تمام فایل‌ها و تنظیمات را حذف می‌کند!"
echo ""
read -r -p "آیا مطمئن هستید؟ [y/N]: " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
  info "عملیات لغو شد."
  exit 0
fi

info "توقف و غیرفعال‌سازی سرویس‌ها..."
systemctl disable --now xui-multi-sync.timer 2>/dev/null || true
systemctl stop xui-multi-sync.service 2>/dev/null || true

info "حذف فایل‌های systemd..."
rm -f /etc/systemd/system/xui-multi-sync.service
rm -f /etc/systemd/system/xui-multi-sync.timer
systemctl daemon-reload

info "حذف فایل‌های برنامه..."
rm -rf /opt/xui-multi-sync
rm -rf /var/lib/xui-multi-sync
rm -f /usr/local/bin/xui-multi-sync

read -r -p "آیا می‌خواهید فایل‌های پیکربندی (/etc/xui-multi-sync) را هم حذف کنید؟ [y/N]: " del_conf

if [[ "$del_conf" =~ ^[Yy]$ ]]; then
  info "حذف فایل‌های پیکربندی..."
  rm -rf /etc/xui-multi-sync
  ok "فایل‌های پیکربندی حذف شدند"
else
  info "فایل‌های پیکربندی نگه داشته شدند: /etc/xui-multi-sync"
fi

info "حذف لاگ‌ها..."
rm -f /var/log/xui-multi-sync.log

ok "حذف با موفقیت انجام شد!"
