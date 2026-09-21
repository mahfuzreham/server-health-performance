# 🖥️ Server Health Performance

<p align="center"><b>All-in-one Linux Server Health & Performance Report</b><br>Safe • Read-only • Lightweight • cPanel/WHM & CloudLinux friendly</p>

---

## 📌 About

**Server Health Performance** is a lightweight Bash diagnostic tool for checking the health, performance, services, resources, networking, security indicators, and recent errors of a Linux server.

It is designed especially for **VPS, Dedicated Servers, cPanel/WHM and CloudLinux environments**.

## ✨ Features

- ⚡ CPU model, cores, threads, load and top CPU processes
- 🧠 RAM, available memory and swap usage
- 💾 Disk, filesystem, inode and disk I/O checks
- 📁 Large directories and large files
- 🌐 Network interfaces, sockets, ports and connection states
- 🔧 SSH, Apache, Nginx, PHP-FPM, MySQL/MariaDB and common service checks
- ☁️ cPanel/WHM and CloudLinux detection
- 🛡️ OOM, kernel, filesystem, system and SSH authentication errors
- 🔐 SELinux and firewall status
- 📊 Final health summary with basic warnings
- 📝 Timestamped report saved under `/root/`

## 🚀 Quick Start

Run as root:

```bash
curl -fsSL https://raw.githubusercontent.com/mahfuzreham/server-health-performance/main/server-health-report.sh -o /root/server-health-report.sh
chmod +x /root/server-health-report.sh
/root/server-health-report.sh
```

Or:

```bash
wget -O /root/server-health-report.sh https://raw.githubusercontent.com/mahfuzreham/server-health-performance/main/server-health-report.sh
chmod +x /root/server-health-report.sh
/root/server-health-report.sh
```

## 📄 Report Location

Each run creates a timestamped report:

```text
/root/server-health-report-YYYYMMDD-HHMMSS.txt
```

View reports:

```bash
ls -lh /root/server-health-report-*.txt
less /root/server-health-report-*.txt
```

## 🔐 Safety

This project is intentionally **read-only**.

It does **not** restart services, change configuration, modify firewall rules, install packages automatically, modify users, delete files, or change databases.

It only reads server information and creates a local report.

> Run as root for the most complete results.

## 🧪 Supported Environments

Designed for common Linux environments including:

- AlmaLinux
- Rocky Linux
- CentOS-compatible systems
- CloudLinux
- Ubuntu
- Debian
- VPS and Dedicated Servers
- cPanel / WHM

Unsupported or unavailable checks are skipped safely.

## 🔧 Optional Tools

Advanced sections can use:

```text
iostat
lsof
systemctl
timedatectl
```

Missing optional tools are reported and are **not installed automatically**.

For RHEL-family systems:

```bash
dnf install sysstat lsof -y
```

## 📊 Health Summary

The final section reports:

- RAM usage
- Root disk usage
- Zombie processes
- Failed systemd units
- Basic warnings

This is a diagnostic tool, not a replacement for continuous monitoring.

## 🛠️ Troubleshooting

Permission issue:

```bash
chmod +x /root/server-health-report.sh
sudo /root/server-health-report.sh
```

## 📁 Project Structure

```text
server-health-performance/
├── server-health-report.sh
└── README.md
```

## 🤝 Contributing

Bug reports, improvements and pull requests are welcome.

When reporting an issue, include your Linux distribution and the relevant report section. **Never share passwords, API keys, tokens or other sensitive server data.**

## 📜 License

MIT License.

---

<p align="center">Made for Linux server administrators and hosting engineers.</p>
