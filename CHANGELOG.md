# Changelog

All notable changes to XUI Panel Manager will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.0] - 2024-01-XX

### 🎉 Initial Release

#### Added
- **Multi-Server Sync System**: Synchronize client data across multiple X-UI/3X-UI panels
  - MAX traffic consumption algorithm (up, down, total)
  - MIN expiry time algorithm (remaining days)
  - Automatic backup before sync (keep last 10)
  - Retry logic with exponential backoff (8 attempts)
  
- **Web Management Panel**: Flask-based web interface
  - Modern responsive dashboard with 8 statistics cards
  - Client management (edit, apply packages, reset traffic)
  - Package template system (define and apply)
  - Server management (add/remove remote servers)
  - Settings page (sync interval, Telegram, backup)
  - Real-time logs viewer
  - REST API with 12 endpoints
  
- **Package Management System**: Pre-defined packages for resellers
  - Create packages with days/traffic/price
  - One-click application to clients
  - Default packages: Basic (30d/50GB), Standard (100GB), Premium (200GB), Unlimited (1000GB)
  
- **Multi-Language Support**: Persian and English
  - Installation script language selection
  - Translation system with t() function
  - All messages and prompts localized
  
- **Authentication & Security**:
  - SSH key-based authentication (ed25519)
  - Web panel session-based authentication
  - Password hashing (SHA256)
  - Default credentials: admin/admin123 (changeable)
  
- **Telegram Integration**:
  - Bot notifications for sync events
  - Alerts on package application
  - Client edit notifications
  - Test message functionality
  
- **Automatic Backup System**:
  - Pre-sync database snapshots
  - Keep last N backups (configurable)
  - Per-server backup storage
  - Timestamp-based naming
  
- **Systemd Integration**:
  - Timer unit for automatic sync
  - Service unit for web panel
  - Service unit for sync operations
  - Configurable intervals
  
- **CLI Management**: Terminal-based configuration
  - Interactive menu system
  - Server add/remove
  - Package management
  - Interval adjustment
  - Status monitoring
  
- **Documentation**:
  - Comprehensive README (500 lines)
  - Quick Start Guide (200 lines)
  - Installation Guide (600 lines)
  - Project Summary (400 lines)
  - File List (800 lines)
  - Total: ~2500 lines of documentation in Persian
  
#### Technical Details
- **Backend**: Python 3 with Flask 3.0.0
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Database**: SQLite3 (X-UI database)
- **Communication**: SSH for remote execution
- **Dependencies**: Flask, Flask-CORS, requests
- **Installation**: Bash script with auto-detection

#### File Structure
```
xui-panel-manager/
├── xui-panel-manager-installer.sh  (~800 lines)
├── web_app.py                      (~600 lines)
├── requirements.txt                
├── templates/                      (~1400 lines total)
│   ├── base.html
│   ├── login.html
│   ├── dashboard.html
│   ├── clients.html
│   ├── packages.html
│   ├── servers.html
│   └── settings.html
└── docs/                           (~2500 lines total)
    ├── README-panel-manager.md
    ├── QUICKSTART.md
    ├── INSTALLATION.md
    ├── PROJECT_SUMMARY.md
    └── FILE_LIST.md
```

#### Features Summary
- ✅ 15 files created
- ✅ ~5,400 lines of code (excluding comments/blanks)
- ✅ Multi-language (Persian/English)
- ✅ Web panel on port 8080
- ✅ REST API (12 endpoints)
- ✅ SSH-based remote management
- ✅ Automatic sync timer
- ✅ Telegram notifications
- ✅ Pre-sync backups
- ✅ Package templates
- ✅ Client traffic management
- ✅ Comprehensive documentation

---

## [Unreleased]

### Planned Features
- [ ] Docker support (docker-compose.yml)
- [ ] Advanced filtering in clients table
- [ ] Export clients to CSV/JSON
- [ ] Import clients from file
- [ ] Multi-user support (roles: admin, operator, viewer)
- [ ] Email notifications (alternative to Telegram)
- [ ] Webhook support for external integrations
- [ ] Advanced statistics (charts, graphs)
- [ ] Client usage history
- [ ] Automated reports (daily/weekly/monthly)
- [ ] Dark mode theme
- [ ] Mobile app (React Native)
- [ ] API rate limiting
- [ ] Two-factor authentication (2FA)
- [ ] LDAP/Active Directory integration

### Potential Improvements
- [ ] Better error handling in sync
- [ ] Parallel sync (multiple servers simultaneously)
- [ ] Database connection pooling
- [ ] Caching layer (Redis)
- [ ] Async/await in sync operations
- [ ] WebSocket for real-time updates
- [ ] Unit tests (pytest)
- [ ] Integration tests
- [ ] Performance benchmarks
- [ ] Load testing results

---

## Version History

### Version Numbering
- **Major (X.0.0)**: Breaking changes, major feature additions
- **Minor (1.X.0)**: New features, backward compatible
- **Patch (1.0.X)**: Bug fixes, minor improvements

### Support Policy
- Latest version: Full support
- Previous major version: Security updates only
- Older versions: Community support

---

## Migration Guides

### To v1.0.0
- Initial release, no migration needed

### Future Versions
- Migration guides will be added here

---

## Contributors
- Initial development by the XUI Panel Manager team
- Community contributions welcome!

---

## Acknowledgments
- X-UI/3X-UI panel developers
- Flask framework team
- Python community
- All beta testers and early adopters

---

**For detailed release notes, visit: https://github.com/sepehringo/xui-panel-manager/releases**
