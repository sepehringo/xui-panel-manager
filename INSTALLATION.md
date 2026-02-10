# 🔧 راهنمای نصب مفصل XUI Panel Manager

## 📋 پیش‌نیازها

### سرور:
- **OS**: Ubuntu 20.04 یا 22.04 LTS
- **RAM**: حداقل 512MB (پیشنهادی: 1GB+)
- **Storage**: حداقل 2GB فضای خالی
- **دسترسی**: root یا sudo

### پنل X-UI:
- نصب شده و در حال اجرا
- دیتابیس در مسیر استاندارد

### شبکه:
- دسترسی SSH به سرورهای دیگر
- پورت 8080 (یا دلخواه) برای پنل وب

---

## 📥 روش 1: نصب از GitHub (پیشنهادی)

### مرحله 1: آپلود به GitHub

```bash
# 1. ساخت repository جدید در GitHub
# نام: xui-panel-manager

# 2. کلون در کامپیوتر محلی
git clone https://github.com/sepehringo/xui-panel-manager.git
cd xui-panel-manager

# 3. کپی همه فایل‌ها به repo
cp /path/to/xui-panel-manager-installer.sh .
cp /path/to/web_app.py .
cp /path/to/requirements.txt .
cp -r /path/to/templates .
cp /path/to/README-panel-manager.md .
cp /path/to/QUICKSTART.md .

# 4. Commit و Push
git add .
git commit -m "Initial commit: Complete XUI Panel Manager"
git push origin main
```

### مرحله 2: نصب روی سرور

```bash
# SSH به سرور اصلی
ssh root@YOUR_SERVER_IP

# دانلود و نصب
wget https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-panel-manager-installer.sh
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

---

## 📥 روش 2: نصب دستی (بدون GitHub)

### مرحله 1: انتقال فایل‌ها

```bash
# در کامپیوتر محلی:
scp xui-panel-manager-installer.sh root@YOUR_SERVER:/root/
scp web_app.py root@YOUR_SERVER:/root/
scp requirements.txt root@YOUR_SERVER:/root/
scp -r templates root@YOUR_SERVER:/root/
```

### مرحله 2: نصب روی سرور

```bash
# SSH به سرور
ssh root@YOUR_SERVER

# اجرای نصب
cd /root
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

---

## 📥 روش 3: نصب کامل دستی (توسعه‌دهندگان)

### مرحله 1: نصب وابستگی‌ها

```bash
# آپدیت سیستم
apt-get update
apt-get upgrade -y

# نصب پکیج‌های اصلی
apt-get install -y python3 python3-pip python3-venv
apt-get install -y sqlite3 openssh-client jq curl
```

### مرحله 2: ساخت ساختار دایرکتوری

```bash
# ایجاد دایرکتوری‌ها
mkdir -p /opt/xui-panel-manager
mkdir -p /opt/xui-panel-manager/templates
mkdir -p /etc/xui-panel-manager
mkdir -p /var/lib/xui-panel-manager
mkdir -p /var/lib/xui-panel-manager/backups
```

### مرحله 3: کپی فایل‌ها

```bash
# Backend
cp web_app.py /opt/xui-panel-manager/
cp sync.py /opt/xui-panel-manager/  # اگر جداگانه دارید

# Frontend
cp templates/*.html /opt/xui-panel-manager/templates/

# Dependencies
cp requirements.txt /opt/xui-panel-manager/
```

### مرحله 4: نصب Python Dependencies

```bash
cd /opt/xui-panel-manager
pip3 install -r requirements.txt
```

### مرحله 5: ایجاد SSH Key

```bash
ssh-keygen -t ed25519 -f /etc/xui-panel-manager/id_ed25519 -N '' -C "xui-panel-manager"
chmod 600 /etc/xui-panel-manager/id_ed25519
chmod 644 /etc/xui-panel-manager/id_ed25519.pub
```

### مرحله 6: ایجاد Config Files

```bash
# config.json
cat > /etc/xui-panel-manager/config.json <<'EOF'
{
  "local_db_path": "/etc/x-ui/x-ui.db",
  "local_service_name": "x-ui",
  "sync_interval_minutes": 60,
  "web_panel": {
    "enabled": true,
    "host": "0.0.0.0",
    "port": 8080,
    "secret_key": "CHANGE_THIS_SECRET_KEY"
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

# servers.json
cat > /etc/xui-panel-manager/servers.json <<'EOF'
{
  "servers": []
}
EOF

# packages.json
cat > /etc/xui-panel-manager/packages.json <<'EOF'
{
  "packages": [
    {
      "id": "basic_30",
      "name": "Basic - 30 Days",
      "days": 30,
      "traffic_gb": 50,
      "price": "10"
    }
  ]
}
EOF

# users.json
cat > /etc/xui-panel-manager/users.json <<'EOF'
{
  "users": [
    {
      "username": "admin",
      "password": "8c6976e5b5410415bde908bd4dee15dfb167a9c873fc4bb8a81f6f2ab448a918",
      "role": "admin",
      "language": "en"
    }
  ]
}
EOF

# language.conf
echo "en" > /etc/xui-panel-manager/language.conf
```

