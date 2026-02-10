# 🚀 راهنمای دپلوی (Production Deployment Guide)

این راهنما شما را در دپلوی XUI Panel Manager روی سرورهای production راهنمایی می‌کند.

---

## 📋 چک‌لیست قبل از دپلوی

### الزامات سرور:
- [ ] Ubuntu 20.04 یا 22.04 LTS نصب شده
- [ ] دسترسی root یا sudo
- [ ] حداقل 1GB RAM
- [ ] حداقل 2GB فضای دیسک خالی
- [ ] اتصال اینترنت پایدار

### الزامات شبکه:
- [ ] پورت 22 (SSH) باز است
- [ ] پورت 8080 (یا پورت دلخواه) در دسترس است
- [ ] فایروال پیکربندی شده
- [ ] دسترسی SSH به سرورهای remote موجود است

### الزامات X-UI:
- [ ] X-UI یا 3X-UI نصب و اجرا شده
- [ ] دیتابیس قابل دسترسی است (`/etc/x-ui/x-ui.db`)
- [ ] نام سرویس مشخص است (`x-ui`)

---

## 🔐 امنیت قبل از دپلوی

### 1. تنظیمات SSH

```bash
# ویرایش تنظیمات SSH
sudo nano /etc/ssh/sshd_config

# تغییرات پیشنهادی:
PermitRootLogin prohibit-password  # غیرفعال کردن لاگین root با پسورد
PasswordAuthentication no          # غیرفعال کردن احراز هویت با پسورد
PubkeyAuthentication yes           # فعال کردن احراز هویت با کلید
Port 2222                          # تغییر پورت SSH (اختیاری)

# ری‌استارت SSH
sudo systemctl restart sshd
```

### 2. فایروال

```bash
# نصب UFW (اگر نصب نیست)
sudo apt-get install -y ufw

# قوانین پایه
sudo ufw default deny incoming
sudo ufw default allow outgoing

# مجوز SSH (مهم: قبل از enable!)
sudo ufw allow 22/tcp    # یا پورت SSH خود

# مجوز X-UI
sudo ufw allow 2053/tcp  # پورت X-UI خود

# مجوز پنل مدیریت (محدود به IP خاص)
sudo ufw allow from YOUR_OFFICE_IP to any port 8080

# فعال‌سازی
sudo ufw enable

# بررسی
sudo ufw status verbose
```

### 3. Fail2Ban (محافظت در برابر حملات Brute Force)

```bash
# نصب
sudo apt-get install -y fail2ban

# پیکربندی برای SSH
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
sudo nano /etc/fail2ban/jail.local

# اضافه کردن:
[sshd]
enabled = true
port = 22
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# شروع
sudo systemctl start fail2ban
sudo systemctl enable fail2ban
```

---

## 📦 روش‌های دپلوی

### روش 1: دپلوی سریع (توصیه شده)

```bash
# SSH به سرور
ssh root@YOUR_SERVER_IP

# دانلود و اجرا
wget https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-panel-manager-installer.sh
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh

# انتخاب زبان (English/Persian)
# پیروی از دستورالعمل‌های روی صفحه
```

### روش 2: دپلوی با Git

```bash
# نصب Git
sudo apt-get install -y git

# کلون repository
git clone https://github.com/sepehringo/xui-panel-manager.git
cd xui-panel-manager

# اجرای نصب
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

### روش 3: دپلوی خودکار (CI/CD)

```bash
# در سرور CI/CD خود:
# مثال: GitHub Actions، GitLab CI، Jenkins

# فایل .github/workflows/deploy.yml:
name: Deploy to Production

on:
  push:
    branches: [ main ]
    tags: [ 'v*' ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to server
        uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SERVER_HOST }}
          username: ${{ secrets.SERVER_USER }}
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/xui-panel-manager
            git pull origin main
            sudo systemctl restart xui-panel-manager-web
            sudo systemctl restart xui-panel-manager-sync.timer
