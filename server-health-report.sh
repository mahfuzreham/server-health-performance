#!/bin/bash
set -o pipefail
REPORT="/root/server-health-report-$(date +%Y%m%d-%H%M%S).txt"
exec > >(tee "$REPORT") 2>&1

# Privacy-friendly telemetry is OFF by default. Set TELEMETRY_URL and
# TELEMETRY_ENABLED=true explicitly if you operate a collector and want usage counts.
TELEMETRY_ENABLED="${TELEMETRY_ENABLED:-false}"
TELEMETRY_URL="${TELEMETRY_URL:-}"
TELEMETRY_ID_FILE="/var/lib/server-health-performance/install-id"

send_telemetry() {
    [ "$TELEMETRY_ENABLED" = "true" ] || return 0
    [ -n "$TELEMETRY_URL" ] || return 0
    command -v curl >/dev/null 2>&1 || return 0
    mkdir -p "$(dirname "$TELEMETRY_ID_FILE")" 2>/dev/null || return 0
    if [ ! -s "$TELEMETRY_ID_FILE" ]; then
        if command -v uuidgen >/dev/null 2>&1; then uuidgen > "$TELEMETRY_ID_FILE";
        else cat /proc/sys/kernel/random/uuid > "$TELEMETRY_ID_FILE" 2>/dev/null || return 0; fi
        chmod 600 "$TELEMETRY_ID_FILE" 2>/dev/null || true
    fi
    local id os family version
    id=$(cat "$TELEMETRY_ID_FILE" 2>/dev/null)
    os=$(uname -s 2>/dev/null)
    family=$(awk -F= "/^ID=/{gsub(/\"/,"",\$2); print \$2}" /etc/os-release 2>/dev/null)
    version=$(awk -F= "/^VERSION_ID=/{gsub(/\"/,"",\$2); print \$2}" /etc/os-release 2>/dev/null)
    curl -fsS --max-time 5 -X POST -H "Content-Type: application/json" \
      --data "{"install_id":"$id","os":"$os","distro":"$family","version":"$version","script_version":"1.0.0"}" \
      "$TELEMETRY_URL" >/dev/null 2>&1 || true
}

section(){ echo; echo "============================================================"; echo " $1"; echo "============================================================"; }
echo "SERVER HEALTH & PERFORMANCE REPORT"; echo "Generated: $(date)"; echo "Hostname: $(hostname 2>/dev/null)"; uptime
section "SYSTEM"; hostnamectl 2>/dev/null || true; uname -a
section "CPU"; lscpu 2>/dev/null | egrep "Model name|CPU\\(s\\)|Core|Thread|Socket|Architecture" || true; cat /proc/loadavg
section "MEMORY"; free -h; awk "/MemTotal|MemAvailable|SwapTotal|SwapFree/ {print}" /proc/meminfo
section "DISK"; df -hT; echo; df -ih; echo; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,ROTA 2>/dev/null || true
section "DISK I/O"; if command -v iostat >/dev/null 2>&1; then iostat -xz 1 3; else echo "iostat not installed"; fi
section "TOP CPU"; ps -eo pid,user,%cpu,%mem,etime,cmd --sort=-%cpu | head -21
section "TOP RAM"; ps -eo pid,user,%cpu,%mem,etime,cmd --sort=-%mem | head -21
section "PROCESSES"; echo "Total: $(ps -e --no-headers | wc -l)"; echo "Running: $(ps -e -o state= | grep -c R || true)"; echo "Zombie: $(ps -e -o state= | grep -c Z || true)"
section "NETWORK"; ip -br addr 2>/dev/null || true; ss -s 2>/dev/null || true; echo; ss -lntup 2>/dev/null | head -50 || true
section "FAILED SERVICES"; systemctl --failed --no-pager 2>/dev/null || true
section "SERVICES"; for s in sshd ssh httpd nginx mariadb mysql php-fpm crond firewalld NetworkManager; do if systemctl list-unit-files 2>/dev/null | grep -q "^$s\\."; then printf "%-20s : " "$s"; systemctl is-active "$s" 2>/dev/null || true; fi; done
section "MYSQL"; command -v mysqladmin >/dev/null && { mysqladmin version 2>/dev/null || true; mysqladmin status 2>/dev/null || true; } || echo "mysqladmin not found"
section "APACHE"; command -v httpd >/dev/null && httpd -v 2>&1 || true; command -v apache2 >/dev/null && apache2 -v 2>&1 || true
section "NGINX"; command -v nginx >/dev/null && nginx -v 2>&1 || echo "Nginx not detected"
section "PHP"; command -v php >/dev/null && php -v | head -3 || echo "PHP CLI not detected"; ps aux | grep "[p]hp-fpm" | head -30 || true
section "CPANEL"; if [ -d /usr/local/cpanel ]; then echo "cPanel detected"; /usr/local/cpanel/cpanel -V 2>/dev/null || true; else echo "cPanel not detected"; fi
section "CLOUDLINUX"; [ -f /etc/cloudlinux-release ] && cat /etc/cloudlinux-release || echo "CloudLinux not detected"
section "OOM"; journalctl -k --no-pager 2>/dev/null | grep -Ei "out of memory|oom-killer|killed process" | tail -30 || true
section "KERNEL ERRORS"; journalctl -k -p err --no-pager 2>/dev/null | tail -50 || true
section "SYSTEM ERRORS 24H"; journalctl -p err --since "24 hours ago" --no-pager 2>/dev/null | tail -100 || true
section "SSH FAILED LOGINS 24H"; journalctl --since "24 hours ago" --no-pager 2>/dev/null | grep -Ei "failed password|authentication failure|invalid user" | tail -50 || true
section "FILESYSTEM ERRORS"; dmesg 2>/dev/null | grep -Ei "error|fail|I/O error|filesystem|ext4|xfs|nvme|ata" | tail -100 || true
section "SWAP"; swapon --show 2>/dev/null || true; free -h
section "OPEN FILES"; command -v lsof >/dev/null && echo "Open files: $(lsof 2>/dev/null | wc -l)" || echo "lsof not installed"
section "LARGE DIRECTORIES"; du -xhd1 / 2>/dev/null | sort -h | tail -20 || true
section "LARGE FILES"; find /var /home /tmp -xdev -type f -size +500M -print0 2>/dev/null | xargs -0 -r ls -lhS 2>/dev/null | head -30 || true
section "SECURITY"; echo "SELinux:"; getenforce 2>/dev/null || true; echo "Firewalld:"; systemctl is-active firewalld 2>/dev/null || true
section "HEALTH SUMMARY"; MEM=$(free | awk "/Mem:/ {printf "%.1f", \$3/\$2*100}"); DISK=$(df -P / | awk "NR==2 {gsub("%","",\$5); print \$5}"); Z=$(ps -e -o state= | grep -c Z || true); F=$(systemctl --failed --no-legend 2>/dev/null | wc -l); echo "RAM: $MEM%"; echo "Root disk: $DISK%"; echo "Zombie: $Z"; echo "Failed units: $F"; echo; echo "Report saved: $REPORT"

send_telemetry
