# 📁 لیست کامل فایل‌های پروژه XUI Panel Manager

## 📂 ساختار کامل دایرکتوری

```
xui-panel-manager/
├── 📄 xui-panel-manager-installer.sh    (اسکریپت نصب اصلی)
├── 📄 web_app.py                        (برنامه Flask)
├── 📄 requirements.txt                  (وابستگی‌های Python)
│
├── 📁 templates/                        (قالب‌های HTML)
│   ├── base.html
│   ├── login.html
│   ├── dashboard.html
│   ├── clients.html
│   ├── packages.html
│   ├── servers.html
│   └── settings.html
│
├── 📁 docs/                             (مستندات)
│   ├── README-panel-manager.md
│   ├── QUICKSTART.md
│   ├── INSTALLATION.md
│   ├── PROJECT_SUMMARY.md
│   └── FILE_LIST.md
│
└── 📁 examples/                         (فایل‌های نمونه - اختیاری)
    ├── config.json.example
    ├── servers.json.example
    └── packages.json.example
```

---

## 📄 توضیحات تفصیلی فایل‌ها

### 🔧 فایل‌های اصلی (Core Files)

#### 1. `xui-panel-manager-installer.sh`
- **نوع**: Bash Script
- **خطوط کد**: ~800+ lines
- **زبان**: Multi-language (Persian/English)
- **نقش**: اسکریپت نصب و مدیریت اصلی
- **امکانات**:
  - نصب خودکار با انتخاب زبان
  - تشخیص خودکار دیتابیس و سرویس X-UI
  - ایجاد SSH Key (ed25519)
  - نصب وابستگی‌های سیستم (Python3, pip, sqlite3, jq)
  - ایجاد Python Virtual Environment
  - نصب پکیج‌های Python از requirements.txt
  - ساخت ساختار دایرکتوری:
    - `/opt/xui-panel-manager/` - فایل‌های برنامه
    - `/etc/xui-panel-manager/` - تنظیمات
    - `/var/lib/xui-panel-manager/` - بکاپ‌ها
  - ایجاد فایل‌های JSON پیش‌فرض:
    - config.json (با 4 پکیج پیش‌فرض)
    - servers.json
    - packages.json
    - users.json (admin/admin123)
  - ایجاد sync.py (موتور همگام‌سازی)
  - ایجاد systemd units:
    - xui-panel-manager-sync.service
    - xui-panel-manager-sync.timer
    - xui-panel-manager-web.service
  - ایجاد symlink: `/usr/local/bin/xui-panel-manager`
- **استفاده**:
  ```bash
  chmod +x xui-panel-manager-installer.sh
  sudo ./xui-panel-manager-installer.sh
  ```

#### 2. `web_app.py`
- **نوع**: Python Flask Application
- **خطوط کد**: ~600 lines
- **زبان**: Python 3
- **نقش**: پنل مدیریت تحت وب
- **امکانات**:
  - **Authentication**: سیستم لاگین با session
  - **Routes** (15 view):
    - `/` → Redirect to dashboard
    - `/login` + `/logout`
    - `/dashboard` → صفحه اصلی با 8 آمار
    - `/clients` → مدیریت کلاینت‌ها
    - `/packages` → مدیریت پکیج‌ها
    - `/servers` → مدیریت سرورها
    - `/settings` → تنظیمات
  - **API Endpoints** (12 endpoint):
    - `GET /api/clients` → لیست کلاینت‌ها
    - `POST /api/clients/<email>` → به‌روزرسانی کلاینت
    - `POST /api/clients/<email>/apply-package` → اعمال پکیج
    - `POST /api/clients/<email>/reset` → ریست ترافیک
    - `GET /api/packages` → لیست پکیج‌ها
    - `POST /api/packages` → ایجاد پکیج
    - `DELETE /api/packages/<id>` → حذف پکیج
    - `GET /api/servers` → لیست سرورها
    - `POST /api/servers` → اضافه کردن سرور
    - `DELETE /api/servers/<index>` → حذف سرور
    - `POST /api/sync/trigger` → شروع همگام‌سازی دستی
    - `GET /api/stats` → آمار داشبورد
    - `POST /api/settings` → ذخیره تنظیمات
    - `POST /api/telegram/test` → تست تلگرام
    - `GET /api/logs` → لاگ‌های سیستم
  - **Database Operations**:
    - خواندن از SQLite (client_traffics)
    - محاسبه ترافیک (bytes → GB)
    - محاسبه درصد استفاده
    - تبدیل تاریخ (Unix timestamp → Persian/English)
  - **Sync Engine Integration**:
    - Trigger همگام‌سازی با فراخوانی sync.py
    - نمایش لاگ‌های real-time
  - **Telegram Integration**:
    - ارسال نوتیفیکیشن‌ها
    - تست ارتباط با bot
  - **Security**:
    - Session-based auth
    - Password hashing (SHA256)
    - CSRF protection (via Flask)
