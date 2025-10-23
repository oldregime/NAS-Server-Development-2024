# Frequently Asked Questions (FAQ)

## General Questions

### Q1: What is this project about?
**A:** This is an enterprise-grade Network Attached Storage (NAS) server implementation developed during an internship at LNJ Solution. It provides secure, scalable, and high-performance file storage with advanced features like RAID redundancy, automated backups, and remote access.

### Q2: Who is this project for?
**A:** This project is suitable for:
- Small to medium businesses needing centralized storage
- Home lab enthusiasts interested in enterprise NAS solutions
- Students learning about systems administration and virtualization
- Anyone looking to build a production-grade NAS server

### Q3: What are the key features?
**A:** 
- 99.9% data availability with RAID-Z2
- 20% faster file transfers through optimization
- Support for 15+ concurrent users
- Enterprise-grade security with encryption
- Automated backups and snapshots
- Remote access via VPN
- Comprehensive monitoring

---

## Hardware Questions

### Q4: What hardware is required?
**A:** Minimum specifications:
- **CPU:** Modern multi-core processor (Intel/AMD)
- **RAM:** 16GB minimum (32GB recommended)
- **Storage:** 6+ drives for RAID-Z2 (12TB+ total)
- **Network:** Gigabit Ethernet (dual NICs recommended)

### Q5: Can I use different hardware?
**A:** Yes! While this project uses specific hardware, you can adapt it to your setup. Key considerations:
- Ensure CPU supports virtualization (VT-x/AMD-V)
- ECC RAM is recommended but not mandatory
- More drives = better redundancy and performance

### Q6: What about storage capacity?
**A:** 
- **RAID-Z2:** Minimum 6 drives (loses 2 drives to parity)
- **Example:** 6× 2TB drives = 8TB usable (66% efficiency)
- **Recommended:** 6-12 drives for optimal balance

---

## Software Questions

### Q7: What operating systems are used?
**A:** 
- **Hypervisor:** Proxmox VE (open-source virtualization)
- **Primary OS:** Debian 12 (stable, enterprise-grade)
- **Storage:** TrueNAS SCALE (ZFS-based NAS)
- **Apps:** CasaOS (application management)

### Q8: Is everything free/open-source?
**A:** Yes! All core components are free and open-source:
- Proxmox VE: Open-source (enterprise support optional)
- Debian: Completely free
- TrueNAS: Open-source
- ZFS: Open-source file system

### Q9: Do I need licenses?
**A:** 
- **Proxmox VE:** Free (optional enterprise subscription)
- **Plex:** Free tier available, premium optional
- **Other services:** Mostly free/open-source

---

## Setup & Installation Questions

### Q10: How long does setup take?
**A:** 
- **Hardware assembly:** 1-2 days
- **Software installation:** 2-3 days
- **Configuration & testing:** 1 week
- **Total (with learning):** 2-3 weeks

### Q11: What skill level is required?
**A:** 
- **Beginner:** Can follow guide step-by-step
- **Intermediate:** Can customize and troubleshoot
- **Advanced:** Can optimize and extend functionality

### Q12: Is there an easier way?
**A:** Yes, alternatives include:
- Pre-built NAS devices (Synology, QNAP)
- Simpler OS (OMV, FreeNAS)
- Cloud storage (less control, recurring costs)

This project offers maximum control and learning opportunities.

---

## Performance Questions

### Q13: What performance can I expect?
**A:** With recommended hardware:
- **Sequential Read:** 400-600 MB/s
- **Sequential Write:** 350-500 MB/s
- **Random IOPS:** 10K-20K
- **Concurrent Users:** 15-20

### Q14: How can I improve performance?
**A:** 
- Add more RAM (increases ZFS ARC cache)
- Use SSDs for cache (L2ARC, ZIL)
- Upgrade to 10GbE network
- Optimize ZFS recordsize for workload

### Q15: What about power consumption?
**A:** Typical consumption:
- **Idle:** 80-120W
- **Active:** 150-200W
- **Peak:** 250-300W
Annual cost: ~₹5,000-8,000 (at ₹6/kWh)

---

## Security Questions

### Q16: How secure is this setup?
**A:** Very secure with multiple layers:
- SSH key-based authentication (no passwords)
- VPN encryption for remote access
- ZFS native encryption at rest
- Firewall with whitelist-only access
- Regular security updates

### Q17: What about ransomware protection?
**A:** Multiple protections:
- ZFS snapshots (immutable backups)
- Offsite backups (air-gapped)
- User permission controls
- Network segmentation

