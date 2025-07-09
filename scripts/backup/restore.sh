#!/bin/bash
set -euo pipefail

# Database restore script
# Usage: ./restore.sh <backup_file> [stack_name]

if [ $# -lt 1 ]; then
    echo "Usage: $0 <backup_file> [stack_name]"
    echo "Example: $0 ./backup/store_production_20240101_120000.sql.gz"
    exit 1
fi

BACKUP_FILE=$1
STACK_NAME=${2:-klip_a}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.prod.yml}

# Database configuration
DB_NAME=${POSTGRES_DB:-store_production}
DB_USER=${POSTGRES_USER:-postgres}
DB_PASSWORD=${POSTGRES_PASSWORD:-password}

# Verify backup file exists
if [ ! -f "$BACKUP_FILE" ]; then
    echo "Error: Backup file $BACKUP_FILE does not exist"
    exit 1
fi

echo "Starting database restore for stack: $STACK_NAME"
echo "Backup file: $BACKUP_FILE"
echo "Database: $DB_NAME"

# Get postgres container ID
POSTGRES_CONTAINER=$(docker compose -f $COMPOSE_FILE -p $STACK_NAME ps -q postgres)

if [ -z "$POSTGRES_CONTAINER" ]; then
    echo "Error: Could not find postgres container for stack $STACK_NAME"
    exit 1
fi

# Confirmation prompt
echo "WARNING: This will overwrite the current database!"
echo "Database: $DB_NAME"
echo "Stack: $STACK_NAME"
read -p "Are you sure you want to continue? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Restore cancelled."
    exit 1
fi

# Stop application services to prevent connections during restore
echo "Stopping application services..."
docker compose -f $COMPOSE_FILE -p $STACK_NAME stop store waha

# Drop existing database and recreate
echo "Dropping and recreating database..."
docker exec $POSTGRES_CONTAINER psql -U $DB_USER -c "DROP DATABASE IF EXISTS $DB_NAME;"
docker exec $POSTGRES_CONTAINER psql -U $DB_USER -c "CREATE DATABASE $DB_NAME;"

# Restore from backup
echo "Restoring database from backup..."
if [[ $BACKUP_FILE == *.gz ]]; then
    gunzip -c "$BACKUP_FILE" | docker exec -i $POSTGRES_CONTAINER psql -U $DB_USER -d $DB_NAME
else
    docker exec -i $POSTGRES_CONTAINER psql -U $DB_USER -d $DB_NAME < "$BACKUP_FILE"
fi

echo "Database restore completed successfully!"

# Restart application services
echo "Restarting application services..."
docker compose -f $COMPOSE_FILE -p $STACK_NAME up -d store waha

echo "Services restarted. Restore completed!"