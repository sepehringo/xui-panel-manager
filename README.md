# XUI Multi-Server Sync

Smart multi-panel sync for X-UI / 3X-UI using a Delta-Based algorithm.

> 🌐 [فارسی (Persian)](README.fa.md)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%20%7C%20Debian-orange.svg)]()
[![Python](https://img.shields.io/badge/Python-3.8%2B-green.svg)]()

---

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

