# XUI Multi-Server Sync

همگام‌سازی هوشمند چندین پنل X-UI / 3X-UI با الگوریتم Delta-Based

> **[English](#english) | [فارسی](#فارسی)**

---

<a name="english"></a>
## English

Smart multi-panel sync for X-UI / 3X-UI using a Delta-Based algorithm.

### Quick Install

Run only on your **Master server**:

```bash
wget -O xuisync.sh https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-multi-sync-installer.sh && chmod +x xuisync.sh && sudo ./xuisync.sh
```

After install, manage from anywhere with `sudo xuisync`.

### Features

| | |
|---|---|
| **Master Authority** | expiry, total and enable are enforced from Master only |
| **Delta Traffic** | Real usage is aggregated across all servers |
| **Full Client Sync** | New users with full UUID are pushed to all servers |
| **Reset Detection** | Traffic reset on Master propagates to all servers |
| **Auto-Detect** | Remote DB path and service are detected automatically |
| **Systemd Timer** | Periodic auto-sync with configurable interval |

### Setup

**1. Install** — Run the command above on Master. Language, sync interval (default 60 min) and SSH key are configured automatically.

**2. Copy SSH Key** — After install, the public key is displayed. On each Remote server:

```bash
echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
```

**3. Add Server** — `sudo xuisync` → option 3. Only IP and SSH port are required.

### Management Menu

```
sudo xuisync

  1) System status      5) Change sync interval
  2) List servers       6) Enable/disable timer
  3) Add server         7) Manual sync
  4) Remove server      8) View logs
  U) Uninstall          0) Exit
```

### Sync Logic

```
final_up = master_up + Σ(delta_up of each remote)
```

- **expiry / total / enable** — Master only
- **up / down** — Real sum across all servers
- **Reset** — If Master traffic decreases, all servers are reset
- **Offline server** — Logged, sync continues with remaining servers

### Quick Troubleshooting

```bash
tail -f /var/log/xui-multi-sync.log
ssh -i /etc/xui-multi-sync/id_ed25519 root@SERVER_IP
systemctl status xui-multi-sync.timer
```

DB locked: Script retries up to 8 times and restarts the service if needed.

### Requirements

- Ubuntu 20.04+ / Debian 10+
- root access on Master
- X-UI or 3X-UI installed on all servers
- SSH access from Master to all Remotes

### License

MIT

### Support

If this tool was useful, consider supporting via USDT (ERC20 / BEP20):

```
0x31835120E726de2EdFE5524EC282271468201D03
```

---

<a name="فارسی"></a>
## فارسی

همگام‌سازی هوشمند چندین پنل X-UI / 3X-UI با الگوریتم Delta-Based

### نصب سریع

فقط روی **سرور Master** اجرا کنید:

```bash
wget -O xuisync.sh https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-multi-sync-installer.sh && chmod +x xuisync.sh && sudo ./xuisync.sh
```

پس از نصب، مدیریت از هر جایی با `sudo xuisync`.

---

### ویژگی‌ها

| | |
|---|---|
| **Master Authority** | مقادیر expiry، total و enable فقط از Master اعمال می‌شوند |
| **Delta Traffic** | مصرف واقعی همه سرورها تجمیع می‌شود |
| **Full Client Sync** | کاربران جدید با UUID کامل به همه سرورها منتقل می‌شوند |
| **Reset Detection** | صفرسازی روی Master به همه سرورها اعمال می‌شود |
| **Auto-Detect** | مسیر دیتابیس و سرویس سرور Remote خودکار شناسایی می‌شود |
| **Systemd Timer** | اجرای دوره‌ای خودکار با قابلیت تنظیم بازه زمانی |

---

### راه‌اندازی

**۱. نصب** — اسکریپت بالا را روی Master اجرا کنید. زبان، بازه زمانی (پیش‌فرض ۶۰ دقیقه) و SSH key به صورت خودکار تنظیم می‌شوند.

**۲. کپی SSH Key** — پس از نصب، کلید عمومی نمایش داده می‌شود. روی هر سرور Remote:

```bash
echo "ssh-ed25519 AAAA..." >> ~/.ssh/authorized_keys
```

**۳. افزودن سرور** — `sudo xuisync` → گزینه ۳. فقط IP و پورت SSH کافی است.

---

### منوی مدیریت

```
sudo xuisync

  1) وضعیت سیستم       5) تغییر بازه زمانی
  2) لیست سرورها        6) فعال/غیرفعال تایمر
  3) اضافه کردن سرور    7) اجرای دستی sync
  4) حذف سرور           8) نمایش لاگ‌ها
  U) حذف سیستم          0) خروج
```

---

### منطق Sync

ترافیک روی Master به صورت زیر محاسبه می‌شود:

```
final_up = master_up + Σ(delta_up of each remote)
```

- **expiry / total / enable** — فقط از Master
- **up / down** — مصرف واقعی جمع همه سرورها
- **Reset** — اگر مصرف Master کاهش یابد، همه سرورها reset می‌شوند
- **Offline server** — لاگ می‌شود، sync بقیه ادامه می‌یابد

---

### عیب‌یابی سریع

```bash
# لاگ زنده
tail -f /var/log/xui-multi-sync.log

# تست SSH دستی
ssh -i /etc/xui-multi-sync/id_ed25519 root@SERVER_IP

# وضعیت تایمر
systemctl status xui-multi-sync.timer
```

دیتابیس قفل: اسکریپت تا ۸ بار retry می‌کند و در صورت نیاز سرویس را موقتاً restart می‌کند.

---

### پیش‌نیازها

- Ubuntu 20.04+ / Debian 10+
- دسترسی root روی Master
- X-UI یا 3X-UI نصب‌شده روی همه سرورها
- دسترسی SSH از Master به Remote‌ها

---

### لایسنس

MIT

---

### حمایت از پروژه

اگر این ابزار برایتان مفید بود، با ارسال USDT (ERC20 / BEP20) حمایت کنید:

```
0x31835120E726de2EdFE5524EC282271468201D03
```