- **استفاده**:
  ```bash
  python3 /opt/xui-panel-manager/web_app.py
  # یا
  systemctl start xui-panel-manager-web
  ```

#### 3. `requirements.txt`
- **نوع**: Python Dependencies
- **خطوط کد**: 3 lines
- **نقش**: لیست پکیج‌های Python
- **محتوا**:
  ```
  Flask==3.0.0
  Flask-CORS==4.0.0
  requests==2.31.0
  ```
- **استفاده**:
  ```bash
  pip3 install -r requirements.txt
  ```

---

### 🎨 فایل‌های قالب (Template Files)

#### 4. `templates/base.html`
- **نوع**: HTML + CSS + JavaScript Base Template
- **خطوط کد**: ~340 lines
- **زبان**: HTML5, CSS3, JavaScript (Vanilla)
- **نقش**: قالب پایه با CSS Framework کامل
- **امکانات**:
  - **CSS Variables**: 
    - Colors: --primary, --success, --danger, --warning, --info
    - Spacing: --spacing-sm to --spacing-xl
    - Typography: --font-family, --font-sizes
  - **Components**:
    - Navbar (responsive با hamburger menu)
    - stat-card (کارت‌های آماری)
    - table (جدول‌های responsive)
    - modal (پنجره‌های مودال)
    - badge (برچسب‌های رنگی)
    - progress-bar (نوار پیشرفت)
    - alert (پیام‌های اطلاع‌رسانی)
    - button (دکمه‌ها با variants)
  - **JavaScript Utilities**:
    - `showLoading()` / `hideLoading()`
    - `showAlert(message, type, duration)`
    - `openModal(id)` / `closeModal(id)`
    - `formatBytes(bytes)` → GB conversion
    - `formatDate(timestamp)` → readable date
  - **Responsive**: Breakpoint at 768px (mobile-first)
- **استفاده**: Extended by all other templates

#### 5. `templates/login.html`
- **نوع**: HTML Template
- **خطوط کد**: ~45 lines
- **نقش**: صفحه ورود
- **امکانات**:
  - فرم لاگین (username/password)
  - نمایش پیام‌های خطا (Flask flash)
  - نمایش اطلاعات پیش‌فرض (admin/admin123)
  - لودینگ در هنگام submit
- **Route**: `GET/POST /login`

#### 6. `templates/dashboard.html`
- **نوع**: HTML + JavaScript Template
- **خطوط کد**: ~125 lines
- **نقش**: داشبورد اصلی
- **امکانات**:
  - **8 Stat Cards**:
    1. Total Clients
    2. Active Clients (enable=1)
    3. Expired Clients (expiry < now)
    4. Expiring Soon (< 7 days)
    5. Total Servers
    6. Total Packages
    7. Traffic Used (GB)
    8. Total Quota (GB)
  - **Quick Actions**:
    - دکمه Sync Now
    - لینک‌های سریع به clients/servers/packages
  - **Real-time Logs**:
    - نمایش 20 خط آخر لاگ
    - رنگ‌آمیزی بر اساس نوع (ERROR/SUCCESS/INFO)
    - Auto-refresh هر 10 ثانیه
  - **JavaScript**:
    - `loadStats()` → fetch آمارها
    - `triggerSync()` → شروع همگام‌سازی
    - `loadLogs()` → بارگذاری لاگ‌ها
- **Route**: `GET /dashboard`

#### 7. `templates/clients.html`
- **نوع**: HTML + JavaScript Template
- **خطوط کد**: ~260 lines
- **نقش**: مدیریت کلاینت‌ها
- **امکانات**:
  - **Search Box**: جستجوی real-time در جدول
  - **Clients Table**:
    - ستون‌ها: Email, Traffic Used (GB), Total Quota (GB), Usage %, Expiry Date, Status
    - Badge رنگی برای Active/Expired
    - Progress bar برای usage
    - دکمه Edit/Apply Package/Reset
  - **Edit Modal**:
    - سه حالت action:
      1. **Set**: جایگزینی کامل (up=X, down=Y, total=Z)
      2. **Add**: افزودن به موجود (up+=X, down+=Y, total+=Z)
      3. **Reset**: صفر کردن (up=0, down=0)
    - فیلدها: Up Traffic (GB), Down Traffic (GB), Total Quota (GB), Expiry Days, Enable
    - Auto-calculate Total = Up + Down
  - **Apply Package Modal**:
    - Dropdown لیست پکیج‌ها
    - توضیح هر پکیج (days/traffic/price)
    - اعمال یکجا (با reset ترافیک قبلی)
  - **Reset Button**: صفر کردن ترافیک با تأیید
  - **JavaScript**:
    - `searchClients()` → فیلتر جدول
    - `editClient(email)` → باز کردن modal ویرایش
    - `saveClient()` → ذخیره تغییرات
    - `showApplyPackage(email)` → باز کردن modal پکیج
    - `applyPackage(email)` → اعمال پکیج
    - `resetTraffic(email)` → ریست ترافیک
