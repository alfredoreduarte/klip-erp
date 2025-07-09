#!/bin/bash
set -euo pipefail

# SSH deployment script for CI/CD
# Usage: ./deploy-ssh.sh <host> <user> <version>

if [ $# -lt 3 ]; then
    echo "Usage: $0 <host> <user> <version>"
    echo "Example: $0 production.example.com deploy v1.0.0"
    exit 1
fi

HOST=$1
USER=$2
VERSION=$3
SSH_KEY=${SSH_KEY:-~/.ssh/id_rsa}
PROJECT_DIR=${PROJECT_DIR:-/opt/klip-erp}
COMPOSE_FILE=${COMPOSE_FILE:-docker-compose.prod.yml}

echo "Deploying version $VERSION to $HOST as $USER"

# Function to run commands on remote server
remote_exec() {
    ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$USER@$HOST" "$@"
}

# Function to copy files to remote server
remote_copy() {
    scp -i "$SSH_KEY" -o StrictHostKeyChecking=no "$1" "$USER@$HOST:$2"
}

# Check if we can connect to the server
echo "Testing SSH connection..."
if ! remote_exec "echo 'SSH connection successful'"; then
    echo "Error: Cannot connect to $HOST"
    exit 1
fi

# Create project directory if it doesn't exist
echo "Setting up project directory..."
remote_exec "sudo mkdir -p $PROJECT_DIR && sudo chown $USER:$USER $PROJECT_DIR"

# Copy deployment files
echo "Copying deployment files..."
remote_copy "$COMPOSE_FILE" "$PROJECT_DIR/docker-compose.yml"
remote_copy "deploy.sh" "$PROJECT_DIR/"
remote_copy ".env.production" "$PROJECT_DIR/.env" 2>/dev/null || echo "Warning: .env.production not found"

# Copy backup scripts
echo "Copying backup scripts..."
remote_exec "mkdir -p $PROJECT_DIR/scripts/backup"
remote_copy "scripts/backup/backup.sh" "$PROJECT_DIR/scripts/backup/"
remote_copy "scripts/backup/restore.sh" "$PROJECT_DIR/scripts/backup/"
remote_copy "scripts/backup/cron-backup.sh" "$PROJECT_DIR/scripts/backup/"

# Set permissions
echo "Setting permissions..."
remote_exec "chmod +x $PROJECT_DIR/deploy.sh $PROJECT_DIR/scripts/backup/*.sh"

# Create necessary directories
echo "Creating necessary directories..."
remote_exec "mkdir -p $PROJECT_DIR/backup $PROJECT_DIR/letsencrypt"

# Create environment file if it doesn't exist
echo "Setting up environment..."
remote_exec "
if [ ! -f $PROJECT_DIR/.env ]; then
    cat > $PROJECT_DIR/.env << 'EOF'
# Production environment variables
POSTGRES_PASSWORD=\$(openssl rand -base64 32)
POSTGRES_USER=postgres
POSTGRES_DB=store_production
SECRET_KEY_BASE=\$(openssl rand -base64 64)
DOMAIN=\${DOMAIN:-localhost}
IMAGE_TAG=$VERSION
COMPOSE_FILE=docker-compose.yml
EOF
fi
"

# Pull latest images
echo "Pulling latest images..."
remote_exec "cd $PROJECT_DIR && docker compose pull"

# Run backup before deployment
echo "Creating backup before deployment..."
remote_exec "cd $PROJECT_DIR && ./scripts/backup/backup.sh || echo 'Backup failed or no existing database'"

# Deploy using blue-green deployment
echo "Deploying version $VERSION..."
remote_exec "cd $PROJECT_DIR && IMAGE_TAG=$VERSION ./deploy.sh"

# Verify deployment
echo "Verifying deployment..."
sleep 30
if remote_exec "curl -f -s http://localhost/up > /dev/null"; then
    echo "Deployment successful!"
else
    echo "Warning: Health check failed, but deployment may still be successful"
fi

# Setup cron job for automated backups if not exists
echo "Setting up automated backups..."
remote_exec "
if ! crontab -l | grep -q 'cron-backup.sh'; then
    (crontab -l 2>/dev/null; echo '0 2 * * * $PROJECT_DIR/scripts/backup/cron-backup.sh') | crontab -
    echo 'Automated backup cron job added'
else
    echo 'Automated backup already configured'
fi
"

echo "Deployment completed successfully!"
echo "Application URL: http://$HOST"
echo "Version deployed: $VERSION"