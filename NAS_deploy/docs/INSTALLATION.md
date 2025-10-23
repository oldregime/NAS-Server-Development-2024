# Installation Guide

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Hardware Setup](#hardware-setup)
3. [Proxmox Installation](#proxmox-installation)
4. [VM Configuration](#vm-configuration)
5. [Storage Configuration](#storage-configuration)
6. [Security Hardening](#security-hardening)
7. [Service Deployment](#service-deployment)

## Prerequisites

### Hardware Requirements
- Triple CPU setup (Intel i9-9100F + 2× Xeon E2314)
- 32GB DDR4 ECC RAM minimum
- 12TB+ storage capacity for RAID-Z2
- 5TB+ for backup array
- Dual 1Gbps network interfaces

### Software Requirements
- Proxmox VE 8.x ISO
- Debian 12 (Bookworm) ISO
- TrueNAS SCALE ISO
- USB drive (8GB+) for installation media

## Hardware Setup

### Step 1: Physical Assembly
```bash
# 1. Install CPUs in motherboard
# 2. Install RAM modules (ensure ECC compatibility)
# 3. Connect storage drives to RAID controller
# 4. Connect network cables to both NICs
# 5. Connect power supply and peripherals
```

### Step 2: BIOS Configuration
- Enable virtualization (VT-x/AMD-V)
- Enable VT-d/IOMMU for PCIe passthrough
- Configure boot order (USB first)
- Enable ECC memory checking
- Disable secure boot

## Proxmox Installation

### Step 3: Install Proxmox VE
```bash
# 1. Create bootable USB with Proxmox ISO
# 2. Boot from USB
# 3. Follow installation wizard:
#    - Select target disk for Proxmox
#    - Set hostname: nas.local
#    - Configure management IP: 192.168.1.100/24
#    - Set root password
#    - Configure email for notifications
```

### Step 4: Post-Installation Configuration
```bash
# SSH into Proxmox host
ssh root@192.168.1.100

# Update system
apt update && apt upgrade -y

# Remove enterprise repository (if no subscription)
rm /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repository
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update again
apt update && apt upgrade -y
```

## VM Configuration

### Step 5: Create Debian 12 VM
```bash
# Download Debian 12 ISO
cd /var/lib/vz/template/iso
wget https://cdimage.debian.org/debian-cd/current/amd64/iso-cd/debian-12.x.x-amd64-netinst.iso

# Create VM via Proxmox web interface or CLI
qm create 100 \
  --name nas-debian \
  --memory 8192 \
  --cores 4 \
  --sockets 1 \
  --cpu host \
  --net0 virtio,bridge=vmbr0 \
  --ide2 local:iso/debian-12.x.x-amd64-netinst.iso,media=cdrom \
  --scsi0 local-lvm:32 \
  --boot order=scsi0 \
  --ostype l26

# Start VM and complete Debian installation
qm start 100
```

### Step 6: Create TrueNAS VM
```bash
# Download TrueNAS SCALE ISO
cd /var/lib/vz/template/iso
wget https://download.truenas.com/TrueNAS-SCALE-Latest.iso

# Create VM
qm create 101 \
  --name truenas \
  --memory 16384 \
  --cores 4 \
  --net0 virtio,bridge=vmbr0 \
  --ide2 local:iso/TrueNAS-SCALE-Latest.iso,media=cdrom \
  --scsi0 local-lvm:64 \
  --boot order=scsi0 \
  --ostype l26
```

## Storage Configuration

### Step 7: Configure ZFS Storage Pool
```bash
# SSH into Debian VM
ssh user@nas-debian

# Install ZFS utilities
sudo apt install zfsutils-linux

# Create RAID-Z2 pool (6 disks for redundancy)
sudo zpool create -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  -O normalization=formD \
  tank raidz2 \
  /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg

# Enable encryption
sudo zfs create -o encryption=on \
  -o keyformat=passphrase \
  -o keylocation=prompt \
  tank/encrypted

# Create backup pool (RAID-1)
sudo zpool create backup mirror /dev/sdh /dev/sdi

# Check pool status
sudo zpool status
sudo zfs list
```

### Step 8: Configure ZFS Snapshots
```bash
# Create snapshot schedule
sudo crontab -e

# Add snapshot entries
0 * * * * /usr/sbin/zfs snapshot tank/encrypted@hourly-$(date +\%Y\%m\%d-\%H\%M)
0 0 * * * /usr/sbin/zfs snapshot tank/encrypted@daily-$(date +\%Y\%m\%d)
0 0 * * 0 /usr/sbin/zfs snapshot tank/encrypted@weekly-$(date +\%Y\%m\%d)

# Prune old snapshots (keep last 24 hourly, 30 daily, 12 weekly)
0 1 * * * /root/scripts/prune_snapshots.sh
```

## Security Hardening

### Step 9: SSH Key Configuration
```bash
# On client machine, generate SSH key
ssh-keygen -t ed25519 -C "nas-access"

# Copy public key to NAS
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@nas-debian

# On NAS, disable password authentication
sudo nano /etc/ssh/sshd_config

# Set the following:
PasswordAuthentication no
PubkeyAuthentication yes
PermitRootLogin no
Protocol 2

# Restart SSH
sudo systemctl restart sshd
```

### Step 10: Configure Firewall
```bash
# Install UFW
sudo apt install ufw

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH
sudo ufw allow 22/tcp

# Allow NFS (if using)
sudo ufw allow 2049/tcp

# Allow Samba (if using)
sudo ufw allow 445/tcp
sudo ufw allow 139/tcp

# Enable firewall
sudo ufw enable
```

### Step 11: Install VPN (ZeroTier)
```bash
# Install ZeroTier
curl -s https://install.zerotier.com | sudo bash

# Join network
sudo zerotier-cli join <YOUR_NETWORK_ID>

# On ZeroTier web portal, authorize the device
# Verify connection
sudo zerotier-cli listnetworks
```

## Service Deployment

### Step 12: Install Plex Media Server
```bash
# Add Plex repository
echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -

# Install Plex
sudo apt update
sudo apt install plexmediaserver

# Start and enable Plex
sudo systemctl start plexmediaserver
sudo systemctl enable plexmediaserver

# Access Plex at http://nas-debian:32400/web
```

### Step 13: Configure Monitoring
```bash
# Install Prometheus Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.7.0.linux-amd64*

# Create systemd service
sudo nano /etc/systemd/system/node_exporter.service

# Add content:
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target

# Enable and start
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

## Verification

### Step 14: Test Installation
```bash
# Check ZFS pool health
sudo zpool status

# Check network connectivity
ping -c 4 8.8.8.8

# Check SSH access
ssh user@nas-debian "uptime"

# Check services
sudo systemctl status plexmediaserver
sudo systemctl status node_exporter

# Check firewall rules
sudo ufw status verbose

# Check disk performance
sudo hdparm -tT /dev/sdb
```

## Next Steps

After successful installation:
1. Configure backup schedules (see [CONFIGURATION.md](CONFIGURATION.md))
2. Set up monitoring dashboards
3. Review security settings (see [SECURITY.md](SECURITY.md))
4. Test disaster recovery procedures

## Troubleshooting

For common issues and solutions, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