- **Route**: `GET /clients`
- **API Calls**:
  - `POST /api/clients/<email>` → update
  - `POST /api/clients/<email>/apply-package` → apply
  - `POST /api/clients/<email>/reset` → reset

#### 8. `templates/packages.html`
- **نوع**: HTML + JavaScript Template
- **خطوط کد**: ~150 lines
- **نقش**: مدیریت پکیج‌ها
- **امکانات**:
  - **Packages Grid**: نمایش کارت‌ها در grid (responsive)
  - **Package Card**:
    - نام پکیج
    - مدت (روز)
    - حجم (GB)
    - قیمت (اختیاری)
    - دکمه Delete
  - **Add Package Modal**:
    - فیلدها: Name, Days, Traffic (GB), Price
    - Validation (همه فیلدها required)
  - **Delete Function**: حذف با confirmation
  - **JavaScript**:
    - `addPackage()` → ایجاد پکیج جدید
    - `deletePackage(id)` → حذف پکیج
- **Route**: `GET /packages`
- **API Calls**:
  - `GET /api/packages` → list
  - `POST /api/packages` → create
  - `DELETE /api/packages/<id>` → delete

#### 9. `templates/servers.html`
- **نوع**: HTML + JavaScript Template
- **خطوط کد**: ~160 lines
- **نقش**: مدیریت سرورهای remote
- **امکانات**:
  - **Servers Table**:
    - ستون‌ها: Name, Host, Port, Username, DB Path, Service Name, Actions
    - دکمه Delete برای هر سرور
  - **Add Server Modal**:
    - فیلدها:
      - Name (نام دلخواه)
      - Host (IP/domain)
      - Port (SSH port, default: 22)
      - Username (default: root)
      - DB Path (مسیر x-ui.db)
      - Service Name (نام سرویس X-UI)
    - راهنمای SSH Key Setup
  - **SSH Key Warning**: یادآوری کپی کلید عمومی به سرور
  - **JavaScript**:
    - `addServer()` → اضافه کردن سرور
    - `deleteServer(index)` → حذف سرور
- **Route**: `GET /servers`
- **API Calls**:
  - `GET /api/servers` → list
  - `POST /api/servers` → add
  - `DELETE /api/servers/<index>` → delete

#### 10. `templates/settings.html`
- **نوع**: HTML + JavaScript Template
- **خطوط کد**: ~320 lines
- **نقش**: تنظیمات سیستم
- **امکانات**:
  - **Sync Settings Section**:
    - فیلد Sync Interval (minutes)
    - دکمه Save Settings
  - **Telegram Settings Section**:
    - راهنمای گام به گام:
      1. ساخت bot با @BotFather
      2. دریافت Chat ID با @userinfobot
    - فیلدها: Bot Token, Chat ID, Enable/Disable
    - دکمه Test Telegram
  - **Backup Settings Section**:
    - Enable/Disable Backup
    - Keep Count (تعداد بکاپ نگهداری شده)
  - **System Info Section**:
    - نمایش SSH Public Key
    - دکمه مشاهده کلید (در modal)
    - دکمه کپی کلید
    - Restart Services
    - Clear Logs
    - Clear Old Backups
  - **SSH Key Modal**:
    - نمایش کلید عمومی در textarea
    - دکمه Copy to Clipboard
    - راهنمای اضافه کردن به سرورها
  - **JavaScript**:
    - `saveSettings()` → ذخیره تنظیمات
    - `testTelegram()` → ارسال پیام تست
    - `showSSHKey()` → نمایش modal کلید
    - `copySSHKey()` → کپی به clipboard
    - `restartServices()` → ری‌استارت سرویس‌ها
    - `clearLogs()` → پاک کردن لاگ‌ها
    - `clearBackups()` → پاک کردن بکاپ‌های قدیمی
