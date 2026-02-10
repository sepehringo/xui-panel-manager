# 🚀 راهنمای سریع XUI Panel Manager

## نصب فوری (5 دقیقه)

### ✅ مرحله 1: نصب روی سرور اصلی

```bash
# دانلود و اجرا
wget https://sepehringo/xui-panel-manager-installer.sh
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

**در حین نصب:**
1. انتخاب زبان: **فارسی** یا **English**
2. بازه sync: `60` دقیقه (پیش‌فرض)
3. پورت پنل: `8080` (پیش‌فرض)

### ✅ مرحله 2: کپی کلید SSH

بعد از نصب، یک کلید SSH نمایش داده می‌شود. کپی کنید:

```bash
# روی هر سرور دیگر اجرا کنید:
echo "ssh-ed25519 AAAA... xui-panel-manager" >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
```

### ✅ مرحله 3: ورود به پنل وب

```
آدرس: http://YOUR_SERVER_IP:8080
نام کاربری: admin
رمز عبور: admin123
```

⚠️ **حتماً بعد از اولین ورود رمز را عوض کنید!**

---

## 📦 راه‌اندازی اولیه (از پنل وب)

### 1. اضافه کردن سرورها

```
منو: Servers → Add Server

نام: Server-Germany
IP: 192.168.1.100
پورت: 22
کاربر: root
دیتابیس: /etc/x-ui/x-ui.db
سرویس: x-ui
```

**تکرار برای همه سرورها**

### 2. تعریف پکیج‌ها

```
منو: Packages → Add Package

مثال 1:
نام: Basic 1 Month
روز: 30
حجم: 50 GB
قیمت: $10

مثال 2:
نام: Premium 1 Month
روز: 30
حجم: 200 GB
قیمت: $25
```

### 3. تنظیم تلگرام (اختیاری)

```
منو: Settings → Telegram

1. به @BotFather بروید → /newbot
2. Bot Token را کپی کنید
3. به @userinfobot بروید → ID را کپی کنید
4. در پنل ذخیره کنید
5. Test Message بزنید
```

---

## 💼 استفاده روزمره

### اعمال پکیج به مشتری:

```
1. منو: Clients
2. جستجوی email مشتری
3. کلیک: 📦 Package
4. انتخاب پکیج (مثلاً Basic 1 Month)
5. Apply
```

✅ **به صورت خودکار:**
- ترافیک reset می‌شود
- زمان جدید ست می‌شود
- در همه سرورها اعمال می‌شود
- telegram notification ارسال می‌شود

### ویرایش دستی کلاینت:

```
1. Clients → جستجو
2. کلیک: ✏️ Edit
3. وارد کردن:
   - Days: 30
   - Traffic: 100 GB
   - Action: Set/Add/Reset
4. Save
```

**Action Types:**
- **Set**: جایگزینی کامل
- **Add**: اضافه به موجودی
- **Reset**: فقط reset traffic

### صفر کردن ترافیک:

```
Clients → 🔄 Reset → تأیید
```

نتیجه: مصرف 0 می‌شود، بقیه تنظیمات حفظ می‌شود

---

## 📊 Dashboard

**نمایش خودکار:**
- تعداد کل کلاینت‌ها
- کلاینت‌های فعال
- کلاینت‌های منقضی شده
- کلاینت‌های در حال انقضا (7 روز)
- تعداد سرورها
- مصرف و کوتای کل

**Quick Actions:**
- 🔄 Run Sync Now: اجرای دستی sync
- 👥 Manage Clients: مدیریت کلاینت‌ها
- 📦 Manage Packages: پکیج‌ها
- 🖥️ Manage Servers: سرورها

---

## 🔧 دستورات Terminal

```bash
# منوی مدیریت
sudo xui-panel-manager

# sync دستی
sudo python3 /opt/xui-panel-manager/sync.py

# نمایش لاگ
tail -f /var/log/xui-panel-manager.log

# ری‌استارت پنل
systemctl restart xui-panel-manager-web

