#!/bin/bash
# Backup Uptime Kuma Database from ECS

set -e

CLUSTER_NAME="${1:-uptime-kuma-cluster}"
SERVICE_NAME="${2:-uptime-kuma}"
BACKUP_DIR="${3:-./backups}"

echo "Backing up Uptime Kuma database..."

# Get the task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster "$CLUSTER_NAME" \
  --service-name "$SERVICE_NAME" \
  --query 'taskArns[0]' \
  --output text)

if [ -z "$TASK_ARN" ] || [ "$TASK_ARN" = "None" ]; then
  echo "Error: No running tasks found"
  exit 1
fi

echo "Found task: $TASK_ARN"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Generate backup filename with timestamp
BACKUP_FILE="$BACKUP_DIR/kuma-$(date +%Y%m%d-%H%M%S).db"

echo "Creating backup: $BACKUP_FILE"

# Execute command to cat the database
aws ecs execute-command \
  --cluster "$CLUSTER_NAME" \
  --task "$TASK_ARN" \
  --container uptime-kuma \
  --command "cat /app/data/kuma.db" \
  --interactive > "$BACKUP_FILE"

echo "Backup completed successfully!"
echo "Backup location: $BACKUP_FILE"

# Verify backup file
if [ -s "$BACKUP_FILE" ]; then
  SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
  echo "Backup size: $SIZE"
else
  echo "Warning: Backup file is empty!"
  exit 1
fi
