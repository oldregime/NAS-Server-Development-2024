#!/bin/bash
###############################################################################
# Automated ZFS Backup Script
# Description: Creates snapshots and replicates to backup pool
# Author: Divyansh Joshi
# Date: 2024-12-01
###############################################################################

set -euo pipefail

# Configuration
SOURCE_POOL="tank/encrypted"
BACKUP_POOL="backup"
LOG_FILE="/var/log/nas_backup.log"
RETENTION_DAYS=30
DATE=$(date +%Y%m%d-%H%M%S)
SNAPSHOT_NAME="backup-${DATE}"

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "${LOG_FILE}"
}

# Error handling
error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   error_exit "This script must be run as root"
fi

# Start backup process
log "Starting backup process..."

# Create snapshot
log "Creating snapshot: ${SOURCE_POOL}@${SNAPSHOT_NAME}"
zfs snapshot "${SOURCE_POOL}@${SNAPSHOT_NAME}" || error_exit "Failed to create snapshot"

# Get the last successful snapshot
LAST_SNAPSHOT=$(zfs list -H -t snapshot -o name "${SOURCE_POOL}" | grep backup | tail -n 2 | head -n 1)

# Perform incremental or full send
if [[ -n "${LAST_SNAPSHOT}" && "${LAST_SNAPSHOT}" != "${SOURCE_POOL}@${SNAPSHOT_NAME}" ]]; then
    log "Performing incremental backup from ${LAST_SNAPSHOT}"
    zfs send -i "${LAST_SNAPSHOT}" "${SOURCE_POOL}@${SNAPSHOT_NAME}" | \
        zfs receive -F "${BACKUP_POOL}/$(basename ${SOURCE_POOL})" || \
        error_exit "Incremental backup failed"
else
    log "Performing full backup"
    zfs send "${SOURCE_POOL}@${SNAPSHOT_NAME}" | \
        zfs receive -F "${BACKUP_POOL}/$(basename ${SOURCE_POOL})" || \
        error_exit "Full backup failed"
fi

# Verify backup
log "Verifying backup..."
BACKUP_SNAP="${BACKUP_POOL}/$(basename ${SOURCE_POOL})@${SNAPSHOT_NAME}"
if zfs list -H -t snapshot "${BACKUP_SNAP}" > /dev/null 2>&1; then
    log "Backup verified successfully"
else
    error_exit "Backup verification failed"
fi

# Prune old snapshots
log "Pruning snapshots older than ${RETENTION_DAYS} days..."
CUTOFF_DATE=$(date -d "${RETENTION_DAYS} days ago" +%Y%m%d)

for snap in $(zfs list -H -t snapshot -o name "${SOURCE_POOL}" | grep backup); do
    SNAP_DATE=$(echo "${snap}" | grep -oP '\d{8}' | head -1)
    if [[ "${SNAP_DATE}" -lt "${CUTOFF_DATE}" ]]; then
        log "Deleting old snapshot: ${snap}"
        zfs destroy "${snap}" || log "WARNING: Failed to delete ${snap}"
    fi
done

# Calculate backup size
BACKUP_SIZE=$(zfs list -H -o used "${BACKUP_POOL}/$(basename ${SOURCE_POOL})")
log "Current backup size: ${BACKUP_SIZE}"

# Send notification (optional)
# mail -s "NAS Backup Successful" admin@example.com < "${LOG_FILE}"

log "Backup process completed successfully"
exit 0
