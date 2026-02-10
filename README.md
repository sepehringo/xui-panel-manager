# 🚀 XUI Panel Manager

یک سیستم مدیریت متمرکز برای چندین پنل X-UI/3X-UI با رابط وب و همگام‌سازی خودکار

---

## ✨ ویژگی‌ها

- 🔄 **همگام‌سازی خودکار** کلاینت‌ها بین چندین سرور
- 🌐 **پنل وب مدرن** برای مدیریت آسان
- 📦 **سیستم پکیج** برای تعریف و اعمال سریع پلن‌ها
- 🔔 **اعلان تلگرام** برای تغییرات
- 💾 **بکاپ خودکار** قبل از هر همگام‌سازی
- 🔐 **امنیت بالا** با احراز هویت SSH Key

---

## 📥 نصب

### نصب با یک خط (توصیه می‌شود):

```bash
wget -qO- https://raw.githubusercontent.com/sepehringo/xui-panel-manager/main/xui-panel-manager-installer.sh | sudo bash
```

### نصب دستی:

```bash
git clone https://github.com/sepehringo/xui-panel-manager.git
cd xui-panel-manager
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

---

## 🌐 دسترسی به پنل

بعد از نصب، به آدرس زیر بروید:

```
http://YOUR_SERVER_IP:8080
نام کاربری: admin
رمز عبور: admin123
```

⚠️ **حتماً رمز عبور را تغییر دهید!**

---

## 📋 الزامات

- **سرور**: Ubuntu 20.04 یا 22.04
- **RAM**: حداقل 512MB
- **دیسک**: حداقل 2GB
- **پنل X-UI**: نصب شده و فعال

---

## 🔧 مدیریت سریع

```bash
# مشاهده وضعیت
systemctl status xui-panel-manager-web
systemctl status xui-panel-manager-sync.timer

# مشاهده لاگ‌ها
tail -f /var/log/xui-panel-manager.log

# همگام‌سازی دستی
python3 /opt/xui-panel-manager/sync.py

# ری‌استارت سرویس‌ها
systemctl restart xui-panel-manager-web
```

---

## 📚 مستندات کامل

- 📘 [راهنمای فارسی](README-panel-manager.md)
- ⚡ [شروع سریع](QUICKSTART.md)
- 🔧 [راهنمای نصب تفصیلی](INSTALLATION.md)
- 🚀 [راهنمای دپلوی](DEPLOY.md)

---

## ⚙️ تنظیمات اولیه

### 1. اضافه کردن سرور

1. وارد پنل وب شوید
2. برو به **Settings** → **Servers**
3. کلید SSH را کپی کنید:
   ```bash
   cat /etc/xui-panel-manager/id_ed25519.pub
   ```
4. به سرور remote وصل شوید و کلید را اضافه کنید:
   ```bash
   ssh root@REMOTE_SERVER
   echo "PASTE_KEY_HERE" >> ~/.ssh/authorized_keys
   ```
5. سرور را در پنل اضافه کنید

### 2. تنظیم تلگرام (اختیاری)

1. با [@BotFather](https://t.me/BotFather) یک ربات بسازید
2. با [@userinfobot](https://t.me/userinfobot) Chat ID خود را بگیرید
3. در پنل: **Settings** → **Telegram** → اطلاعات را وارد کنید

### 3. ساخت پکیج

1. برو به **Packages**
2. روی **Add Package** کلیک کنید
3. مشخصات پکیج (روز، حجم، قیمت) را وارد کنید

### 4. مدیریت کلاینت‌ها

- **ویرایش**: Clients → Edit → انتخاب Set/Add/Reset
- **اعمال پکیج**: Clients → Apply Package → انتخاب پکیج
- **ریست ترافیک**: Clients → Reset

---

## 🔒 امنیت

```bash
# تغییر رمز عبور
echo -n "NEW_PASSWORD" | sha256sum
nano /etc/xui-panel-manager/users.json

# محدود کردن دسترسی به IP خاص
ufw allow from YOUR_IP to any port 8080

# فعال‌سازی فایروال
ufw enable
```

---

## 🐛 رفع مشکلات رایج

### پورت ۸۰۸۰ در حال استفاده
```bash
netstat -tulpn | grep 8080
nano /etc/xui-panel-manager/config.json  # تغییر پورت
systemctl restart xui-panel-manager-web
```

### خطای اتصال SSH
```bash
ssh -i /etc/xui-panel-manager/id_ed25519 root@REMOTE_SERVER
# اگر کار نکرد، کلید عمومی را دوباره اضافه کنید
```

### همگام‌سازی کار نمی‌کنه
```bash
systemctl status xui-panel-manager-sync.timer
python3 /opt/xui-panel-manager/sync.py  # تست دستی
```

---

## 📞 پشتیبانی

- 📖 [مستندات](INSTALLATION.md)
- 🐛 [گزارش باگ](https://github.com/sepehringo/xui-panel-manager/issues)
- 💬 [بحث و تبادل نظر](https://github.com/sepehringo/xui-panel-manager/discussions)

---

## 📊 آمار پروژه

- **تعداد فایل‌ها**: 32
- **خطوط کد**: ~10,000
- **زبان‌ها**: Bash, Python, HTML, CSS, JavaScript
- **مستندات**: فارسی + انگلیسی

---

## 📝 مجوز

این پروژه تحت مجوز MIT منتشر شده - [LICENSE](LICENSE)

---

<div align="center">

⭐ اگر این پروژه برایتان مفید بود، حتماً Star بدید!

Made with ❤️ for X-UI Community

</div>
