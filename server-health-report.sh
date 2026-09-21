#!/bin/bash
set -o pipefail

VERSION="1.1.0"
REPORT_DIR="${REPORT_DIR:-/var/log/server-health-performance}"
REPORT="${REPORT_DIR}/report-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$REPORT_DIR" 2>/dev/null || REPORT="/root/server-health-report-$(date +%Y%m%d-%H%M%S).txt"

# Optional notifications. Disabled by default.
DISCORD_WEBHOOK="${DISCORD_WEBHOOK:-}"
ALERT_EMAIL="${ALERT_EMAIL:-}"
EMAIL_ON_ALERT="${EMAIL_ON_ALERT:-false}"
DISCORD_ON_ALERT="${DISCORD_ON_ALERT:-false}"

section(){ echo; echo "============================================================"; echo " $1"; echo "============================================================"; }

get_public_ip() {
    local ip=""
    if command -v curl >/dev/null 2>&1; then
        ip=$(curl -4 -fsS --max-time 3 https://api.ipify.org 2>/dev/null || true)
    fi
    if [ -z "$ip" ] && command -v wget >/dev/null 2>&1; then
        ip=$(wget -qO- --timeout=3 https://api.ipify.org 2>/dev/null || true)
    fi
    echo "${ip:-Unavailable}"
}

get_service_list() {
    systemctl --failed --no-legend --no-pager 2>/dev/null | awk '{print $1}' | sed '/^$/d'
}

send_alerts() {
    local failed="$1" ram="$2" disk="$3" hostname="$4" public_ip="$5"
    local status="OK"
    [ "$failed" -gt 0 ] && status="WARNING"
    awk "BEGIN {exit !($ram >= 90 || $disk >= 90)}" && status="WARNING"

    [ "$status" = "OK" ] && return 0

    local msg="Server Health Alert%0AHostname: $hostname%0APublic IP: $public_ip%0ARAM: $ram%%0ARoot Disk: $disk%%0AFailed Services: $failed%0AReport: $REPORT"

    if [ "$DISCORD_ON_ALERT" = "true" ] && [ -n "$DISCORD_WEBHOOK" ] && command -v curl >/dev/null 2>&1; then
        curl -fsS --max-time 5 -H "Content-Type: application/json"           -d "{\"content\":\"$msg\"}" "$DISCORD_WEBHOOK" >/dev/null 2>&1 || true
    fi

    if [ "$EMAIL_ON_ALERT" = "true" ] && [ -n "$ALERT_EMAIL" ] && command -v mail >/dev/null 2>&1; then
        {
            echo "Server Health Alert"
            echo
            echo "Hostname: $hostname"
            echo "Public IP: $public_ip"
            echo "RAM: $ram%"
            echo "Root Disk: $disk%"
            echo "Failed Services: $failed"
            echo
            echo "Full report: $REPORT"
        } | mail -s "Server Health Alert - $hostname" "$ALERT_EMAIL" 2>/dev/null || true
    fi
}

run_report() {
    exec > >(tee "$REPORT") 2>&1

    local HOSTNAME PUBLIC_IP
    HOSTNAME=$(hostname 2>/dev/null || echo "Unknown")
    PUBLIC_IP=$(get_public_ip)

    echo "SERVER HEALTH & PERFORMANCE REPORT"
    echo "Version: $VERSION"
    echo "Generated: $(date)"
    echo "Hostname: $HOSTNAME"
    echo "Public IP: $PUBLIC_IP"
    uptime

    section "SYSTEM"; hostnamectl 2>/dev/null || true; uname -a
    section "CPU"; lscpu 2>/dev/null | egrep "Model name|CPU\\(s\\)|Core|Thread|Socket|Architecture" || true; cat /proc/loadavg
    section "MEMORY"; free -h; awk '/MemTotal|MemAvailable|SwapTotal|SwapFree/ {print}' /proc/meminfo
    section "DISK"; df -hT; echo; df -ih; echo; lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINT,ROTA 2>/dev/null || true
    section "DISK I/O"; if command -v iostat >/dev/null 2>&1; then iostat -xz 1 3; else echo "iostat not installed"; fi
    section "TOP CPU"; ps -eo pid,user,%cpu,%mem,etime,cmd --sort=-%cpu | head -21
    section "TOP RAM"; ps -eo pid,user,%cpu,%mem,etime,cmd --sort=-%mem | head -21
    section "PROCESSES"; echo "Total: $(ps -e --no-headers | wc -l)"; echo "Running: $(ps -e -o state= | grep -c R || true)"; echo "Zombie: $(ps -e -o state= | grep -c Z || true)"
    section "NETWORK"; ip -br addr 2>/dev/null || true; ss -s 2>/dev/null || true; echo; ss -lntup 2>/dev/null | head -50 || true

    section "FAILED SERVICES"
    local FAILED_LIST FAILED_COUNT
    FAILED_LIST=$(get_service_list)
    FAILED_COUNT=$(printf '%s\n' "$FAILED_LIST" | sed '/^$/d' | wc -l)
    if [ "$FAILED_COUNT" -gt 0 ]; then
        echo "❌ Failed services: $FAILED_COUNT"
        printf '%s\n' "$FAILED_LIST"
        echo
        while read -r svc; do
            [ -z "$svc" ] && continue
            echo "--- $svc ---"
            systemctl status "$svc" --no-pager -l 2>/dev/null | head -25 || true
        done <<< "$FAILED_LIST"
    else
        echo "✅ No failed systemd services detected."
    fi

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

    local MEM DISK
    MEM=$(free | awk '/Mem:/ {printf "%.1f", $3/$2*100}')
    DISK=$(df -P / | awk 'NR==2 {gsub("%","",$5); print $5}')
    section "HEALTH SUMMARY"
    echo "Hostname: $HOSTNAME"
    echo "Public IP: $PUBLIC_IP"
    echo "RAM: $MEM%"
    echo "Root disk: $DISK%"
    echo "Zombie: $(ps -e -o state= | grep -c Z || true)"
    echo "Failed services: $FAILED_COUNT"
    if [ "$FAILED_COUNT" -gt 0 ] || awk "BEGIN {exit !($MEM >= 90 || $DISK >= 90)}"; then
        echo "Overall status: ⚠️ WARNING"
    else
        echo "Overall status: ✅ OK"
    fi
    echo
    echo "Report saved: $REPORT"

    send_alerts "$FAILED_COUNT" "$MEM" "$DISK" "$HOSTNAME" "$PUBLIC_IP"
}

if [ "$1" = "--help" ]; then
    echo "Usage: $0 [--daily|--full|--help]"
    echo "--daily  Run non-interactive daily check"
    echo "--full   Run full report"
    echo "Default  Show quick terminal check, then offer full report"
    exit 0
fi

if [ "$1" = "--daily" ] || [ "$1" = "--full" ]; then
    run_report
    exit $?
fi

echo "🖥️ Server Health Performance v$VERSION"
echo "Hostname : $(hostname 2>/dev/null || echo Unknown)"
echo "Public IP: $(get_public_ip)"
echo
echo "Quick status:"
printf "RAM      : "; free | awk '/Mem:/ {printf "%.1f%%\n", $3/$2*100}'
printf "Disk /   : "; df -P / | awk 'NR==2 {print $5}'
printf "Load     : "; awk '{print $1" "$2" "$3}' /proc/loadavg
printf "Failed   : "; systemctl --failed --no-legend --no-pager 2>/dev/null | wc -l
echo
read -r -p "Run full report now? [Y/n/s=skip] " ans
case "$ans" in
    [NnSs]*) echo "Skipped. Run '$0 --full' anytime."; exit 0 ;;
    *) run_report ;;
esac