- **Route**: `GET /settings`
- **API Calls**:
  - `POST /api/settings` → save
  - `POST /api/telegram/test` → test

---

### 📚 فایل‌های مستندات (Documentation Files)

#### 11. `README-panel-manager.md`
- **نوع**: Markdown Documentation
- **خطوط کد**: ~500 lines
- **زبان**: فارسی
- **نقش**: مستندات کامل پروژه
- **محتوا**:
  1. **مقدمه**: توضیح مشکل و راه‌حل
  2. **ویژگی‌ها**: لیست کامل امکانات (18 ویژگی)
  3. **پیش‌نیازها**: الزامات سیستم
  4. **نصب**: دستورالعمل نصب گام به گام
  5. **استفاده**: راهنمای استفاده (CLI + Web)
  6. **API Documentation**: مستندات 12 endpoint
  7. **پیکربندی**: توضیح فایل‌های JSON
  8. **عیب‌یابی**: راه‌حل مشکلات رایج (15 مورد)
  9. **امنیت**: توصیه‌های امنیتی
  10. **سناریوهای کاربردی**: مثال‌های واقعی
  11. **پشتیبانی**: راه‌های دریافت کمک
  12. **FAQ**: سوالات متداول
- **مخاطب**: کاربر نهایی، مدیر سیستم

#### 12. `QUICKSTART.md`
- **نوع**: Markdown Quick Guide
- **خطوط کد**: ~200 lines
- **زبان**: فارسی
- **نقش**: راهنمای سریع 5 دقیقه‌ای
- **محتوا**:
  1. **نصب سریع**: دستورات کپی-پیست
  2. **راه‌اندازی اولیه**: از پنل وب
  3. **استفاده روزانه**: سناریوهای متداول
  4. **دستورات Terminal**: کامندهای پرکاربرد
  5. **سناریوهای عملی**: 5 مثال واقعی
  6. **عیب‌یابی سریع**: رفع مشکلات فوری
- **مخاطب**: کاربران عجول، Quick Reference

#### 13. `INSTALLATION.md`
- **نوع**: Markdown Installation Guide
- **خطوط کد**: ~600 lines
- **زبان**: فارسی
- **نقش**: راهنمای نصب تفصیلی
- **محتوا**:
  1. **پیش‌نیازها**: چک‌لیست کامل
  2. **روش 1**: نصب از GitHub (پیشنهادی)
  3. **روش 2**: نصب دستی بدون GitHub
  4. **روش 3**: نصب کامل دستی (developers)
  5. **راه‌اندازی SSH Keys**: گام به گام
  6. **راه‌اندازی پنل وب**: اولین ورود
  7. **تنظیم Firewall**: UFW configuration
  8. **تنظیم Telegram**: ساخت bot
  9. **تست نصب**: 4 روش تست
  10. **عیب‌یابی نصب**: حل مشکلات رایج
  11. **نصب روی چند سرور**: HA setup
  12. **آپدیت نسخه**: راهنمای upgrade
  13. **حذف کامل**: uninstall
  14. **چک‌لیست نصب**: کامل
  15. **دریافت کمک**: جمع‌آوری لاگ‌ها
- **مخاطب**: مدیران سیستم، DevOps

#### 14. `PROJECT_SUMMARY.md`
- **نوع**: Markdown Project Overview
- **خطوط کد**: ~400 lines
- **زبان**: فارسی و انگلیسی
- **نقش**: خلاصه کامل پروژه
- **محتوا**:
  1. **نمای کلی**: توضیح هدف پروژه
  2. **ویژگی‌های کلیدی**: 10 feature اصلی
  3. **معماری سیستم**: نمودار و توضیح
  4. **ساختار فایل‌ها**: تمام دایرکتوری‌ها
  5. **راهنمای استفاده**: سناریوهای اصلی
  6. **جزئیات پیاده‌سازی**: توضیحات فنی
  7. **آمار پروژه**: تعداد خطوط کد
  8. **مقایسه با نسخه قبل**: تفاوت‌ها
  9. **چک‌لیست تست**: آیتم‌های تست
  10. **بهبودهای آینده**: ایده‌ها
- **مخاطب**: توسعه‌دهندگان، مدیران پروژه

#### 15. `FILE_LIST.md` (این فایل)
- **نوع**: Markdown File Index
- **خطوط کد**: ~800 lines
- **زبان**: فارسی
- **نقش**: لیست و توضیح تمام فایل‌ها
- **مخاطب**: همه

---

## 📊 آمار پروژه