```

---

## ⚙️ پیکربندی Production

### 1. تغییر رمز عبور پیش‌فرض

```bash
# روش 1: از پنل وب
# Login → Settings → Change Password

# روش 2: دستی
python3 -c "import hashlib; print(hashlib.sha256('YOUR_NEW_PASSWORD'.encode()).hexdigest())"

# کپی hash و ویرایش فایل
sudo nano /etc/xui-panel-manager/users.json
# جایگزین "password" با hash جدید
```

### 2. تنظیم Secret Key

```bash
# Generate random secret key
python3 -c "import secrets; print(secrets.token_hex(32))"

# ویرایش config
sudo nano /etc/xui-panel-manager/config.json

# تغییر این خط:
"secret_key": "GENERATED_RANDOM_KEY_HERE"
```

### 3. محدود کردن Host

```bash
# برای امنیت بیشتر، فقط به localhost bind کنید
sudo nano /etc/xui-panel-manager/config.json

# تغییر:
"host": "127.0.0.1"  # به جای "0.0.0.0"

# سپس از nginx به عنوان reverse proxy استفاده کنید
```

### 4. پیکربندی HTTPS با Nginx

```bash
# نصب nginx و certbot
sudo apt-get install -y nginx certbot python3-certbot-nginx

# ایجاد config nginx
sudo nano /etc/nginx/sites-available/xui-panel-manager

# محتوا:
server {
    listen 80;
    server_name panel.yourdomain.com;

    location / {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}

# فعال‌سازی
sudo ln -s /etc/nginx/sites-available/xui-panel-manager /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# دریافت SSL certificate
sudo certbot --nginx -d panel.yourdomain.com

# Auto-renewal
sudo systemctl enable certbot.timer
```

---

## 🔧 بهینه‌سازی Production

### 1. تنظیم Python WSGI Server

```bash
# نصب gunicorn
pip3 install gunicorn

# ویرایش systemd service
sudo nano /etc/systemd/system/xui-panel-manager-web.service

# تغییر ExecStart به:
ExecStart=/usr/local/bin/gunicorn --workers 4 \
    --bind 127.0.0.1:8080 \
    --timeout 120 \
    --access-logfile /var/log/xui-panel-manager-access.log \
    --error-logfile /var/log/xui-panel-manager-error.log \
    web_app:app

# ری‌استارت
sudo systemctl daemon-reload
sudo systemctl restart xui-panel-manager-web
```

### 2. تنظیم Log Rotation

```bash
# ایجاد config logrotate
sudo nano /etc/logrotate.d/xui-panel-manager

# محتوا:
/var/log/xui-panel-manager*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
    postrotate
        systemctl reload xui-panel-manager-web > /dev/null 2>&1 || true
    endscript
}

# تست
sudo logrotate -d /etc/logrotate.d/xui-panel-manager
```

### 3. محدودیت‌های Resource

```bash
# ویرایش systemd service
sudo systemctl edit xui-panel-manager-web

# اضافه کردن:
[Service]
MemoryLimit=512M
CPUQuota=50%
TasksMax=100

# ری‌استارت
sudo systemctl restart xui-panel-manager-web
```

---

## 📊 مانیتورینگ Production

### 1. Monitoring با systemd

```bash
# بررسی وضعیت
systemctl status xui-panel-manager-web
systemctl status xui-panel-manager-sync.timer

# مشاهده لاگ‌ها
journalctl -u xui-panel-manager-web -f
journalctl -u xui-panel-manager-sync -f

# بررسی منابع
systemd-cgtop
```

### 2. Health Check Script

```bash
# ایجاد اسکریپت health check
sudo nano /usr/local/bin/xui-health-check.sh

#!/bin/bash
# XUI Panel Manager Health Check

# بررسی سرویس web
if ! systemctl is-active --quiet xui-panel-manager-web; then
    echo "Web service is down! Restarting..."
    systemctl restart xui-panel-manager-web
fi

