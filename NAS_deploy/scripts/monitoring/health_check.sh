#!/bin/bash
###############################################################################
# NAS Health Check Script
# Description: Monitors system health and sends alerts
# Author: Divyansh Joshi
# Date: 2024-12-01
###############################################################################

set -euo pipefail

# Configuration
LOG_FILE="/var/log/nas_health.log"
ALERT_EMAIL="admin@example.com"
CPU_THRESHOLD=80
RAM_THRESHOLD=90
DISK_THRESHOLD=85
TEMP_THRESHOLD=70

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Alert function
alert() {
    log "ALERT: $1"
    echo "$1" | mail -s "NAS Health Alert" "${ALERT_EMAIL}"
}

# Check CPU usage
check_cpu() {
    log "Checking CPU usage..."
    CPU_USAGE=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    CPU_USAGE_INT=${CPU_USAGE%.*}
    
    if [[ ${CPU_USAGE_INT} -gt ${CPU_THRESHOLD} ]]; then
        echo -e "${RED}[FAIL]${NC} CPU usage is ${CPU_USAGE}% (threshold: ${CPU_THRESHOLD}%)"
        alert "CPU usage is high: ${CPU_USAGE}%"
    else
        echo -e "${GREEN}[OK]${NC} CPU usage: ${CPU_USAGE}%"
    fi
}

# Check RAM usage
check_ram() {
    log "Checking RAM usage..."
    RAM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    
    if [[ ${RAM_USAGE} -gt ${RAM_THRESHOLD} ]]; then
        echo -e "${RED}[FAIL]${NC} RAM usage is ${RAM_USAGE}% (threshold: ${RAM_THRESHOLD}%)"
        alert "RAM usage is high: ${RAM_USAGE}%"
    else
        echo -e "${GREEN}[OK]${NC} RAM usage: ${RAM_USAGE}%"
    fi
}

# Check disk usage
check_disk() {
    log "Checking disk usage..."
    DISK_USAGE=$(df -h / | awk 'NR==2 {print $5}' | cut -d'%' -f1)
    
    if [[ ${DISK_USAGE} -gt ${DISK_THRESHOLD} ]]; then
        echo -e "${RED}[FAIL]${NC} Disk usage is ${DISK_USAGE}% (threshold: ${DISK_THRESHOLD}%)"
        alert "Disk usage is high: ${DISK_USAGE}%"
    else
        echo -e "${GREEN}[OK]${NC} Disk usage: ${DISK_USAGE}%"
    fi
}

# Check ZFS pool health
check_zfs() {
    log "Checking ZFS pool health..."
    
    if ! command -v zpool &> /dev/null; then
        echo -e "${YELLOW}[WARN]${NC} ZFS not installed"
        return
    fi
    
    for pool in $(zpool list -H -o name); do
        HEALTH=$(zpool list -H -o health "${pool}")
        
        if [[ "${HEALTH}" != "ONLINE" ]]; then
            echo -e "${RED}[FAIL]${NC} ZFS pool ${pool} health: ${HEALTH}"
            alert "ZFS pool ${pool} is not ONLINE: ${HEALTH}"
        else
            echo -e "${GREEN}[OK]${NC} ZFS pool ${pool}: ${HEALTH}"
        fi
        
        # Check for scrub errors
        SCRUB_ERRORS=$(zpool status "${pool}" | grep "errors:" | tail -1 | awk '{print $2}')
        if [[ "${SCRUB_ERRORS}" != "No" && "${SCRUB_ERRORS}" != "0" ]]; then
            echo -e "${RED}[FAIL]${NC} ZFS pool ${pool} has scrub errors: ${SCRUB_ERRORS}"
            alert "ZFS pool ${pool} has scrub errors: ${SCRUB_ERRORS}"
        fi
    done
}

# Check system temperature
check_temperature() {
    log "Checking system temperature..."
    
    if command -v sensors &> /dev/null; then
        MAX_TEMP=$(sensors | grep -i "Core" | awk '{print $3}' | grep -oP '\d+' | sort -nr | head -1)
        
        if [[ ${MAX_TEMP} -gt ${TEMP_THRESHOLD} ]]; then
            echo -e "${RED}[FAIL]${NC} CPU temperature is ${MAX_TEMP}°C (threshold: ${TEMP_THRESHOLD}°C)"
            alert "CPU temperature is high: ${MAX_TEMP}°C"
        else
            echo -e "${GREEN}[OK]${NC} CPU temperature: ${MAX_TEMP}°C"
        fi
    else
        echo -e "${YELLOW}[WARN]${NC} lm-sensors not installed"
    fi
}

# Check network connectivity
check_network() {
    log "Checking network connectivity..."
    
    if ping -c 3 8.8.8.8 &> /dev/null; then
        echo -e "${GREEN}[OK]${NC} Network connectivity"
    else
        echo -e "${RED}[FAIL]${NC} No network connectivity"
        alert "Network connectivity lost"
    fi
}

# Check critical services
check_services() {
    log "Checking critical services..."
    
    SERVICES=("sshd" "plexmediaserver" "smbd" "nfs-server")
    
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "${service}" 2>/dev/null; then
            echo -e "${GREEN}[OK]${NC} Service ${service} is running"
        else
            echo -e "${YELLOW}[WARN]${NC} Service ${service} is not running"
        fi
    done
}

# Check SMART status
check_smart() {
    log "Checking SMART status..."
    
    if ! command -v smartctl &> /dev/null; then
        echo -e "${YELLOW}[WARN]${NC} smartmontools not installed"
        return
    fi
    
    for disk in /dev/sd[a-z]; do
        if [[ -e "${disk}" ]]; then
            SMART_STATUS=$(smartctl -H "${disk}" | grep "PASSED\|FAILED" || echo "UNKNOWN")
            
            if echo "${SMART_STATUS}" | grep -q "FAILED"; then
                echo -e "${RED}[FAIL]${NC} SMART status for ${disk}: FAILED"
                alert "SMART test failed for ${disk}"
            elif echo "${SMART_STATUS}" | grep -q "PASSED"; then
                echo -e "${GREEN}[OK]${NC} SMART status for ${disk}: PASSED"
            fi
        fi
    done
}

# Main execution
main() {
    log "===== Starting NAS Health Check ====="
    
    check_cpu
    check_ram
    check_disk
    check_zfs
    check_temperature
    check_network
    check_services
    check_smart
    
    log "===== Health Check Completed ====="
}

main "$@"