### تعداد فایل‌ها:
- **Core Files**: 3 files
- **Templates**: 7 files
- **Documentation**: 5 files
- **Total**: **15 files**

### تعداد خطوط کد:
- **Bash**: ~800 lines (installer)
- **Python**: ~600 lines (web_app.py) + ~100 lines (embedded sync.py) = ~700 lines
- **HTML/CSS/JS**: ~340 (base) + 45 (login) + 125 (dashboard) + 260 (clients) + 150 (packages) + 160 (servers) + 320 (settings) = **~1,400 lines**
- **Documentation**: ~500 (README) + 200 (QUICKSTART) + 600 (INSTALLATION) + 400 (PROJECT_SUMMARY) + 800 (FILE_LIST) = **~2,500 lines**
- **Total**: **~5,400 lines** (بدون شمارش فضای خالی و کامنت‌ها)

### زبان‌های برنامه‌نویسی:
- Bash
- Python 3
- HTML5
- CSS3
- JavaScript (Vanilla)

### Framework/Library:
- Flask 3.0.0
- Flask-CORS 4.0.0
- requests 2.31.0
- SQLite3

---

## 🔄 نحوه استفاده از فایل‌ها

### برای نصب:
```bash
# فقط نیاز به یک فایل:
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

### برای توسعه:
```bash
# کلون repository
git clone <repo-url>
cd xui-panel-manager

# نصب dependencies
pip3 install -r requirements.txt

# اجرا
python3 web_app.py

# مرور
http://localhost:8080
```

### برای deploy:
```bash
# آپلود به GitHub
git add .
git commit -m "Initial release"
git push origin main

# نصب روی سرور
ssh root@server
wget https://raw.githubusercontent.com/user/repo/main/xui-panel-manager-installer.sh
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

---

## 📦 فایل‌های ناموجود (اختیاری)

### فایل‌هایی که می‌توانید اضافه کنید:

#### `sync.py` (جداگانه)
- در حال حاضر در installer جاسازی شده
- می‌توان جدا کرد برای خوانایی بهتر
- ~350-400 lines

#### `config.json.example`
```json
{
  "local_db_path": "/etc/x-ui/x-ui.db",
  "local_service_name": "x-ui",
  "sync_interval_minutes": 60,
  ...
}
```

#### `servers.json.example`
```json
{
  "servers": [
    {
      "name": "Server 1",
      "host": "10.0.0.1",
      "port": 22,
      ...
    }
  ]
}
```

#### `packages.json.example`
```json
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
```

#### `docker-compose.yml`
- برای دپلوی با Docker
- مفید برای تست و توسعه

#### `Makefile`
- کامندهای سریع (make install, make run, make test)

#### `.github/workflows/ci.yml`
- CI/CD برای GitHub Actions
- تست خودکار

#### `tests/`
- Unit tests
- Integration tests

#### `screenshots/`
- اسکرین‌شات‌های پنل وب
- برای README

---

## ✅ چک‌لیست فایل‌ها

### فایل‌های اساسی:
- [x] xui-panel-manager-installer.sh
- [x] web_app.py
- [x] requirements.txt

### قالب‌ها:
- [x] templates/base.html
- [x] templates/login.html
- [x] templates/dashboard.html
- [x] templates/clients.html
- [x] templates/packages.html
- [x] templates/servers.html
- [x] templates/settings.html

### مستندات:
- [x] README-panel-manager.md
- [x] QUICKSTART.md
- [x] INSTALLATION.md
- [x] PROJECT_SUMMARY.md
- [x] FILE_LIST.md

### اختیاری (پیشنهادی):
- [ ] sync.py (separated)
- [ ] config.json.example
- [ ] servers.json.example
- [ ] packages.json.example
- [ ] docker-compose.yml
- [ ] Makefile
- [ ] .gitignore
- [ ] LICENSE
- [ ] CHANGELOG.md
- [ ] CONTRIBUTING.md
- [ ] tests/
- [ ] screenshots/

---

## 🚀 آماده برای Release

### فایل‌های ضروری موجود است:
✅ اسکریپت نصب  
✅ برنامه وب  
✅ قالب‌های HTML  
✅ مستندات کامل  

### برای انتشار:
1. آپلود به GitHub
2. ساخت Release با tag (v1.0.0)
3. Attach فایل zip:
   ```bash
   zip -r xui-panel-manager-v1.0.0.zip \
     xui-panel-manager-installer.sh \
     web_app.py \
     requirements.txt \
     templates/ \
     *.md
   ```
4. نوشتن Release Notes
5. اشتراک‌گذاری!

---

**🎉 پروژه کامل و آماده استفاده است!**
