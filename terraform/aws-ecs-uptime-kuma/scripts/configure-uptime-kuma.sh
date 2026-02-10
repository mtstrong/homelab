#!/bin/bash
# Uptime Kuma Configuration Bootstrap Script
# This script configures Uptime Kuma via API after initial deployment

set -e

# Configuration
UPTIME_KUMA_URL="${UPTIME_KUMA_URL:-http://localhost:3001}"
ADMIN_USERNAME="${ADMIN_USERNAME:-admin}"
ADMIN_PASSWORD="${ADMIN_PASSWORD:-changeme}"

echo "Waiting for Uptime Kuma to be ready..."
until curl -sf "${UPTIME_KUMA_URL}" > /dev/null; do
  echo "Waiting..."
  sleep 5
done

echo "Uptime Kuma is ready!"

# Check if setup is needed (first run)
SETUP_NEEDED=$(curl -sf "${UPTIME_KUMA_URL}/api/status-page/config" | jq -r '.needSetup // true')

if [ "$SETUP_NEEDED" = "true" ]; then
  echo "Setting up admin account..."
  
  # Create admin account (first-time setup)
  curl -sf "${UPTIME_KUMA_URL}/api/setup" \
    -H "Content-Type: application/json" \
    -d "{
      \"username\": \"${ADMIN_USERNAME}\",
      \"password\": \"${ADMIN_PASSWORD}\"
    }"
  
  echo "Admin account created successfully!"
fi

# Login to get auth token
echo "Logging in..."
TOKEN=$(curl -sf "${UPTIME_KUMA_URL}/api/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"username\": \"${ADMIN_USERNAME}\",
    \"password\": \"${ADMIN_PASSWORD}\"
  }" | jq -r '.token')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
  echo "Failed to login. Please check credentials."
  exit 1
fi

echo "Logged in successfully!"

# Example: Create monitors from environment variables or config file
# You can customize this section based on your needs

# Example: Add a monitor
# curl -sf "${UPTIME_KUMA_URL}/api/monitor" \
#   -H "Content-Type: application/json" \
#   -H "Authorization: Bearer ${TOKEN}" \
#   -d '{
#     "name": "Example Monitor",
#     "type": "http",
#     "url": "https://example.com",
#     "interval": 60,
#     "retryInterval": 60,
#     "maxretries": 3
#   }'

echo "Configuration complete!"
