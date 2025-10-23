# Security Best Practices

## Authentication & Access Control

### SSH Security
- ✅ Use ED25519 keys (not RSA)
- ✅ Disable password authentication
- ✅ Disable root login
- ✅ Use non-standard SSH port (optional)
- ✅ Implement fail2ban for brute-force protection

### User Management
```bash
# Create service account with restricted permissions
sudo useradd -r -s /bin/false nasservice

# Set up proper file permissions
sudo chown -R nasservice:nasservice /tank/encrypted
sudo chmod 750 /tank/encrypted
```

## Encryption

### ZFS Native Encryption
```bash
# Enable encryption on dataset
sudo zfs create -o encryption=aes-256-gcm \
                -o keyformat=passphrase \
                -o keylocation=file:///root/.zfs-key \
                tank/encrypted

# Change encryption key
sudo zfs change-key tank/encrypted
```

### Network Encryption
- Use VPN (ZeroTier/Tailscale) for all remote access
- Enable TLS for web interfaces
- Use SFTP instead of FTP

## Firewall Configuration

### UFW Rules
```bash
# Default deny
sudo ufw default deny incoming

# Allow only necessary ports
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
sudo ufw allow from 10.147.17.0/24 to any port 22 proto tcp  # ZeroTier network

# Enable logging
sudo ufw logging on
```

### Fail2Ban
```bash
# Install
sudo apt install fail2ban

# Configure
sudo nano /etc/fail2ban/jail.local

[sshd]
enabled = true
port = 22
maxretry = 3
bantime = 3600
```

## Monitoring & Auditing

### Audit Logging
```bash
# Install auditd
sudo apt install auditd

# Monitor file access
sudo auditctl -w /tank/encrypted -p rwa -k nas_access

# View logs
sudo ausearch -k nas_access
```

### Security Scanning
```bash
# Install lynis
sudo apt install lynis

# Run security audit
sudo lynis audit system
```

## Backup Security

### Encrypted Backups
```bash
# Encrypt backup before offsite transfer
tar -czf - /backup | openssl enc -aes-256-cbc -salt > backup.tar.gz.enc

# Decrypt
openssl enc -d -aes-256-cbc -in backup.tar.gz.enc | tar xzf -
```

### 3-2-1 Backup Rule
- 3 copies of data
- 2 different media types
- 1 offsite copy

## Vulnerability Management

### Regular Updates
```bash
# Automated security updates
sudo apt install unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

### CVE Monitoring
- Subscribe to security mailing lists
- Monitor Proxmox/Debian security advisories
- Regular vulnerability scans

## Incident Response Plan

### Detection
1. Monitor logs for suspicious activity
2. Set up alerts for failed login attempts
3. Monitor unusual network traffic

### Response
1. Isolate affected systems
2. Preserve evidence (logs, snapshots)
3. Investigate root cause
4. Apply fixes and patches
5. Document incident

### Recovery
1. Restore from clean backups
2. Verify system integrity
3. Change all credentials
4. Update security measures

## Compliance Checklist

- [ ] Regular security audits
- [ ] Documented access control policies
- [ ] Encrypted data at rest and in transit
- [ ] Regular backup testing
- [ ] Incident response plan
- [ ] Security awareness training
- [ ] Vulnerability scanning
- [ ] Log retention policy
