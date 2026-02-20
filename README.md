# XUI Multi-Server Sync

همگام‌سازی هوشمند چندین پنل X-UI / 3X-UI با الگوریتم Delta-Based

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-orange.svg)]()
[![Python](https://img.shields.io/badge/Python-3.8%2B-green.svg)]()

---

## ویژگی‌ها

| ویژگی | توضیح |
|-------|-------|
| **Master-Only Authority** | سرور اصلی منبع حقیقت است — expiry، total و enable فقط از Master می‌آیند |
| **Delta-Based Traffic** | مصرف واقعی همه سرورها جمع می‌شود، نه صرفاً بیشترین مقدار |
| **Full Client Sync** | اکانت‌های جدید با UUID، پسورد و تنظیمات کامل Inbound به همه سرورها منتقل می‌شوند |
| **Reset Detection** | اگر admin ترافیک را روی Master صفر کند، روی تمام سرورها هم اعمال می‌شود |
| **Parallel Fetch** | دریافت همزمان اطلاعات از همه سرورها (threading) |
| **Auto-Detect** | سرویس و مسیر دیتابیس سرور جدید به صورت خودکار شناسایی می‌شود |
| **Auto Timer** | با systemd timer به صورت دوره‌ای اجرا می‌شود |
| **دو زبانه** | فارسی و انگلیسی |

---

## نصب سریع

فقط روی **سرور Master** نصب کنید:

```bash
wget -O xuisync.sh https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-multi-sync-installer.sh
chmod +x xuisync.sh
sudo ./xuisync.sh
```

پس از نصب، از هر جایی با دستور `sudo xuisync` اجرا کنید.

---

## معماری سیستم

```
┌─────────────────────────────────────────────────┐
│                  Master Server                  │
│          (این سرور اسکریپت نصب است)             │
│                                                 │
│  sync.py ──┬── SSH ──▶ Server-1 (read + write)  │
│            ├── SSH ──▶ Server-2 (read + write)  │
│            └── SSH ──▶ Server-N (read + write)  │
└─────────────────────────────────────────────────┘
```

- نصب فقط روی **یک سرور** (Master)
- Master از طریق SSH به بقیه سرورها وصل می‌شود
- هیچ چیزی روی سرورهای دیگر نصب نمی‌شود

---

## منطق همگام‌سازی

### قوانین sync

| فیلد | منبع | دلیل |
|------|------|------|
| `up` / `down` | Master فعلی + جمع delta‌های Remote | مصرف واقعی همه سرورها |
| `expiry_time` | فقط Master | ادمین روی Master تمدید می‌کند |
| `total` | فقط Master | حجم کوتا روی Master تنظیم می‌شود |
| `enable` | فقط Master | غیرفعال کردن فقط از Master اعمال می‌شود |

### مثال عملی

فرض کنید Master + 2 سرور دیگر دارید:

**Snapshot قبلی (آخرین sync):**
```
Master:   user@vpn.com → up: 5 GB, down: 10 GB
Server-1: user@vpn.com → up: 5 GB, down: 10 GB
Server-2: user@vpn.com → up: 5 GB, down: 10 GB
```

**مصرف جدید تا این لحظه:**
```
Master:   up: 7 GB  (+2)   down: 13 GB (+3)
Server-1: up: 8 GB  (+3)   down: 12 GB (+2)
Server-2: up: 6 GB  (+1)   down: 17 GB (+7)
```

**محاسبه:**
```
delta_up   = remote_1(+3) + remote_2(+1)  = +4 GB
delta_down = remote_1(+2) + remote_2(+7)  = +9 GB

نتیجه نهایی:
  up   = 7 + 4 = 11 GB
  down = 13 + 9 = 22 GB
```

> ⚠️ دلتای Master **دیگر اضافه نمی‌شود** چون مقدار `up=7` و `down=13` قبلاً مصرف Master را در خود دارد.

---

### تشخیص Reset

اگر admin روی Master ترافیک کاربری را صفر کند:

```
Snapshot: up=10 GB, down=20 GB
Master فعلی: up=0, down=0  ← کاهش → Reset تشخیص داده شد
```

**نتیجه:** همه سرورها به مقادیر فعلی Master ست می‌شوند (صفر).  
این مکانیزم با اشتباه فرق دارد — فقط وقتی **Master** کاهش داشته باشد اعمال می‌شود.

---

### اضافه شدن اکانت جدید

وقتی کاربر جدیدی روی Master اضافه می‌شود:

1. UUID و تنظیمات کامل از جدول `inbounds` خوانده می‌شود
2. inbound متناظر روی هر Remote با `tag` پیدا می‌شود
3. کاربر به `settings.clients` اضافه می‌شود
4. ردیف `client_traffics` با `inbound_id` درست insert می‌شود

کاربر روی تمام سرورها **واقعاً** کار می‌کند، نه فقط یک ردیف آماری.

---

## راه‌اندازی

### ۱. نصب

```bash
sudo ./xuisync.sh
```

مراحل نصب:
- انتخاب زبان (فارسی / English)
- نصب وابستگی‌ها (`python3`, `sqlite3`, `jq`, `openssh-client`)
- ساخت SSH key اختصاصی
- تنظیم بازه زمانی sync (پیش‌فرض: 60 دقیقه)
- فعال‌سازی systemd timer

### ۲. کپی کلید SSH

پس از نصب، کلید عمومی SSH نمایش داده می‌شود. این کلید را روی هر سرور Remote اجرا کنید:

```bash
# روی هر سرور Remote:
echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### ۳. اضافه کردن سرور

```bash
sudo xuisync
# گزینه 3 → Add Server
```

فقط نام، IP و پورت SSH می‌خواهد. **سرویس و مسیر دیتابیس به صورت خودکار شناسایی می‌شوند.**

اگر SSH key کپی نشده باشد، یک تست اتصال انجام می‌دهد و در صورت خطا دلیل دقیق را نشان می‌دهد.

---

## منوی مدیریت

```bash
sudo xuisync
```

```
╔═══════════════════════════════════════╗
║   XUI Multi-Server Sync Manager      ║
╚═══════════════════════════════════════╝

1) وضعیت سیستم
2) لیست سرورها
3) اضافه کردن سرور
4) حذف سرور
5) تغییر بازه زمانی
6) فعال/غیرفعال تایمر خودکار
7) اجرای دستی sync
8) نمایش لاگ‌ها
9) تغییر زبان
U) حذف سیستم
0) خروج
```

---

## فایل‌های سیستم

```
/etc/xui-multi-sync/
├── config.json        ← تنظیمات اصلی
├── servers.json       ← لیست سرورهای Remote
├── language           ← زبان انتخابی (en/fa)
└── id_ed25519         ← کلید SSH اختصاصی

