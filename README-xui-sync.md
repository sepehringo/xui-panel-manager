# XUI Multi-Server Sync

اسکریپت هماهنگ‌سازی خودکار بین چندین پنل X-UI/3X-UI

## ویژگی‌ها

✅ **مقایسه همه سرورها**: تمام دیتابیس‌های سرورها را با هم مقایسه می‌کند  
✅ **ماکزیمم ترافیک**: بیشترین مقدار مصرف (up/down) را از بین همه سرورها انتخاب می‌کند  
✅ **مینیمم روزهای باقی‌مانده**: کمترین expiry_time را در نظر می‌گیرد  
✅ **همگام‌سازی کامل**: تمام مقادیر را در همه سرورها یکسان می‌کند  
✅ **مدیریت آسان**: منوی تعاملی برای اضافه/حذف سرور و تغییر تایمینگ  
✅ **اجرای خودکار**: با systemd timer به صورت دوره‌ای اجرا می‌شود  

## نحوه نصب

### روش 1: نصب مستقیم

```bash
# دانلود اسکریپت
wget https://raw.githubusercontent.com/YOUR_REPO/xui-multi-sync-installer.sh

# اجرای نصب
chmod +x xui-multi-sync-installer.sh
sudo ./xui-multi-sync-installer.sh
```

### روش 2: نصب با curl

```bash
curl -o xui-multi-sync-installer.sh https://raw.githubusercontent.com/YOUR_REPO/xui-multi-sync-installer.sh
chmod +x xui-multi-sync-installer.sh
sudo ./xui-multi-sync-installer.sh
```

### روش 3: نصب مستقیم (یک خطی)

```bash
bash <(curl -Ls https://raw.githubusercontent.com/YOUR_REPO/xui-multi-sync-installer.sh)
```

## راه‌اندازی اولیه

1. **نصب بر روی یک سرور (اصلی)**
   ```bash
   sudo ./xui-multi-sync-installer.sh
   ```

2. **کپی کلید SSH**
   
   پس از نصب، کلید عمومی SSH نمایش داده می‌شود. این کلید را روی **همه سرورهای دیگر** کپی کنید:

   ```bash
   # روی هر سرور دیگر:
   echo "ssh-ed25519 AAAA... xui-multi-sync" >> ~/.ssh/authorized_keys
   chmod 600 ~/.ssh/authorized_keys
   ```

   یا از طریق ssh-copy-id:
   ```bash
   ssh-copy-id -i /etc/xui-multi-sync/id_ed25519.pub root@SERVER_IP
   ```

3. **اضافه کردن سرورها**
   
   از منوی اصلی گزینه "اضافه کردن سرور" را انتخاب کنید و اطلاعات هر سرور را وارد نمایید:
   - نام سرور (مثلاً: Server-DE، Server-US)
   - آدرس IP
   - پورت SSH (پیش‌فرض: 22)
   - نام کاربری (پیش‌فرض: root)
   - مسیر دیتابیس (پیش‌فرض: /etc/x-ui/x-ui.db)
   - نام سرویس (پیش‌فرض: x-ui)

## استفاده

بعد از نصب، برای مدیریت سیستم از دستور زیر استفاده کنید:

```bash
sudo xui-multi-sync
```

### منوی اصلی

```
╔═══════════════════════════════════════╗
║   XUI Multi-Server Sync Manager      ║
║   مدیریت همگام‌سازی چند-سرور        ║
╚═══════════════════════════════════════╝

1) نمایش وضعیت سیستم
2) لیست سرورها
3) اضافه کردن سرور
4) حذف سرور
5) تغییر بازه زمانی
6) فعال/غیرفعال کردن تایمر خودکار
7) اجرای دستی همگام‌سازی (الان)
8) نمایش لاگ‌ها
9) خروج
```

## نحوه کار

### منطق همگام‌سازی

برای هر کلاینت (email)، سیستم:

1. **جمع‌آوری داده** از همه سرورها
2. **مقایسه** و انتخاب بهترین مقادیر:
   - `up` & `down`: **حداکثر** (بیشترین مصرف)
   - `total`: **حداکثر** (بیشترین کوتا)
   - `expiry_time`: **حداقل** (کمترین روز باقی‌مانده)
   - `enable`: **حداقل** (اگر روی یک پنل غیرفعال باشد، همه جا غیرفعال می‌شود)
3. **اعمال** مقادیر یکسان به **همه سرورها**

### مثال

فرض کنید 3 سرور دارید:

| سرور | Email | Up (GB) | Down (GB) | Expiry Days | Total (GB) |
|------|-------|---------|-----------|-------------|------------|
| S1   | user@example.com | 5 | 10 | 15 | 50 |
| S2   | user@example.com | 8 | 7  | 20 | 50 |
| S3   | user@example.com | 3 | 12 | 10 | 60 |

**نتیجه همگام‌سازی** (اعمال به همه):
- Up: **8 GB** (max)
- Down: **12 GB** (max)
- Expiry: **10 روز** (min - کمترین زمان باقی‌مانده)
- Total: **60 GB** (max)

## پیکربندی

### فایل‌های پیکربندی

