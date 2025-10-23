# Configuration Reference

## Network Configuration

### Static IP Configuration
```bash
# /etc/network/interfaces
auto eth0
iface eth0 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
```

### VPN Configuration (ZeroTier)
```bash
# Join network
sudo zerotier-cli join <NETWORK_ID>

# Configure static IP in ZeroTier Central
# Managed Routes: 192.168.191.0/24
```

## Storage Configuration

### ZFS Pool Settings
```bash
# Compression
sudo zfs set compression=lz4 tank/encrypted

# Deduplication (use cautiously - RAM intensive)
sudo zfs set dedup=on tank/encrypted

# Auto-snapshot
sudo zfs set com.sun:auto-snapshot=true tank/encrypted
```

### NFS Export Configuration
```bash
# /etc/exports
/tank/encrypted/share 192.168.1.0/24(rw,sync,no_subtree_check,no_root_squash)

# Apply changes
sudo exportfs -ra
```

### Samba Configuration
```bash
# /etc/samba/smb.conf
[global]
    workgroup = WORKGROUP
    server string = NAS Server
    security = user
    map to guest = Bad User

[shared]
    path = /tank/encrypted/share
    browseable = yes
    writable = yes
    valid users = @users
```

## Backup Configuration

### Automated Backup Script
```bash
#!/bin/bash
# /root/scripts/automated_backup.sh

SOURCE_POOL="tank/encrypted"
BACKUP_POOL="backup"
DATE=$(date +%Y%m%d-%H%M)

# Create snapshot
zfs snapshot ${SOURCE_POOL}@backup-${DATE}

# Replicate to backup pool
zfs send ${SOURCE_POOL}@backup-${DATE} | zfs receive ${BACKUP_POOL}/$(basename ${SOURCE_POOL})-${DATE}

# Prune old backups (keep last 30 days)
find /backup -type d -mtime +30 -exec rm -rf {} \;
```

## Security Configuration

### SSH Hardening
```bash
# /etc/ssh/sshd_config
Port 22
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
PermitEmptyPasswords no
X11Forwarding no
MaxAuthTries 3
MaxSessions 2
```

### Firewall Rules
```bash
# UFW configuration
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp comment 'SSH'
sudo ufw allow 2049/tcp comment 'NFS'
sudo ufw allow 445/tcp comment 'Samba'
sudo ufw enable
```

## Monitoring Configuration

### Prometheus Configuration
```yaml
# /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'nas-server'
    static_configs:
      - targets: ['localhost:9100']
```

### Grafana Dashboard
Import dashboard ID: 1860 (Node Exporter Full)

## Performance Tuning

### ZFS ARC Cache
```bash
# /etc/modprobe.d/zfs.conf
options zfs zfs_arc_max=17179869184  # 16GB
options zfs zfs_arc_min=8589934592   # 8GB
```

### Network Optimization
```bash
# /etc/sysctl.conf
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
```
