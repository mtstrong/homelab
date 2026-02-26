#!/bin/bash
TOKEN_ID="terraform@pam!terraform"
TOKEN_SECRET="${TF_VAR_proxmox_token_secret}"  # Use environment variable
PROXMOX_HOST="bd790i.local"
NODE="um773a"

echo "=== Fetching k3s-01 (Control Node) ==="
curl -k -s --max-time 10 \
  -H "Authorization: PVEAPIToken=${TOKEN_ID}=${TOKEN_SECRET}" \
  "https://${PROXMOX_HOST}:8006/api2/json/nodes/${NODE}/qemu/201/config" | python3 -m json.tool

echo ""
echo "=== Fetching k3s-06 (Worker Node) ==="
curl -k -s --max-time 10 \
  -H "Authorization: PVEAPIToken=${TOKEN_ID}=${TOKEN_SECRET}" \
  "https://${PROXMOX_HOST}:8006/api2/json/nodes/${NODE}/qemu/206/config" | python3 -m json.tool