```
/etc/xui-multi-sync/
├── config.json         # تنظیمات اصلی
├── servers.json        # لیست سرورها
└── id_ed25519         # کلید SSH
```

### config.json

```json
{
  "local_db_path": "/etc/x-ui/x-ui.db",
  "local_service_name": "x-ui",
  "sync_interval_minutes": 60
}
```

### servers.json

```json
{
  "servers": [
    {
      "name": "Server-DE",
      "host": "192.168.1.100",
      "port": 22,
      "user": "root",
      "db_path": "/etc/x-ui/x-ui.db",
      "service_name": "x-ui",
      "ssh_key": "/etc/xui-multi-sync/id_ed25519"
    },
    {
      "name": "Server-US",
      "host": "192.168.1.101",
      "port": 22,
      "user": "root",
      "db_path": "/etc/x-ui/x-ui.db",
      "service_name": "x-ui",
      "ssh_key": "/etc/xui-multi-sync/id_ed25519"
    }
  ]
}
```

## دستورات مفید

### نمایش وضعیت تایمر

```bash
systemctl status xui-multi-sync.timer
```

### نمایش لاگ‌های اخیر

```bash
journalctl -u xui-multi-sync.service -f
```

یا:

```bash
tail -f /var/log/xui-multi-sync.log
```

### اجرای دستی

```bash
sudo python3 /opt/xui-multi-sync/sync.py
```

### غیرفعال کردن موقت

```bash
sudo systemctl stop xui-multi-sync.timer
```

### فعال کردن مجدد

```bash
sudo systemctl start xui-multi-sync.timer
```

### حذف کامل

```bash
sudo systemctl disable --now xui-multi-sync.timer
sudo rm -rf /opt/xui-multi-sync /etc/xui-multi-sync /var/lib/xui-multi-sync
sudo rm /usr/local/bin/xui-multi-sync
sudo rm /etc/systemd/system/xui-multi-sync.*
sudo systemctl daemon-reload
```

## عیب‌یابی

### مشکل SSH

اگر خطای SSH دریافت کردید:

1. مطمئن شوید کلید عمومی روی سرور مقصد کپی شده
2. تست دستی SSH:
   ```bash
   ssh -i /etc/xui-multi-sync/id_ed25519 root@SERVER_IP
   ```

### مشکل Database Locked

اگر دیتابیس قفل شد، اسکریپت به صورت خودکار:
1. چندین بار retry می‌کند
2. در صورت نیاز، سرویس را موقتاً متوقف می‌کند

### بررسی خطاها

```bash
# لاگ‌های systemd
journalctl -u xui-multi-sync.service -n 50

# لاگ‌های اپلیکیشن
cat /var/log/xui-multi-sync.log
```

## نکات امنیتی

⚠️ **توجه**: این اسکریپت به SSH key-based authentication نیاز دارد  
⚠️ کلید خصوصی را محافظت کنید (فقط root باید دسترسی داشته باشد)  
⚠️ از فایروال برای محدود کردن دسترسی SSH استفاده کنید  
⚠️ اتصالات SSH را با StrictHostKeyChecking در تنظیمات production محدود کنید  

## سناریوهای کاربردی

### 1. چند پنل مجزا با یک اشتراک

شما 3 پنل جداگانه در کشورهای مختلف دارید و می‌خواهید کاربران بتوانند با یک اکانت از همه استفاده کنند:

```
Panel-DE (Germany) ──┐
Panel-US (USA)      ──┼── Sync → همه به‌روز می‌شوند
Panel-SG (Asia)     ──┘
```

### 2. High Availability Setup

اگر یک سرور down شود، کاربر می‌تواند به سرور دیگر متصل شود و با همان account ادامه دهد.

### 3. Load Balancing Manual

توزیع کاربران بین چند سرور با sync خودکار ترافیک مصرفی.

## سؤالات متداول

**Q: آیا باید روی همه سرورها نصب شود؟**  
A: خیر! فقط روی یک سرور نصب کنید و آدرس سرورهای دیگر را اضافه کنید.

**Q: چه اتفاقی می‌افتد اگر یک سرور offline باشد؟**  
A: اسکریپت خطا را log می‌کند و با سرورهای دیگر ادامه می‌دهد.

**Q: آیا کاربران جدید هم sync می‌شوند؟**  
A: بله، ولی فقط کاربرانی که در دیتابیس موجود هستند. کاربران جدید باید به صورت دستی در همه پنل‌ها ایجاد شوند.

**Q: آیا پسوردها و تنظیمات Inbound sync می‌شوند؟**  
A: خیر، فقط ترافیک و expiry sync می‌شود. برای sync کامل یوزرها باید از راه حل‌های دیگر استفاده کنید.

## لایسنس

MIT License - استفاده، تغییر و توزیع آزاد است.

## پشتیبانی

در صورت بروز مشکل:
1. لاگ‌ها را بررسی کنید
2. SSH connection را تست کنید
3. دسترسی‌های filesystem و database را چک کنید

---

**توسعه‌دهنده**: XUI Multi-Server Sync Team  
**نسخه**: 1.0.0
