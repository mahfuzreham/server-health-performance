# 🖥️ Server Health Performance

<p align="center"><b>Open-source Daily Linux Server Health & Performance Checker</b><br>Local-first • Read-only • Privacy-friendly • cPanel/WHM & CloudLinux friendly</p>

---

## 📌 About

**Server Health Performance** is a lightweight Bash tool for daily Linux server health and performance checks.

It checks CPU, RAM, disk, network, services, security indicators, recent errors, hostname and public IP, and clearly lists **failed systemd services**.

The project is **fully open-source and local-first**. It does not use telemetry, tracking, install IDs, or a central collector.

## ✨ Features

- 📅 Daily health checking
- 🖥️ Hostname and public IP detection
- ⚡ CPU model, cores, threads, load and top CPU processes
- 🧠 RAM, available memory and swap usage
- 💾 Disk, filesystem, inode and disk I/O checks
- 📁 Large directories and large files
- 🌐 Network interfaces, sockets, ports and connection states
- ❌ Failed systemd services with service status/details
- 🔧 SSH, Apache, Nginx, PHP-FPM, MySQL/MariaDB and common service checks
- ☁️ cPanel/WHM and CloudLinux detection
- 🛡️ OOM, kernel, filesystem, system and SSH authentication errors
- 🔐 SELinux and firewall status
- 📊 Overall health summary
- 📝 Timestamped local reports
- 🔔 Optional Email and Discord alerts for warnings
- 🚫 No telemetry, tracking or central data collection

## 🚀 Quick Start

Run as root:

```bash
curl -fsSL https://raw.githubusercontent.com/mahfuzreham/server-health-performance/main/server-health-report.sh -o /root/server-health-report.sh
chmod +x /root/server-health-report.sh
/root/server-health-report.sh
```

The normal command shows a quick status first and lets the administrator **skip** or run the full report.

## 📅 Daily Automatic Check

Run the full check manually:

```bash
/root/server-health-report.sh --full
```

For a non-interactive daily check:

```bash
/root/server-health-report.sh --daily
```

Example cron (runs every day at 3:00 AM):

```cron
0 3 * * * /root/server-health-report.sh --daily >> /var/log/server-health-performance/daily.log 2>&1
```

The daily check does not modify services or configuration.

## 🔔 Optional Email / Discord Alerts

Alerts are **disabled by default**.

Discord:

```bash
export DISCORD_ON_ALERT=true
export DISCORD_WEBHOOK='https://discord.com/api/webhooks/REPLACE_ME'
/root/server-health-report.sh --daily
```

Email (requires a working `mail` command):

```bash
export EMAIL_ON_ALERT=true
export ALERT_EMAIL='you@example.com'
/root/server-health-report.sh --daily
```

Only warning conditions trigger alerts by default: high RAM, high root-disk usage, or failed services.

> Webhooks and email destinations are controlled by the server administrator. The project has no central notification service.

## 📄 Report Location

Reports are stored locally:

```text
/var/log/server-health-performance/report-YYYYMMDD-HHMMSS.txt
```

If that directory cannot be created, the script falls back to `/root/`.

## ❌ Failed Services

The report includes:

- Number of failed systemd services
- Service names
- `systemctl status` output for each failed service

Example:

```text
FAILED SERVICES
❌ Failed services: 1
nginx.service

--- nginx.service ---
Active: failed
...
```

## 🔐 Privacy & Safety

This project is intentionally **read-only**.

It does **not**:

- send telemetry
- create tracking/install IDs
- contact a central collector
- restart services
- change configuration
- modify firewall rules
- install packages automatically
- modify users
- delete files
- modify databases

The public IP is read only to display it in the local report or an administrator-configured notification.

> Run as root for the most complete results.

## 🧪 Supported Environments

Designed for:

- AlmaLinux
- Rocky Linux
- CentOS-compatible systems
- CloudLinux
- Ubuntu
- Debian
- VPS
- Dedicated Servers
- cPanel / WHM

Unsupported or unavailable checks are skipped safely.

## 🔧 Optional Tools

Advanced sections can use:

```text
curl
wget
iostat
lsof
systemctl
journalctl
mail
```

Missing tools are not installed automatically.

For RHEL-family systems:

```bash
dnf install sysstat lsof -y
```

## 📁 Project Structure

```text
server-health-performance/
├── server-health-report.sh
└── README.md
```


## 🗑️ Uninstall / Remove

If you want to completely remove the checker from a server, first remove the daily cron entry (if you added one), then delete the script and local reports:

```bash
crontab -e
```

Remove the line containing:

```text
/root/server-health-report.sh --daily
```

Then run:

```bash
rm -f /root/server-health-report.sh
rm -rf /var/log/server-health-performance
rm -f /root/server-health-report-*.txt
```

If you installed the script somewhere else, remove that copy instead.

### One-command removal

For the default installation used in this README:

```bash
crontab -l 2>/dev/null | grep -vF '/root/server-health-report.sh --daily' | crontab -
rm -f /root/server-health-report.sh
rm -rf /var/log/server-health-performance
rm -f /root/server-health-report-*.txt
```

> This removes the checker, its daily cron entry, and locally generated reports. It does **not** modify or remove your server's other services or configuration.

## 🤝 Contributing

Bug reports, improvements and pull requests are welcome.

When reporting an issue, include your Linux distribution and the relevant report section. **Never share passwords, API keys, tokens or other sensitive server data.**

## 📜 License

MIT License.

---

<p align="center">Made for Linux server administrators and hosting engineers.</p>
