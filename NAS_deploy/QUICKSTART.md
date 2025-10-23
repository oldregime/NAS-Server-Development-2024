# Quick Start Guide

Get your NAS server up and running in 10 steps!

## Prerequisites Checklist

- [ ] Hardware assembled and powered on
- [ ] Network cables connected
- [ ] Monitor and keyboard attached
- [ ] Proxmox VE ISO on USB drive
- [ ] Basic networking knowledge
- [ ] 2-3 hours of setup time

---

## Step 1: Install Proxmox VE (30 min)

```bash
# 1. Boot from Proxmox USB drive
# 2. Follow installation wizard
# 3. Select installation disk
# 4. Set timezone and keyboard layout
# 5. Configure network:
#    - IP: 192.168.1.100/24
#    - Gateway: 192.168.1.1
#    - DNS: 8.8.8.8
# 6. Set root password
# 7. Complete installation and reboot
```

**Access Proxmox:** `https://192.168.1.100:8006`

---

## Step 2: Update Proxmox (10 min)

```bash
# SSH into Proxmox
ssh root@192.168.1.100

# Remove enterprise repo
rm /etc/apt/sources.list.d/pve-enterprise.list

# Add no-subscription repo
echo "deb http://download.proxmox.com/debian/pve bookworm pve-no-subscription" > /etc/apt/sources.list.d/pve-no-subscription.list

# Update system
apt update && apt upgrade -y
```

---

## Step 3: Create Debian VM (20 min)

Via Proxmox Web UI:

1. Click **"Create VM"**
2. **General:** 
   - VM ID: 100
   - Name: nas-debian
3. **OS:** 
   - ISO: debian-12.x.x-amd64-netinst.iso
4. **System:** Default settings
5. **Disks:** 
   - Size: 32 GB
   - Storage: local-lvm
6. **CPU:** 
   - Cores: 4
7. **Memory:** 
   - RAM: 8192 MB
8. **Network:** Default (vmbr0)
9. **Start VM and install Debian**

---

## Step 4: Configure ZFS Storage (30 min)

```bash
# SSH into Debian VM
ssh user@<vm-ip>

# Install ZFS
sudo apt update
sudo apt install zfsutils-linux -y

# Create RAID-Z2 pool (adjust drive names)
sudo zpool create -o ashift=12 \
  -O compression=lz4 \
  -O atime=off \
  tank raidz2 \
  /dev/sdb /dev/sdc /dev/sdd /dev/sde /dev/sdf /dev/sdg

# Create encrypted dataset
sudo zfs create -o encryption=on \
  -o keyformat=passphrase \
  tank/encrypted

# Verify
sudo zpool status
sudo zfs list
```

---

## Step 5: Set Up SSH Security (15 min)

```bash
# On your local machine, generate key
ssh-keygen -t ed25519 -C "nas-access"

# Copy key to NAS
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@<vm-ip>

# On NAS, disable password auth
sudo nano /etc/ssh/sshd_config

# Change these lines:
PasswordAuthentication no
PermitRootLogin no

# Restart SSH
sudo systemctl restart sshd
```

---

## Step 6: Configure Firewall (10 min)

```bash
# Install UFW
sudo apt install ufw -y

# Configure rules
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'

# Enable firewall
sudo ufw enable

# Check status
sudo ufw status verbose
```

---

## Step 7: Install VPN (15 min)

```bash
# Install ZeroTier
curl -s https://install.zerotier.com | sudo bash

# Join your network
sudo zerotier-cli join <YOUR_NETWORK_ID>

# Verify connection
sudo zerotier-cli listnetworks
```

