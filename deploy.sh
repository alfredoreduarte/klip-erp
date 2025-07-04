#!/usr/bin/env bash
set -euo pipefail

# Blue-green deployment script
# Usage: ./deploy.sh <version_tag>
# If no tag supplied, uses current git SHA.

TAG=${1:-$(git rev-parse --short HEAD)}
PROJECT_NAME=${PROJECT_NAME:-klip}
STACK_A=${PROJECT_NAME}_a
STACK_B=${PROJECT_NAME}_b

ACTIVE_STACK=$(docker ps --filter "label=klip.active=1" --format '{{.Names}}' | head -n1 | cut -d"_" -f1)
if [ -z "$ACTIVE_STACK" ]; then
  ACTIVE_STACK=$STACK_A
fi
NEXT_STACK=$STACK_B
if [ "$ACTIVE_STACK" == "$STACK_B" ]; then
  NEXT_STACK=$STACK_A
fi

echo "Active stack: $ACTIVE_STACK"
echo "Deploying to: $NEXT_STACK (image tag $TAG)"

# Build & push images (assumes CI already pushed); fallback build locally
( docker compose -p $NEXT_STACK build --build-arg IMAGE_TAG=$TAG )

# Bring up next stack detached
( docker compose -p $NEXT_STACK up -d )

# Wait for health (basic sleep; enhance with curl check)
sleep 15

# Label new containers as active for Traefik switch
for cid in $(docker compose -p $NEXT_STACK ps -q); do
  docker container update --label-add klip.active=1 $cid
done
# Remove active label from old stack
for cid in $(docker compose -p $ACTIVE_STACK ps -q | xargs); do
  docker container update --label-rm klip.active $cid || true
done

echo "Switched traffic to $NEXT_STACK"

echo "Removing old stack in 30s..."
sleep 30
docker compose -p $ACTIVE_STACK down