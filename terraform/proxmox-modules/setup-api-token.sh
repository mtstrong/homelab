#!/bin/bash
# Proxmox API Token Setup Guide and Test Script
# Run this after creating your API token to verify it works

set -e

echo "=== Proxmox API Token Setup Guide ==="
echo ""
echo "Step 1: Access Proxmox Web UI"
echo "  - Open your browser to: https://YOUR-PROXMOX-IP:8006"
echo "  - Login with your admin credentials"
echo ""
echo "Step 2: Navigate to API Tokens"
echo "  - Click on 'Datacenter' in the left sidebar"
echo "  - Click on 'Permissions'"
echo "  - Click on 'API Tokens'"
echo ""
echo "Step 3: Create User (if needed)"
echo "  - Go to Datacenter → Permissions → Users"
echo "  - Click 'Add'"
echo "  - Username: terraform"
echo "  - Realm: PAM or PVE"
echo "  - Click 'Add'"
echo ""
echo "Step 4: Create API Token"
echo "  - Back to Datacenter → Permissions → API Tokens"
echo "  - Click 'Add'"
echo "  - User: terraform@pam (or terraform@pve)"
echo "  - Token ID: terraform"
echo "  - UNCHECK 'Privilege Separation' (important!)"
echo "  - Click 'Add'"
echo ""
echo "Step 5: Copy Token Secret"
echo "  ⚠️  The secret is only shown ONCE - copy it immediately!"
echo "  - Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
echo ""
echo "Step 6: Set Permissions"
echo "  - Go to Datacenter → Permissions"
echo "  - Click 'Add' → 'User Permission'"
echo "  - Path: /"
echo "  - User: terraform@pam"
echo "  - Role: Administrator (or PVEVMAdmin for VMs only)"
echo "  - Click 'Add'"
echo ""
echo "==========================================="
echo ""

# Test API connection
echo "Would you like to test your API connection? (y/n)"
read -r response

if [[ "$response" =~ ^[Yy]$ ]]; then
    echo ""
    echo "Enter your Proxmox details:"
    read -p "Proxmox Host (e.g., 192.168.1.100): " PROXMOX_HOST
    read -p "Token ID (e.g., terraform@pam!terraform): " TOKEN_ID
    read -sp "Token Secret: " TOKEN_SECRET
    echo ""
    
    # Test the connection
    echo ""
    echo "Testing connection to https://${PROXMOX_HOST}:8006/api2/json/version..."
    
    response=$(curl -k -s \
        -H "Authorization: PVEAPIToken=${TOKEN_ID}=${TOKEN_SECRET}" \
        "https://${PROXMOX_HOST}:8006/api2/json/version")
    
    if echo "$response" | grep -q "version"; then
        echo "✅ SUCCESS! API connection working."
        echo ""
        echo "Response:"
        echo "$response" | python3 -m json.tool 2>/dev/null || echo "$response"
        echo ""
        echo "Your credentials are correct. Save them as:"
        echo ""
        echo "export TF_VAR_proxmox_token_id=\"${TOKEN_ID}\""
        echo "export TF_VAR_proxmox_token_secret=\"${TOKEN_SECRET}\""
        echo ""
    else
        echo "❌ FAILED! Could not connect to Proxmox API."
        echo "Response: $response"
        echo ""
        echo "Check:"
        echo "  - Proxmox host IP is correct"
        echo "  - Token ID format: user@realm!tokenname"
        echo "  - Token secret was copied correctly"
        echo "  - 'Privilege Separation' was UNCHECKED"
        echo "  - User has Administrator or PVEVMAdmin role"
    fi
fi