### Q18: Can it be hacked?
**A:** While no system is 100% secure:
- Strong authentication prevents most attacks
- Regular updates patch vulnerabilities
- Monitoring detects suspicious activity
- Backups ensure recovery

---

## Backup & Recovery Questions

### Q19: How does backup work?
**A:** Three-tier approach:
- **Hourly snapshots:** Quick recovery (24 hours)
- **Daily backups:** Separate pool (30 days)
- **Weekly offsite:** Cloud/external (1 year)

### Q20: How fast is recovery?
**A:** 
- **File-level:** Seconds to minutes
- **VM recovery:** 5-15 minutes
- **Full system:** 1-4 hours (depending on data size)

### Q21: What if a drive fails?
**A:** 
- RAID-Z2 tolerates 2 drive failures
- Replace failed drive while system runs
- Automatic rebuild (resilver) process
- No data loss with proper configuration

---

## Remote Access Questions

### Q22: How do I access remotely?
**A:** Multiple methods:
- **VPN (recommended):** ZeroTier or Tailscale
- **SSH tunnel:** Secure terminal access
- **Web interface:** Proxmox/TrueNAS GUI
- **Mobile apps:** Plex, file browsers

### Q23: Is remote access secure?
**A:** Yes, with proper configuration:
- All traffic encrypted via VPN
- No direct port exposure to internet
- SSH key authentication required
- Access logging and monitoring

### Q24: Can I access from anywhere?
**A:** Yes, from any device with:
- Internet connection
- VPN client installed
- Valid credentials
- Works globally

---

## Troubleshooting Questions

### Q25: What if something breaks?
**A:** 
1. Check documentation (TROUBLESHOOTING.md)
2. Review system logs
3. Check monitoring dashboard
4. Restore from backup if needed
5. Contact community for help

### Q26: How do I get support?
**A:** 
- **Documentation:** Comprehensive guides included
- **Community:** Forums (r/homelab, r/zfs)
- **Professional:** Proxmox support (paid)
- **Project author:** divyanshjoshi2022@vitbhopal.ac.in

### Q27: What about updates?
**A:** 
- Security updates: Automated
- System updates: Monthly recommended
- Major upgrades: Plan and test carefully
- Backup before major changes

---

## Cost Questions

### Q28: How much does it cost?
**A:** Approximate costs (India):
- **Hardware:** ₹40,000-80,000 (varies widely)
- **Software:** ₹0 (all open-source)
- **Power:** ₹5,000-8,000/year
- **Total first year:** ₹45,000-90,000

### Q29: Is it cheaper than cloud?
**A:** Long-term yes:
- Cloud (1TB): ₹6,000-12,000/year ongoing
- NAS (12TB): One-time cost, then minimal
- Break-even: 1-2 years for large storage

### Q30: What about maintenance costs?
**A:** Minimal ongoing costs:
- Electricity: ₹500-700/month
- Drive replacement: ₹5,000-10,000 every 3-5 years
- Optional: Enterprise support, UPS replacement

---

## Project-Specific Questions

### Q31: Can I use this commercially?
**A:** Yes! MIT License allows:
- Commercial use
- Modification
- Distribution
- Private use
Attribution appreciated but not required.

### Q32: Will you maintain this project?
**A:** 
- Active maintenance during internship (Dec 2024 - Mar 2025)
- Community contributions welcome afterward
- Documentation will remain available
- Fork and customize as needed

### Q33: Can I contribute?
**A:** Absolutely! See CONTRIBUTING.md for:
- Reporting issues
- Suggesting features
- Submitting improvements
- Documentation updates

---

## Additional Resources

### Useful Links
- [Proxmox Documentation](https://pve.proxmox.com/wiki/Main_Page)
- [ZFS Documentation](https://openzfs.github.io/openzfs-docs/)
- [TrueNAS Forum](https://www.truenas.com/community/)
- [r/homelab](https://reddit.com/r/homelab)

### Learning Resources
- [Proxmox VE Tutorial](https://www.youtube.com/proxmox)
- [ZFS 101](https://arstechnica.com/information-technology/2020/05/zfs-101-understanding-zfs-storage-and-performance/)
- [Linux Server Administration](https://www.linode.com/docs/guides/)

---

**Still have questions?**  
📧 Email: divyanshjoshi2022@vitbhopal.ac.in  
🐙 GitHub: Create an issue  
💬 Discussion: Start a discussion thread
