#!/bin/bash
set -euo pipefail

echo "Starting WAHA service..."

# Wait for dependencies to be ready
echo "Waiting for dependencies..."
sleep 5

# Set default environment variables
export WAHA_SESSION_NAME=${WAHA_SESSION_NAME:-default}
export WAHA_PORT=${WAHA_PORT:-3000}
export WAHA_HOST=${WAHA_HOST:-0.0.0.0}

# Start WAHA
echo "Starting WAHA with session: $WAHA_SESSION_NAME"
exec npm start