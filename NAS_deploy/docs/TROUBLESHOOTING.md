# Troubleshooting Guide

## Common Issues and Solutions

### ZFS Pool Issues

#### Issue: Pool not mounting after reboot
```bash
# Check pool status
sudo zpool status

# Import pool manually
sudo zpool import tank

# If pool is encrypted, load key
sudo zfs load-key tank/encrypted
sudo zfs mount tank/encrypted
```

#### Issue: Pool performance degradation
```bash
# Check fragmentation
sudo zpool list -v

# Run scrub to check for errors
sudo zpool scrub tank

# Check for high ARC miss rate
cat /proc/spl/kstat/zfs/arcstats | grep miss
```

### Network Issues

#### Issue: Cannot access NAS remotely
```bash
# Check VPN status
sudo zerotier-cli listnetworks

# Verify firewall rules
sudo ufw status verbose

# Test connectivity
ping <nas-ip>
traceroute <nas-ip>

# Check SSH service
sudo systemctl status sshd
```

#### Issue: Slow network transfer speeds
```bash
# Check network interface status
ip addr show
ethtool eth0

# Test bandwidth
iperf3 -s  # On server
iperf3 -c <server-ip>  # On client

# Check for packet loss
sudo tcpdump -i eth0
```

### Virtualization Issues

#### Issue: VM won't start
```bash
# Check Proxmox logs
tail -f /var/log/pve/tasks/active

# Check VM configuration
qm config <vmid>

# Verify storage availability
pvesm status

# Check resource usage
pvesh get /nodes/localhost/status
```

#### Issue: Poor VM performance
```bash
# Check CPU allocation
qm config <vmid> | grep cores

# Enable CPU host passthrough
qm set <vmid> --cpu host

# Check I/O delay
iostat -x 1

# Optimize storage settings
qm set <vmid> --scsi0 local-lvm:vm-<vmid>-disk-0,cache=writeback
```

### Backup Issues

#### Issue: Backup script fails
```bash
# Check disk space
df -h

# Verify ZFS snapshots
zfs list -t snapshot

# Check backup log
tail -f /var/log/nas_backup.log

# Manually test snapshot
sudo zfs snapshot tank/encrypted@test
sudo zfs send tank/encrypted@test | sudo zfs receive backup/test
```

#### Issue: Cannot restore from backup
```bash
# List available snapshots
zfs list -t snapshot

# Rollback to snapshot
sudo zfs rollback tank/encrypted@backup-YYYYMMDD

# Or restore specific file
sudo cp /tank/encrypted/.zfs/snapshot/backup-YYYYMMDD/path/to/file /restore/location/
```

### Security Issues

#### Issue: SSH key authentication not working
```bash
# Check SSH key permissions
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519
chmod 644 ~/.ssh/id_ed25519.pub

# Verify authorized_keys
cat ~/.ssh/authorized_keys

# Check SSH logs
sudo tail -f /var/log/auth.log

# Test with verbose output
ssh -vvv user@nas
```

#### Issue: Firewall blocking legitimate traffic
```bash
# Check firewall status
sudo ufw status numbered

# Delete problematic rule
sudo ufw delete <rule-number>

# Allow specific IP
sudo ufw allow from <ip-address> to any port 22

# Reset firewall (caution!)
sudo ufw reset
```

### Performance Issues

#### Issue: High CPU usage
```bash
# Identify CPU-intensive processes
top -o %CPU
htop

# Check for runaway processes
ps aux | sort -nrk 3,3 | head -n 5

# Limit process CPU
cpulimit -p <pid> -l 50
```

#### Issue: High memory usage
```bash
# Check memory usage
free -h
vmstat 1

# Identify memory hogs
ps aux | sort -nrk 4,4 | head -n 5

# Clear cache (careful!)
sync && echo 3 | sudo tee /proc/sys/vm/drop_caches
```

#### Issue: Disk I/O bottleneck
```bash
# Check I/O statistics
iostat -x 1

# Identify disk-heavy processes
iotop -o

# Check ZFS ARC statistics
arc_summary

# Optimize ZFS recordsize
sudo zfs set recordsize=128k tank/encrypted
```

### Service Issues

#### Issue: Plex not accessible
```bash
# Check Plex status
sudo systemctl status plexmediaserver

# Restart Plex
sudo systemctl restart plexmediaserver

# Check Plex logs
tail -f "/var/lib/plexmediaserver/Library/Application Support/Plex Media Server/Logs/Plex Media Server.log"

# Verify port is listening
sudo netstat -tlnp | grep 32400
```

#### Issue: Samba shares not accessible
```bash
# Check Samba status
sudo systemctl status smbd

# Test Samba configuration
testparm

# Check Samba logs
tail -f /var/log/samba/log.smbd

# Restart Samba
sudo systemctl restart smbd nmbd
```

### Hardware Issues

#### Issue: Disk failure detection
```bash
# Check SMART status
sudo smartctl -a /dev/sda

# Run short SMART test
sudo smartctl -t short /dev/sda

# Check for bad sectors
sudo badblocks -sv /dev/sda

# Replace failed disk in ZFS pool
sudo zpool replace tank /dev/sda /dev/sdh
```

#### Issue: High temperature
```bash
# Install monitoring tools
sudo apt install lm-sensors

# Detect sensors
sudo sensors-detect

# Check temperatures
sensors

# Check fan speeds
sensors | grep fan
```

## Diagnostic Commands

### System Information
```bash
# System overview
neofetch

# Hardware info
sudo lshw -short

# CPU info
lscpu

# Memory info
sudo dmidecode -t memory

# PCI devices
lspci -v

# USB devices
lsusb -v
```

### Network Diagnostics
```bash
# Network interfaces
ip link show

# Routing table
ip route show

# DNS resolution
dig google.com

# Network statistics
ss -tulpn
netstat -tulpn
```

### Storage Diagnostics
```bash
# Block devices
lsblk -f

# Disk usage
df -h

# Inode usage
df -i

# ZFS pool I/O statistics
zpool iostat -v 1

# Disk SMART health
sudo smartctl -H /dev/sda
```

## Emergency Recovery

### Boot into Recovery Mode
1. Reboot system
2. Select recovery mode from GRUB
3. Mount filesystems:
```bash
sudo mount -a
sudo zfs mount -a
```

### Reset Root Password
```bash
# Boot into recovery mode
# Remount root as read-write
mount -o remount,rw /

# Change password
passwd root

# Reboot
reboot
```

### Repair Filesystem
```bash
# For ext4
sudo fsck.ext4 -f /dev/sda1

# For ZFS
sudo zpool scrub tank
```

## Getting Help

If you can't resolve the issue:

1. **Check Logs**: Always start with system logs
   ```bash
   sudo journalctl -xe
   tail -f /var/log/syslog
   ```

2. **Community Support**:
   - Proxmox Forums
   - Reddit r/homelab, r/DataHoarder
   - Stack Overflow

3. **Professional Support**:
   - Proxmox Enterprise Support
   - Red Hat Support (for enterprise)

4. **Contact Project Author**:
   - Email: divyanshjoshi2022@vitbhopal.ac.in
   - Create GitHub issue
