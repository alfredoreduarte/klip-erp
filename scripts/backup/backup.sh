#!/bin/bash
set -euo pipefail

# Database backup script with rotation
# Usage: ./backup.sh [stack_name]

STACK_NAME=${1:-klip_a}
BACKUP_DIR=${BACKUP_DIR:-./backup}
RETENTION_DAYS=${RETENTION_DAYS:-7}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.prod.yml}

# Database configuration
DB_NAME=${POSTGRES_DB:-store_production}
DB_USER=${POSTGRES_USER:-postgres}
DB_PASSWORD=${POSTGRES_PASSWORD:-password}

# Create backup directory
mkdir -p $BACKUP_DIR

echo "Starting database backup for stack: $STACK_NAME"
echo "Backup directory: $BACKUP_DIR"
echo "Retention period: $RETENTION_DAYS days"

# Get postgres container ID
POSTGRES_CONTAINER=$(docker compose -f $COMPOSE_FILE -p $STACK_NAME ps -q postgres)

if [ -z "$POSTGRES_CONTAINER" ]; then
    echo "Error: Could not find postgres container for stack $STACK_NAME"
    exit 1
fi

# Create backup filename
BACKUP_FILE="$BACKUP_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

echo "Creating backup: $BACKUP_FILE"

# Perform backup
docker exec $POSTGRES_CONTAINER pg_dump -U $DB_USER -d $DB_NAME | gzip > $BACKUP_FILE

# Verify backup was created
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file was not created"
    exit 1
fi

# Get backup size
BACKUP_SIZE=$(stat -c%s "$BACKUP_FILE")
echo "Backup created successfully: $BACKUP_FILE ($BACKUP_SIZE bytes)"

# Clean up old backups
echo "Cleaning up backups older than $RETENTION_DAYS days..."
find $BACKUP_DIR -name "*.sql.gz" -type f -mtime +$RETENTION_DAYS -delete

# List remaining backups
echo "Remaining backups:"
ls -lh $BACKUP_DIR/*.sql.gz 2>/dev/null || echo "No backups found"

echo "Backup completed successfully!"