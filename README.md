# Server Health Performance

Safe, read-only Linux server health and performance reporting tool.

## Checks
- System/kernel and uptime
- CPU/load
- RAM/swap
- Disk/filesystem/inodes
- Disk I/O when iostat exists
- Top CPU/RAM processes
- Network/listening ports
- Failed systemd units
- SSH, Apache/Nginx, PHP/PHP-FPM, MySQL/MariaDB
- cPanel/WHM and CloudLinux detection
- OOM/kernel/system/SSH errors
- Large directories/files
- SELinux/firewall status
- Basic health summary

## Usage
```bash
curl -fsSL https://raw.githubusercontent.com/mahfuzreham/server-health-performance/main/server-health-report.sh -o /root/server-health-report.sh
chmod +x /root/server-health-report.sh
sudo /root/server-health-report.sh
```

The script does not install packages, restart services, modify configuration, or change firewall rules.

## License
MIT