# وضعیت تایمر
systemctl status xui-panel-manager-sync.timer
```

---

## 🎯 سناریوهای عملی

### سناریو 1: فروش یک پکیج
```
1. مشتری پکیج "Premium 1 Month" می‌خرد
2. شما وارد پنل می‌شوید
3. Clients → جستجوی email مشتری
4. 📦 Package → Premium 1 Month → Apply
5. ✅ تمام! همه سرورها آپدیت شدند
```

### سناریو 2: افزایش زمان
```
1. مشتری تمدید می‌کند
2. Clients → ✏️ Edit
3. Days: 30
4. Action: Add (نه Set!)
5. Save → 30 روز به زمان فعلی اضافه می‌شود
```

### سناریو 3: افزایش ترافیک وسط ماه
```
1. Clients → ✏️ Edit
2. Traffic: 50 GB
3. Action: Add
4. Days: 0 (بدون تغییر زمان)
5. Save → 50GB اضافه می‌شود
```

### سناریو 4: شروع ماه جدید
```
1. Clients → 📦 Package
2. انتخاب همان پکیج قبلی
3. Apply
4. ✅ همه چیز reset و reset شد
```

---

## ⚠️ نکات مهم

### امنیت:
- ✅ حتماً رمز پیش‌فرض را عوض کنید
- ✅ فایروال را تنظیم کنید
- ✅ فقط به IP های مطمئن دسترسی دهید

### Backup:
- ✅ قبل از هر sync خودکار backup می‌گیرد
- ✅ 10 backup اخیر نگه داشته می‌شود
- ✅ مسیر: `/var/lib/xui-panel-manager/backups/`

### Telegram:
- ✅ sync موفق → اعلان ✅
- ✅ خطا → اعلان ❌
- ✅ تغییرات → اعلان 📝

---

## 🆘 حل مشکلات سریع

### پنل باز نمی‌شود؟
```bash
systemctl status xui-panel-manager-web
systemctl restart xui-panel-manager-web
```

### Sync کار نمی‌کند؟
```bash
# تست دستی
sudo python3 /opt/xui-panel-manager/sync.py

# بررسی لاگ
tail -f /var/log/xui-panel-manager.log
```

### SSH Error؟
```bash
# تست SSH
ssh -i /etc/xui-panel-manager/id_ed25519 root@SERVER_IP

# کپی دوباره کلید
cat /etc/xui-panel-manager/id_ed25519.pub
# کپی محتوا و paste روی سرور مقصد
```

### تلگرام نوتیف نمی‌آید؟
```bash
# تست ربات
curl -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" \
  -d "chat_id=<CHAT_ID>&text=Test"
```

---

## 📱 دسترسی از موبایل

1. باز کردن browser
2. رفتن به: `http://YOUR_IP:8080`
3. لاگین: admin / رمزتان
4. ✅ تمام امکانات موجود است!

**پیشنهاد:** Add to Home Screen در موبایل

---

## 🔄 آپدیت

```bash
# دانلود نسخه جدید
wget https://sepehringo/xui-panel-manager-installer.sh

# اجرا (تنظیمات حفظ می‌شود)
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

---

## 🔗 لینک‌های مفید

- 📖 مستندات کامل: `README-panel-manager.md`
- 🐛 گزارش باگ: GitHub Issues
- 💬 پشتیبانی: Telegram Group
- ⭐ Star: GitHub Repository

---

## ✅ چک‌لیست راه‌اندازی

- [ ] نصب اسکریپت
- [ ] کپی SSH key به سرورها
- [ ] ورود به پنل و تغییر رمز
- [ ] اضافه کردن سرورها
- [ ] تعریف 3-4 پکیج
- [ ] تست اعمال پکیج روی یک کلاینت
- [ ] راه‌اندازی تلگرام (اختیاری)
- [ ] تست sync دستی
- [ ] بررسی لاگ‌ها

---

**🎉 آماده است! حالا می‌توانید تمام پنل‌ها را از یک جا مدیریت کنید!**

نیاز به کمک؟ README کامل را بخوانید یا در Telegram پیام دهید.
