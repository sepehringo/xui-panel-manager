# 🚀 XUI Panel Manager

<div align="center">

![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)
![Python](https://img.shields.io/badge/python-3.8+-green.svg)
![Flask](https://img.shields.io/badge/flask-3.0.0-red.svg)
![License](https://img.shields.io/badge/license-MIT-yellow.svg)
![Platform](https://img.shields.io/badge/platform-Ubuntu%2020.04%2B-orange.svg)

**A powerful multi-server management system for X-UI/3X-UI panels**

[Features](#-features) • [Installation](#-installation) • [Documentation](#-documentation) • [Screenshots](#-screenshots) • [Support](#-support)

</div>

---

## 📖 Overview

XUI Panel Manager is a comprehensive solution for managing multiple X-UI/3X-UI panels from a single centralized web interface. It automatically synchronizes client data across all your servers, ensuring maximum traffic consumption and minimum remaining days are applied everywhere.

### Why XUI Panel Manager?

- 🔄 **Automatic Sync**: Keep all your X-UI servers in perfect sync
- 🌐 **Web Interface**: Modern, responsive dashboard for easy management
- 📦 **Package System**: Pre-define packages and apply them with one click
- 🌍 **Multi-Language**: Full support for Persian and English
- 🔔 **Telegram Alerts**: Get notified about sync events and changes
- 💾 **Auto Backup**: Automatic database backups before every sync
- 🔐 **Secure**: SSH key-based authentication for all remote operations

---

## ✨ Features

### Core Functionality
- ✅ **Multi-Server Synchronization**
  - MAX traffic consumption algorithm (up, down, total)
  - MIN expiry time algorithm (remaining days)
  - Automatic retry with exponential backoff
  - Service restart on database lock

- ✅ **Web Management Panel**
  - Modern responsive dashboard with real-time statistics
  - Client management (edit, reset, apply packages)
  - Package template system
  - Server management (add/remove)
  - Comprehensive settings page

- ✅ **Package Management**
  - Define packages with days/traffic/price
  - One-click application to clients
  - Default packages included (Basic, Standard, Premium, Unlimited)

- ✅ **Client Management**
  - Edit traffic (Set/Add/Reset modes)
  - Apply packages instantly
  - Reset traffic with confirmation
  - Search and filter

### Additional Features
- 🔔 **Telegram Integration**: Bot notifications for all events
- 💾 **Automatic Backups**: Keep last N backups per server
- ⏰ **Scheduled Sync**: Configurable timer (systemd)
- 🔑 **SSH Key Management**: Auto-generated ed25519 keys
- 📊 **Real-time Logs**: View sync operations live
- 🌐 **Multi-Language**: Persian + English installer
- 🔒 **Authentication**: Session-based web login
- 📱 **Responsive Design**: Works on desktop and mobile

---

## 🚀 Quick Start

### One-Line Installation

```bash
wget -qO- https://raw.githubusercontent.com/YOUR_USERNAME/xui-panel-manager/main/xui-panel-manager-installer.sh | sudo bash
```

### Manual Installation

```bash
# Download
git clone https://github.com/YOUR_USERNAME/xui-panel-manager.git
cd xui-panel-manager

# Run installer
chmod +x xui-panel-manager-installer.sh
sudo ./xui-panel-manager-installer.sh
```

### Access Web Panel

```
URL: http://YOUR_SERVER_IP:8080
Username: admin
Password: admin123
```

**⚠️ Change default password immediately!**

---

## 📋 Requirements

### Server
- **OS**: Ubuntu 20.04 or 22.04 LTS
- **RAM**: Minimum 512MB (Recommended: 1GB+)
- **Storage**: Minimum 2GB free space
- **Access**: root or sudo privileges

### X-UI Panel
- Installed and running
- Database accessible
- Service name known

### Network
- SSH access to remote servers
- Port 8080 (or custom) for web panel
- Internet connection for Telegram (optional)

---

## 📚 Documentation

### Quick Links
- 📘 [**README (Persian)**](docs/README-panel-manager.md) - Comprehensive guide in Persian
- ⚡ [**Quick Start**](docs/QUICKSTART.md) - 5-minute setup guide
- 🔧 [**Installation Guide**](docs/INSTALLATION.md) - Detailed installation steps
- 📊 [**Project Summary**](docs/PROJECT_SUMMARY.md) - Technical overview
- 📁 [**File List**](docs/FILE_LIST.md) - Complete file descriptions

### Topics
- [Configuration](#-configuration)
- [API Documentation](#-api)
- [Troubleshooting](#-troubleshooting)
- [Security Best Practices](#-security)

---

## 🖼️ Screenshots

### Dashboard
![Dashboard](screenshots/dashboard.png)
*Real-time statistics and quick actions*

### Client Management
![Clients](screenshots/clients.png)
*Search, edit, and apply packages to clients*

### Package Templates
![Packages](screenshots/packages.png)
*Pre-defined packages for easy management*

### Settings
![Settings](screenshots/settings.png)
*Configure sync, Telegram, and backup settings*

---

## ⚙️ Configuration

### Main Config File
Location: `/etc/xui-panel-manager/config.json`

```json
{
  "local_db_path": "/etc/x-ui/x-ui.db",
  "local_service_name": "x-ui",
  "sync_interval_minutes": 60,
  "web_panel": {
    "enabled": true,
    "host": "0.0.0.0",
    "port": 8080
  },
  "telegram": {
    "enabled": false,
    "bot_token": "YOUR_BOT_TOKEN",
    "chat_id": "YOUR_CHAT_ID"
  },
  "backup": {
    "enabled": true,
    "keep_count": 10
  }
}
```

### Server Management
Location: `/etc/xui-panel-manager/servers.json`

```json
{
  "servers": [
    {
      "name": "Server 1",
      "host": "10.0.0.1",
      "port": 22,
      "username": "root",
      "db_path": "/etc/x-ui/x-ui.db",
      "service_name": "x-ui"
    }
  ]
}
```

### Package Templates
Location: `/etc/xui-panel-manager/packages.json`

```json
{
  "packages": [
    {
      "id": "basic_30",
      "name": "Basic - 30 Days",
      "days": 30,
      "traffic_gb": 50,
      "price": "$10"
    }
  ]
}
```

---

## 🔧 Management

### CLI Commands

```bash
# Run installer/menu
xui-panel-manager

# Check status
systemctl status xui-panel-manager-web
systemctl status xui-panel-manager-sync.timer

# View logs
tail -f /var/log/xui-panel-manager.log
journalctl -u xui-panel-manager-web -f

# Manual sync
python3 /opt/xui-panel-manager/sync.py

# Restart services
systemctl restart xui-panel-manager-web
systemctl restart xui-panel-manager-sync.timer
```

### Web Panel Usage

1. **Add Servers**: Settings → Servers → Add Server
2. **Copy SSH Key**: Settings → System Info → View SSH Key
3. **Add to Remote**: `ssh root@REMOTE` then paste to `~/.ssh/authorized_keys`
4. **Define Packages**: Packages → Add Package
5. **Apply to Clients**: Clients → Select Client → Apply Package
6. **Configure Telegram**: Settings → Telegram → Enter Bot Token & Chat ID
7. **Test Sync**: Dashboard → Sync Now

---

## 🌐 API

### Authentication
All API endpoints require valid session cookie from `/login`.

### Endpoints

#### Clients
```bash
# Get all clients
GET /api/clients

# Update client
POST /api/clients/<email>
Body: {
  "action": "set|add|reset",
  "up_gb": 10,
  "down_gb": 20,
  "total_gb": 30,
  "expiry_days": 30,
  "enable": 1
}

# Apply package
POST /api/clients/<email>/apply-package
Body: {
  "package_id": "basic_30"
}

# Reset traffic
POST /api/clients/<email>/reset
```

#### Packages
```bash
# Get all packages
GET /api/packages

# Create package
POST /api/packages
Body: {
  "name": "Custom Package",
  "days": 30,
  "traffic_gb": 100,
  "price": "$20"
}

# Delete package
DELETE /api/packages/<id>
```

#### Servers
```bash
# Get all servers
GET /api/servers

# Add server
POST /api/servers
Body: {
  "name": "Server Name",
  "host": "10.0.0.1",
  "port": 22,
  "username": "root",
  "db_path": "/etc/x-ui/x-ui.db",
  "service_name": "x-ui"
}

# Delete server
DELETE /api/servers/<index>
```

#### Sync
```bash
# Trigger manual sync
POST /api/sync/trigger

# Get statistics
GET /api/stats

# Get logs
GET /api/logs?lines=50
```

#### Settings
```bash
# Save settings
POST /api/settings
Body: {
  "sync_interval_minutes": 60,
  "telegram_enabled": true,
  "telegram_bot_token": "TOKEN",
  "telegram_chat_id": "CHAT_ID",
  "backup_enabled": true,
  "backup_keep_count": 10
}

# Test Telegram
POST /api/telegram/test
```

---

## 🔐 Security

### Best Practices

1. **Change Default Password**
   ```bash
   # Generate password hash
   echo -n "YOUR_NEW_PASSWORD" | sha256sum
   
   # Edit users.json
   nano /etc/xui-panel-manager/users.json
   ```

2. **Restrict Web Panel Access**
   ```bash
   # Allow only specific IP
   ufw allow from YOUR_IP to any port 8080
   ```

3. **Use Strong SSH Keys**
   ```bash
   # Key is auto-generated during installation
   # Never share private key: /etc/xui-panel-manager/id_ed25519
   ```

4. **Enable Firewall**
   ```bash
   ufw enable
   ufw allow 22/tcp
   ufw allow 8080/tcp
   ```

5. **Regular Backups**
   - Automatic database backups are enabled by default
   - Located in: `/var/lib/xui-panel-manager/backups/`

6. **Monitor Logs**
   ```bash
   tail -f /var/log/xui-panel-manager.log
   ```

---

## 🐛 Troubleshooting

### Common Issues

#### Port 8080 Already in Use
```bash
# Check what's using the port
netstat -tulpn | grep 8080

# Change port in config
nano /etc/xui-panel-manager/config.json
# Change "port": 8080 to another port

# Restart
systemctl restart xui-panel-manager-web
```

#### SSH Connection Failed
```bash
# Test SSH connection manually
ssh -i /etc/xui-panel-manager/id_ed25519 root@REMOTE_SERVER

# If fails, check:
# 1. Is public key added to remote server?
cat /etc/xui-panel-manager/id_ed25519.pub
# Copy and add to remote: ~/.ssh/authorized_keys

# 2. Check SSH service on remote
systemctl status sshd

# 3. Check firewall
ufw status
```

#### Database Locked Error
```bash
# Increase retry attempts in config
nano /etc/xui-panel-manager/config.json
# Set "retry_attempts": 10

# Or enable automatic service restart
# Set "restart_service_on_lock": true
```

#### Sync Not Running
```bash
# Check timer status
systemctl status xui-panel-manager-sync.timer

# Check last run
systemctl list-timers | grep xui

# Check logs
journalctl -u xui-panel-manager-sync -n 50

# Manual test
python3 /opt/xui-panel-manager/sync.py
```

### Getting Help

1. **Check Logs**
   ```bash
   tail -f /var/log/xui-panel-manager.log
   journalctl -u xui-panel-manager-web -f
   ```

2. **Collect Debug Info**
   ```bash
   # System info
   cat /etc/os-release
   python3 --version
   
   # Service status
   systemctl status xui-panel-manager-*
   
   # Config files
   cat /etc/xui-panel-manager/config.json
   ```

3. **Open GitHub Issue**
   - Include logs
   - Include error messages
   - Describe what you tried

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Development Setup

```bash
# Clone repo
git clone https://github.com/YOUR_USERNAME/xui-panel-manager.git
cd xui-panel-manager

# Install dependencies
pip3 install -r requirements.txt

# Run web app
python3 web_app.py

# Access
open http://localhost:8080
```

---

## 📊 Project Stats

- **Total Files**: 15+
- **Lines of Code**: ~5,400 (excluding comments/blanks)
- **Languages**: Bash, Python, HTML, CSS, JavaScript
- **Documentation**: ~2,500 lines in Persian
- **Templates**: 7 HTML files
- **API Endpoints**: 12

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgments

- X-UI/3X-UI panel developers
- Flask framework team
- Python community
- All contributors and testers

---

## 📞 Support

- **Documentation**: [docs/](docs/)
- **Issues**: [GitHub Issues](https://github.com/YOUR_USERNAME/xui-panel-manager/issues)
- **Discussions**: [GitHub Discussions](https://github.com/YOUR_USERNAME/xui-panel-manager/discussions)
- **Telegram**: [@YOUR_TELEGRAM_CHANNEL]

---

## 🗺️ Roadmap

### v1.1.0 (Planned)
- [ ] Docker support
- [ ] Multi-user roles (admin, operator, viewer)
- [ ] Client usage history
- [ ] Advanced filtering

### v1.2.0 (Planned)
- [ ] Dark mode theme
- [ ] Export/import clients
- [ ] Email notifications
- [ ] Charts and graphs

### v2.0.0 (Future)
- [ ] Mobile app (React Native)
- [ ] Webhook support
- [ ] Two-factor authentication (2FA)
- [ ] LDAP integration

---

<div align="center">

**⭐ Star this repo if you find it helpful!**

Made with ❤️ for the X-UI community

[Report Bug](https://github.com/YOUR_USERNAME/xui-panel-manager/issues) • [Request Feature](https://github.com/YOUR_USERNAME/xui-panel-manager/issues) • [Documentation](docs/)

</div>