# بررسی پاسخ HTTP
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Web panel not responding!"
fi

# بررسی فضای دیسک
DISK_USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 90 ]; then
    echo "Disk usage is ${DISK_USAGE}%!"
fi

# اجرا خودکار هر 5 دقیقه
sudo chmod +x /usr/local/bin/xui-health-check.sh
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/xui-health-check.sh") | crontab -
```

### 3. Alerting با Telegram

```bash
# اضافه کردن به health check
TELEGRAM_BOT_TOKEN="YOUR_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_CHAT_ID"

send_alert() {
    MESSAGE="$1"
    curl -s -X POST "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage" \
        -d "chat_id=${TELEGRAM_CHAT_ID}&text=${MESSAGE}"
}

# استفاده:
send_alert "⚠️ XUI Panel Manager: Web service is down!"
```

---

## 💾 استراتژی بکاپ

### 1. بکاپ خودکار روزانه

```bash
# ایجاد اسکریپت بکاپ
sudo nano /usr/local/bin/xui-backup.sh

#!/bin/bash
BACKUP_DIR="/var/backups/xui-panel-manager"
DATE=$(date +%Y%m%d-%H%M%S)

# ایجاد دایرکتوری
mkdir -p $BACKUP_DIR

# بکاپ config
tar -czf $BACKUP_DIR/config-$DATE.tar.gz /etc/xui-panel-manager

# بکاپ database
cp /etc/x-ui/x-ui.db $BACKUP_DIR/x-ui-$DATE.db

# بکاپ logs (اختیاری)
tar -czf $BACKUP_DIR/logs-$DATE.tar.gz /var/log/xui-panel-manager*.log

# حذف بکاپ‌های قدیمی‌تر از 30 روز
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete
find $BACKUP_DIR -name "*.db" -mtime +30 -delete

echo "Backup completed: $DATE"

# اجرا خودکار شبانه
sudo chmod +x /usr/local/bin/xui-backup.sh
(crontab -l 2>/dev/null; echo "0 2 * * * /usr/local/bin/xui-backup.sh") | crontab -
```

### 2. بکاپ به سرور Remote

```bash
# استفاده از rsync
BACKUP_SERVER="backup@backup.example.com"
rsync -avz --delete /var/backups/xui-panel-manager/ $BACKUP_SERVER:/backups/xui-panel-manager/

# یا استفاده از rclone برای cloud storage
rclone sync /var/backups/xui-panel-manager/ remote:xui-backups
```

---

## 🔄 آپدیت و Rollback

### آپدیت به نسخه جدید

```bash
# بکاپ قبل از آپدیت
sudo /usr/local/bin/xui-backup.sh

# دانلود نسخه جدید
cd /tmp
wget https://github.com/sepehringo/xui-panel-manager/archive/refs/tags/v1.1.0.tar.gz
tar -xzf v1.1.0.tar.gz

# توقف سرویس‌ها
sudo systemctl stop xui-panel-manager-web
sudo systemctl stop xui-panel-manager-sync.timer