### مرحله 7: ایجاد Systemd Services

```bash
# Web Service
cat > /etc/systemd/system/xui-panel-manager-web.service <<'EOF'
[Unit]
Description=XUI Panel Manager Web Interface
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/python3 /opt/xui-panel-manager/web_app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Sync Service
cat > /etc/systemd/system/xui-panel-manager-sync.service <<'EOF'
[Unit]
Description=XUI Panel Manager Sync Service
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/bin/python3 /opt/xui-panel-manager/sync.py
StandardOutput=journal
StandardError=journal
EOF

# Sync Timer
cat > /etc/systemd/system/xui-panel-manager-sync.timer <<'EOF'
[Unit]
Description=XUI Panel Manager Sync Timer

[Timer]
OnBootSec=120
OnUnitActiveSec=3600s
Persistent=true

[Install]
WantedBy=timers.target
EOF
```

### مرحله 8: فعال‌سازی Services

```bash
systemctl daemon-reload
systemctl enable xui-panel-manager-web.service
systemctl enable xui-panel-manager-sync.timer
systemctl start xui-panel-manager-web.service
systemctl start xui-panel-manager-sync.timer
```

### مرحله 9: ایجاد Symlink

```bash
ln -sf /opt/xui-panel-manager/installer.sh /usr/local/bin/xui-panel-manager
```

---

## 🔑 راه‌اندازی SSH Keys

### روی سرور اصلی:

```bash
# نمایش کلید عمومی
cat /etc/xui-panel-manager/id_ed25519.pub
```

### روی هر سرور دیگر:

```bash
# SSH به سرور
ssh root@REMOTE_SERVER

# اضافه کردن کلید
echo "ssh-ed25519 AAAA... xui-panel-manager" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# تست اتصال
exit

# از سرور اصلی
ssh -i /etc/xui-panel-manager/id_ed25519 root@REMOTE_SERVER
```

---

## 🌐 راه‌اندازی پنل وب

### دسترسی اولیه:

```
URL: http://YOUR_SERVER_IP:8080
Username: admin
Password: admin123
```

### تغییر رمز:

```bash
# با Python:
python3 -c "
import hashlib
password = 'NEW_PASSWORD'
hashed = hashlib.sha256(password.encode()).hexdigest()
print(hashed)
"

# کپی hash و تغییر در:
nano /etc/xui-panel-manager/users.json
```

---

## 🔥 تنظیم Firewall

### UFW (پیشنهادی):

```bash
# نصب UFW
apt-get install -y ufw

# قوانین پایه
ufw default deny incoming
ufw default allow outgoing

# SSH (حتماً قبل از enable!)
ufw allow 22/tcp

# X-UI Panel
ufw allow 2053/tcp  # یا پورت X-UI شما

# XUI Manager Web Panel
ufw allow 8080/tcp

# فعال‌سازی
ufw enable
ufw status
```

### محدود کردن دسترسی به IP خاص:

```bash
# فقط IP خاص به پنل وب
ufw delete allow 8080/tcp
ufw allow from YOUR_IP to any port 8080
```

---

## 📱 تنظیم Telegram

### مرحله 1: ساخت Bot

```
1. باز کردن تلگرام
2. جستجوی @BotFather
3. ارسال: /newbot
4. انتخاب نام: XUI Panel Manager
5. انتخاب username: xuipanel_bot (باید منحصر به فرد باشد)
6. دریافت Bot Token: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz
```

### مرحله 2: دریافت Chat ID

```
1. جستجوی @userinfobot در تلگرام
2. Start
3. نمایش ID: 123456789
```

### مرحله 3: اضافه به Config

```bash
# از Terminal:
sudo xui-panel-manager
# → Telegram bot settings

# یا از Web Panel:
# Settings → Telegram
```

### مرحله 4: تست

```bash
# از پنل وب:
Settings → Telegram → Save → Test Message

# یا دستی:
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d "chat_id=<CHAT_ID>&text=Test from XUI Panel Manager"
```

---

## 🧪 تست نصب

### 1. بررسی Services:

```bash
# Web Panel
systemctl status xui-panel-manager-web

# Sync Timer
systemctl status xui-panel-manager-sync.timer

# لیست تایمرها
systemctl list-timers | grep xui
```

### 2. تست Web Panel:

```bash
# از سرور:
curl http://localhost:8080

# از مرورگر:
http://YOUR_IP:8080
```

### 3. تست Sync دستی:

```bash
python3 /opt/xui-panel-manager/sync.py
```

### 4. بررسی لاگ‌ها:

```bash
# لاگ اپلیکیشن
tail -f /var/log/xui-panel-manager.log

# لاگ systemd
journalctl -u xui-panel-manager-web -f
journalctl -u xui-panel-manager-sync -f
```

---

