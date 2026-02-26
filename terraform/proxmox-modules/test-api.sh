#!/bin/bash
TOKEN_ID="terraform@pam!terraform"
TOKEN_SECRET="${TF_VAR_proxmox_token_secret}"  # Use environment variable
PROXMOX_HOST="bd790i.local"
NODE="um773a"

echo "Testing connection to Proxmox API at https://${PROXMOX_HOST}:8006..."
curl -k -s --max-time 10 \
  -H "Authorization: PVEAPIToken=${TOKEN_ID}=${TOKEN_SECRET}" \
  "https://${PROXMOX_HOST}:8006/api2/json/nodes/${NODE}/qemu" | python3 -m json.tool 2>/dev/null || echo "Failed to connect"