/opt/xui-multi-sync/
└── sync.py            ← اسکریپت اصلی Python

/var/lib/xui-multi-sync/
└── state.json         ← Snapshot آخرین sync (خودکار)

/var/log/xui-multi-sync.log   ← لاگ‌ها
/usr/local/bin/xuisync        ← دستور سراسری
```

### config.json

```json
{
  "local_db_path": "/etc/x-ui/x-ui.db",
  "local_service_name": "x-ui",
  "sync_interval_minutes": 60,
  "is_master": true
}
```

### servers.json

```json
{
  "servers": [
    {
      "name": "Server-DE",
      "host": "1.2.3.4",
      "port": 22,
      "user": "root",
      "db_path": "/etc/x-ui/x-ui.db",
      "service_name": "x-ui",
      "ssh_key": "/etc/xui-multi-sync/id_ed25519"
    }
  ]
}
```

---

## دستورات مفید

```bash
# مدیریت سیستم
sudo xuisync

# مشاهده لاگ زنده
tail -f /var/log/xui-multi-sync.log

# اجرای دستی sync
sudo python3 /opt/xui-multi-sync/sync.py

# وضعیت تایمر
systemctl status xui-multi-sync.timer

# تایمر بعدی
systemctl list-timers | grep xui-multi-sync

# لاگ‌های systemd
journalctl -u xui-multi-sync.service -n 50 -f

# توقف موقت
sudo systemctl stop xui-multi-sync.timer

# راه‌اندازی مجدد
sudo systemctl start xui-multi-sync.timer
```

---

## عیب‌یابی

### خطای SSH

```bash
# تست دستی
ssh -i /etc/xui-multi-sync/id_ed25519 -p 22 root@SERVER_IP

# مشکل معمول: کلید کپی نشده
ssh-copy-id -i /etc/xui-multi-sync/id_ed25519.pub root@SERVER_IP
```

### دیتابیس قفل است

اسکریپت به صورت خودکار:
1. تا ۸ بار retry می‌کند
2. در صورت نیاز سرویس را موقتاً متوقف و راه‌اندازی مجدد می‌کند

### state.json پاک شد

در sync بعدی، delta از صفر حساب می‌شود — یعنی مصرف فعلی سرورها به عنوان delta اعمال می‌شود. مشکلی ایجاد نمی‌کند اما sync اول ممکن است مقادیر را کمی بالاتر ببرد.

```bash
# بک‌آپ از state
cp /var/lib/xui-multi-sync/state.json ~/state-backup.json
```

---

## سؤالات متداول

**آیا روی همه سرورها باید نصب شود؟**  
خیر. فقط روی یک سرور (Master). بقیه سرورها فقط نیاز به SSH دارند.

**اگر یک سرور offline باشد چه می‌شود؟**  
خطا لاگ می‌شود و sync با بقیه سرورها ادامه می‌یابد. در sync بعدی که آن سرور online شود، delta جدیدش محاسبه می‌شود.

**آیا می‌توانم manual sync بزنم؟**  
بله، از منو گزینه ۷ یا مستقیم:  
```bash
sudo python3 /opt/xui-multi-sync/sync.py
```

**اگر ادمین روی یک سرور Remote کاربری را disable کند چه می‌شود؟**  
در sync بعدی، چون `enable` فقط از Master می‌آید، آن سرور دوباره به وضعیت Master برمی‌گردد.

**آیا بازه زمانی را می‌توانم تغییر دهم؟**  
بله، از منو گزینه ۵ یا مستقیم در `config.json`.

---

## نکات امنیتی

- کلید خصوصی SSH باید permissions `600` داشته باشد
- Master باید به سرورهای Remote دسترسی SSH داشته باشد (یک‌طرفه)
- در محیط production از `StrictHostKeyChecking=yes` استفاده کنید
- از `config.json` و `state.json` بک‌آپ بگیرید

---

## پیش‌نیازها

- **سیستم‌عامل**: Ubuntu 20.04+ / Debian 10+
- **دسترسی**: root
- **X-UI / 3X-UI**: نصب‌شده روی همه سرورها
- **شبکه**: دسترسی SSH از Master به تمام Remote‌ها

---

## لایسنس

MIT — استفاده، تغییر و توزیع آزاد است.