## 🔧 عیب‌یابی نصب

### مشکل 1: پورت 8080 در حال استفاده

```bash
# بررسی پورت
netstat -tulpn | grep 8080

# تغییر پورت در config
nano /etc/xui-panel-manager/config.json
# تغییر "port": 8080 به پورت دیگر

# ری‌استارت
systemctl restart xui-panel-manager-web
```

### مشکل 2: خطای Python Dependencies

```bash
# نصب مجدد
pip3 install --upgrade Flask Flask-CORS requests

# یا با requirements.txt
cd /opt/xui-panel-manager
pip3 install -r requirements.txt --force-reinstall
```

### مشکل 3: دیتابیس پیدا نشد

```bash
# جستجوی دیتابیس
find / -name "x-ui.db" 2>/dev/null

# تغییر مسیر در config
nano /etc/xui-panel-manager/config.json
# تغییر "local_db_path"
```

### مشکل 4: Permission Denied

```bash
# تنظیم مجوزها
chown -R root:root /opt/xui-panel-manager
chown -R root:root /etc/xui-panel-manager
chown -R root:root /var/lib/xui-panel-manager
chmod -R 755 /opt/xui-panel-manager
chmod 600 /etc/xui-panel-manager/id_ed25519
chmod 644 /etc/xui-panel-manager/*.json
```

---

## 📦 نصب روی چند سرور

اگر می‌خواهید **روی هر سرور** نصب کنید (نه فقط یک سرور مرکزی):

```bash
# روی هر سرور:
1. نصب XUI Panel Manager
2. همه سرورهای دیگر را به آن اضافه کنید
3. کلیدهای SSH را مبادله کنید

# نتیجه:
- هر سرور می‌تواند sync را trigger کند
- Backup روی هر سرور ذخیره می‌شود
- High Availability
```

---

## ♻️ آپدیت نسخه

```bash
# دانلود نسخه جدید
cd /tmp
wget https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-panel-manager-installer.sh
chmod +x xui-panel-manager-installer.sh

# توقف services
systemctl stop xui-panel-manager-web
systemctl stop xui-panel-manager-sync.timer

# بکاپ config
cp -r /etc/xui-panel-manager /root/xui-panel-manager-backup

# اجرای نصب (config حفظ می‌شود)
./xui-panel-manager-installer.sh

# شروع services
systemctl start xui-panel-manager-web
systemctl start xui-panel-manager-sync.timer
```

---

## 🗑️ حذف کامل

```bash
# توقف و غیرفعال‌سازی
systemctl stop xui-panel-manager-web
systemctl stop xui-panel-manager-sync.timer
systemctl disable xui-panel-manager-web
systemctl disable xui-panel-manager-sync.timer

# حذف فایل‌ها
rm -rf /opt/xui-panel-manager
rm -rf /var/lib/xui-panel-manager
rm /usr/local/bin/xui-panel-manager
rm /etc/systemd/system/xui-panel-manager-*
systemctl daemon-reload

# حذف config (اختیاری)
rm -rf /etc/xui-panel-manager

# حذف لاگ
rm /var/log/xui-panel-manager.log
```

---

## ✅ چک‌لیست نصب

### قبل از نصب:
- [ ] سرور Ubuntu 20.04+ آماده است
- [ ] X-UI نصب و در حال اجرا است
- [ ] دسترسی root یا sudo دارید
- [ ] پورت 8080 آزاد است

### در حین نصب:
- [ ] اسکریپت بدون خطا اجرا شد
- [ ] زبان انتخاب شد
- [ ] بازه sync تنظیم شد
- [ ] پورت پنل تنظیم شد

### بعد از نصب:
- [ ] کلید SSH کپی شد
- [ ] پنل وب باز می‌شود
- [ ] لاگین موفق بود
- [ ] رمز تغییر کرد
- [ ] Firewall تنظیم شد

### راه‌اندازی:
- [ ] سرورها اضافه شدند
- [ ] SSH به سرورها کار می‌کند
- [ ] پکیج‌ها تعریف شدند
- [ ] تلگرام تنظیم شد (اختیاری)
- [ ] Sync دستی تست شد
- [ ] Timer فعال است

---

## 📞 دریافت کمک

### لاگ‌ها:
```bash
# جمع‌آوری اطلاعات برای پشتیبانی
cat /var/log/xui-panel-manager.log > /tmp/logs.txt
journalctl -u xui-panel-manager-web -n 100 >> /tmp/logs.txt
journalctl -u xui-panel-manager-sync -n 100 >> /tmp/logs.txt
systemctl status xui-panel-manager-* >> /tmp/logs.txt

# ارسال /tmp/logs.txt
```

### اطلاعات سیستم:
```bash
# نسخه OS
cat /etc/os-release

# نسخه Python
python3 --version

# وضعیت Services
systemctl status xui-panel-manager-*
```

---

**✅ نصب شما complete است! به `QUICKSTART.md` بروید برای شروع استفاده.**