# جایگزینی فایل‌ها
sudo cp xui-panel-manager-1.1.0/web_app.py /opt/xui-panel-manager/
sudo cp -r xui-panel-manager-1.1.0/templates/* /opt/xui-panel-manager/templates/

# آپدیت dependencies
pip3 install -r xui-panel-manager-1.1.0/requirements.txt --upgrade

# شروع سرویس‌ها
sudo systemctl start xui-panel-manager-web
sudo systemctl start xui-panel-manager-sync.timer

# بررسی
sudo systemctl status xui-panel-manager-web
curl http://localhost:8080
```

### Rollback به نسخه قبلی

```bash
# Restore از بکاپ
BACKUP_DATE="20240115-020000"  # تاریخ بکاپ

sudo systemctl stop xui-panel-manager-web
sudo systemctl stop xui-panel-manager-sync.timer

# Restore config
sudo tar -xzf /var/backups/xui-panel-manager/config-$BACKUP_DATE.tar.gz -C /

# Restore database
sudo cp /var/backups/xui-panel-manager/x-ui-$BACKUP_DATE.db /etc/x-ui/x-ui.db

sudo systemctl start xui-panel-manager-web
sudo systemctl start xui-panel-manager-sync.timer
```

---

## 🐛 عیب‌یابی Production

### مشکلات رایج

#### 1. سرویس استارت نمی‌شود

```bash
# بررسی لاگ‌ها
journalctl -u xui-panel-manager-web -n 50

# بررسی syntax errors
python3 /opt/xui-panel-manager/web_app.py

# بررسی permissions
ls -la /opt/xui-panel-manager/
ls -la /etc/xui-panel-manager/

# اصلاح permissions
sudo chown -R root:root /opt/xui-panel-manager
sudo chmod 644 /opt/xui-panel-manager/*.py
```

#### 2. Performance Issues

```bash
# بررسی منابع
top
htop  # نصب: apt-get install htop

# بررسی connections
netstat -tulpn | grep 8080

# بررسی database size
du -sh /etc/x-ui/x-ui.db

# Optimize database
sqlite3 /etc/x-ui/x-ui.db "VACUUM;"
```

#### 3. Sync Failures

```bash
# تست SSH connection
ssh -i /etc/xui-panel-manager/id_ed25519 root@REMOTE_SERVER

# بررسی لاگ sync
journalctl -u xui-panel-manager-sync -n 100

# اجرای دستی با debug
python3 /opt/xui-panel-manager/sync.py
```

---

## 📈 Scaling

### Multi-Server Setup (High Availability)

```bash
# نصب روی چندین سرور
# هر سرور می‌تواند به عنوان master عمل کند

# سرور 1:
# نصب و اضافه کردن سرورهای 2,3,4

# سرور 2:
# نصب و اضافه کردن سرورهای 1,3,4

# استفاده از Load Balancer (nginx):
upstream xui_backends {
    server 10.0.0.1:8080;
    server 10.0.0.2:8080;
    server 10.0.0.3:8080;
}

server {
    listen 80;
    server_name panel.yourdomain.com;
    
    location / {
        proxy_pass http://xui_backends;
    }
}
```

---

## ✅ چک‌لیست بعد از دپلوی

- [ ] سرویس‌ها اجرا می‌شوند
- [ ] پنل وب قابل دسترسی است
- [ ] رمز پیش‌فرض تغییر کرد
- [ ] Secret key تغییر کرد
- [ ] فایروال تنظیم شد
- [ ] HTTPS پیکربندی شد (اگر نیاز بود)
- [ ] Fail2Ban نصب و فعال است
- [ ] بکاپ خودکار تنظیم شد
- [ ] Health check نصب شد
- [ ] Monitoring فعال است
- [ ] Log rotation تنظیم شد
- [ ] تلگرام تنظیم شد (اختیاری)
- [ ] سرورها اضافه شدند
- [ ] SSH keys توزیع شدند
- [ ] Sync دستی تست شد
- [ ] مستندات به تیم داده شد

---

## 📞 پشتیبانی Production

### در صورت بروز مشکل:

1. **بررسی لاگ‌ها**:
   ```bash
   sudo journalctl -u xui-panel-manager-web -n 100
   sudo tail -f /var/log/xui-panel-manager.log
   ```

2. **جمع‌آوری اطلاعات**:
   ```bash
   # System info
   uname -a
   cat /etc/os-release
   python3 --version
   
   # Service status
   systemctl status xui-panel-manager-*
   
   # Network
   netstat -tulpn | grep 8080
   curl -v http://localhost:8080
   ```

3. **تماس با پشتیبانی**:
   - Issues: GitHub Issues
   - Email: support@example.com
   - Telegram: @support_channel

---

**🎉 دپلوی شما کامل شد! به QUICKSTART.md مراجعه کنید برای استفاده.**