**Note:** Create a free ZeroTier account at [zerotier.com](https://zerotier.com)

---

## Step 8: Set Up Backups (20 min)

```bash
# Create backup pool (if separate drives available)
sudo zpool create backup mirror /dev/sdh /dev/sdi

# Create backup script directory
sudo mkdir -p /root/scripts/backup

# Download backup script
sudo curl -o /root/scripts/backup/automated_backup.sh \
  https://raw.githubusercontent.com/yourusername/NAS_deploy/main/scripts/backup/automated_backup.sh

# Make executable
sudo chmod +x /root/scripts/backup/automated_backup.sh

# Add to crontab
(sudo crontab -l 2>/dev/null; echo "0 3 * * * /root/scripts/backup/automated_backup.sh") | sudo crontab -
```

---

## Step 9: Install Services (30 min)

### Plex Media Server

```bash
# Add Plex repository
echo deb https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plexmediaserver.list
curl https://downloads.plex.tv/plex-keys/PlexSign.key | sudo apt-key add -

# Install Plex
sudo apt update
sudo apt install plexmediaserver -y

# Start Plex
sudo systemctl start plexmediaserver
sudo systemctl enable plexmediaserver
```

**Access Plex:** `http://<vm-ip>:32400/web`

### Samba File Sharing (Optional)

```bash
# Install Samba
sudo apt install samba -y

# Configure share
sudo nano /etc/samba/smb.conf

# Add:
[shared]
    path = /tank/encrypted/share
    browseable = yes
    writable = yes
    valid users = @users

# Restart Samba
sudo systemctl restart smbd
```

---

## Step 10: Set Up Monitoring (20 min)

```bash
# Install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.7.0/node_exporter-1.7.0.linux-amd64.tar.gz
tar xvfz node_exporter-1.7.0.linux-amd64.tar.gz
sudo mv node_exporter-1.7.0.linux-amd64/node_exporter /usr/local/bin/
rm -rf node_exporter-1.7.0.linux-amd64*

# Create systemd service
sudo tee /etc/systemd/system/node_exporter.service > /dev/null <<EOF
[Unit]
Description=Node Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl start node_exporter
sudo systemctl enable node_exporter
```

---

## Verification Checklist

- [ ] Proxmox web UI accessible
- [ ] Debian VM running
- [ ] ZFS pool created and healthy
- [ ] SSH key authentication working
- [ ] Firewall enabled and configured
- [ ] VPN connected
- [ ] Backup script scheduled
- [ ] Services running (Plex, etc.)
- [ ] Monitoring active
- [ ] Remote access working

---

## Next Steps

1. **Create Users:** Set up user accounts and permissions
2. **Organize Storage:** Create datasets for different purposes
3. **Test Backups:** Verify backup and restore procedures
4. **Configure Monitoring:** Set up Grafana dashboards
5. **Optimize Performance:** Tune ZFS and network settings
6. **Documentation:** Keep records of your configuration

---

## Common Issues

### Can't access Proxmox web UI
```bash
# Check if service is running
systemctl status pveproxy

# Check firewall
iptables -L
```

### ZFS pool not mounting
```bash
# Check pool status
sudo zpool status

# Import pool
sudo zpool import tank

# Mount datasets
sudo zfs mount -a
```

### SSH connection refused
```bash
# Check SSH service
sudo systemctl status sshd

# Check firewall
sudo ufw status

# Verify port
sudo netstat -tlnp | grep 22
```

---

## Getting Help

- 📖 **Full Documentation:** See [README.md](../README.md)
- 🔧 **Troubleshooting:** See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
- ❓ **FAQ:** See [FAQ.md](FAQ.md)
- 📧 **Contact:** divyanshjoshi2022@vitbhopal.ac.in

---

## Quick Reference Commands

```bash
# ZFS
sudo zpool status              # Pool health
sudo zfs list                  # List datasets
sudo zfs snapshot tank@snap1   # Create snapshot
sudo zpool scrub tank          # Data integrity check

# Proxmox
qm list                        # List VMs
qm start <vmid>               # Start VM
qm stop <vmid>                # Stop VM
pvesm status                  # Storage status

# Monitoring
systemctl status <service>    # Service status
htop                          # Resource usage
df -h                         # Disk usage
netstat -tlnp                 # Network ports

# Backups
sudo zfs list -t snapshot     # List snapshots
sudo zfs send/receive         # Replicate data
```

---

**Congratulations! Your NAS server is now operational! 🎉**

For detailed configuration and optimization, refer to the full documentation.
