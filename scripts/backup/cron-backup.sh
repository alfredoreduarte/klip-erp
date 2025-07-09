#!/bin/bash
set -euo pipefail

# Cron-friendly backup script
# Add to crontab: 0 2 * * * /path/to/cron-backup.sh

# Set up environment (important for cron jobs)
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

# Change to project directory
cd "$(dirname "$0")/../.."

# Load environment variables if they exist
if [ -f .env ]; then
    source .env
fi

# Set log file
LOG_FILE="/var/log/klip-backup.log"

# Function to log with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "Starting automated backup"

# Run backup script
if ./scripts/backup/backup.sh >> "$LOG_FILE" 2>&1; then
    log "Backup completed successfully"
else
    log "Backup failed with exit code $?"
    # Send alert (uncomment and configure as needed)
    # echo "Backup failed on $(hostname)" | mail -s "Backup Failure" admin@example.com
fi

log "Automated backup finished"