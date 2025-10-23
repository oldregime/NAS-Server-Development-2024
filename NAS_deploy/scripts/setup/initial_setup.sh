#!/bin/bash
###############################################################################
# Initial Setup Script for NAS Server
# Description: Automates initial configuration of NAS server
# Author: Divyansh Joshi
# Date: 2024-12-01
###############################################################################

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
LOG_FILE="/var/log/nas_setup.log"

# Logging
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

success() {
    echo -e "${GREEN}✓${NC} $1"
    log "SUCCESS: $1"
}

error() {
    echo -e "${RED}✗${NC} $1"
    log "ERROR: $1"
    exit 1
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
    log "INFO: $1"
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error "This script must be run as root"
fi

info "Starting NAS server initial setup..."

# Update system
info "Updating system packages..."
apt update && apt upgrade -y || error "Failed to update system"
success "System updated"

# Install essential packages
info "Installing essential packages..."
apt install -y \
    zfsutils-linux \
    openssh-server \
    ufw \
    fail2ban \
    htop \
    iotop \
    tmux \
    vim \
    curl \
    wget \
    git \
    smartmontools \
    lm-sensors \
    unattended-upgrades \
    mailutils || error "Failed to install packages"
success "Essential packages installed"

# Configure SSH
info "Configuring SSH..."
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup
cat >> /etc/ssh/sshd_config << EOF

# NAS Security Settings
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
MaxSessions 2
Protocol 2
EOF
systemctl restart sshd
success "SSH configured"

# Configure firewall
info "Configuring firewall..."
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw --force enable
success "Firewall configured"

# Configure fail2ban
info "Configuring fail2ban..."
cat > /etc/fail2ban/jail.local << EOF
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
EOF
systemctl enable fail2ban
systemctl restart fail2ban
success "Fail2ban configured"

# Enable automatic security updates
info "Enabling automatic security updates..."
dpkg-reconfigure -plow unattended-upgrades
success "Automatic updates enabled"

# Detect sensors
info "Detecting hardware sensors..."
sensors-detect --auto || info "Sensor detection completed with warnings"
success "Hardware sensors configured"

# Create directory structure
info "Creating directory structure..."
mkdir -p /root/scripts/backup
mkdir -p /root/scripts/monitoring
mkdir -p /root/scripts/setup
mkdir -p /var/log/nas
success "Directory structure created"

# Set up log rotation
info "Configuring log rotation..."
cat > /etc/logrotate.d/nas << EOF
/var/log/nas/*.log {
    daily
    rotate 30
    compress
    delaycompress
    notifempty
    create 0640 root root
    sharedscripts
}
EOF
success "Log rotation configured"

# Install ZeroTier (optional)
read -p "Do you want to install ZeroTier VPN? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    info "Installing ZeroTier..."
    curl -s https://install.zerotier.com | bash
    success "ZeroTier installed"
    info "Join a network with: zerotier-cli join <network-id>"
fi

# Configure SMART monitoring
info "Configuring SMART monitoring..."
systemctl enable smartd
systemctl start smartd
success "SMART monitoring enabled"

# Set up cron jobs
info "Setting up maintenance cron jobs..."
(crontab -l 2>/dev/null; echo "0 2 * * 0 zpool scrub tank") | crontab -
(crontab -l 2>/dev/null; echo "0 3 * * * /root/scripts/backup/automated_backup.sh") | crontab -
(crontab -l 2>/dev/null; echo "*/30 * * * * /root/scripts/monitoring/health_check.sh") | crontab -
success "Cron jobs configured"

# Create initial README
cat > /root/README.txt << EOF
NAS Server Setup Complete
========================

Important Files:
- Configuration: /etc/
- Scripts: /root/scripts/
- Logs: /var/log/nas/

Next Steps:
1. Configure ZFS storage pools
2. Set up backup destinations
3. Install and configure services (Plex, Samba, etc.)
4. Configure monitoring dashboards
5. Test backup and restore procedures

Documentation: https://github.com/yourusername/NAS_deploy

For support: divyanshjoshi2022@vitbhopal.ac.in
EOF

success "Initial setup completed successfully!"
info "Please review /root/README.txt for next steps"
info "Reboot recommended to apply all changes"

exit 0
