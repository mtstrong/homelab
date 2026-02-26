# Proxmox API Token Setup Guide

## Quick Setup (5 minutes)

### Step 1: Access Proxmox Web UI
Open your browser to your Proxmox server:
```
https://YOUR-PROXMOX-IP:8006
```
Login with root or an admin account.

### Step 2: Create Terraform User (Optional but Recommended)

1. Navigate: **Datacenter → Permissions → Users**
2. Click **Add**
3. Fill in:
   - **User name**: `terraform`
   - **Realm**: `PAM` (or `PVE`)
   - Leave password empty (we'll use token auth)
4. Click **Add**

### Step 3: Create API Token

1. Navigate: **Datacenter → Permissions → API Tokens**
2. Click **Add**
3. Fill in:
   - **User**: Select `terraform@pam` (or `terraform@pve`)
   - **Token ID**: `terraform`
   - **Privilege Separation**: ⚠️ **UNCHECK THIS BOX** (critical!)
4. Click **Add**

### Step 4: Save Token Secret

⚠️ **IMPORTANT**: The secret is only shown ONCE!

You'll see something like:
```
xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
```

**Save both values:**
- **Token ID**: `terraform@pam!terraform`
- **Token Secret**: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

### Step 5: Set Permissions

1. Navigate: **Datacenter → Permissions**
2. Click **Add → User Permission**
3. Fill in:
   - **Path**: `/` (root, gives access to all resources)
   - **User**: `terraform@pam`
   - **Role**: `Administrator` (or `PVEVMAdmin` for VM-only access)
   - **Propagate**: ✅ Checked
4. Click **Add**

### Step 6: Test Your Token

Run the setup script:
```bash
cd /home/matt/code/homelab/terraform/proxmox-modules
chmod +x setup-api-token.sh
./setup-api-token.sh
```

Or test manually:
```bash
curl -k -H "Authorization: PVEAPIToken=terraform@pam!terraform=YOUR-SECRET" \
  https://YOUR-PROXMOX-IP:8006/api2/json/version
```

You should see JSON output with version info.

### Step 7: Set Environment Variables

Add to your `~/.bashrc` or `~/.zshrc`:
```bash
export TF_VAR_proxmox_token_id="terraform@pam!terraform"
export TF_VAR_proxmox_token_secret="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
export TF_VAR_cloud_init_password="your-vm-password"  # For new VMs
```

Or for one-time use:
```bash
export TF_VAR_proxmox_token_id="terraform@pam!terraform"
export TF_VAR_proxmox_token_secret="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

## Troubleshooting

### "Permission denied" error
- Verify **Privilege Separation** is UNCHECKED
- Check user has **Administrator** or **PVEVMAdmin** role
- Ensure permission path is `/` with **Propagate** checked

### "Authentication failure" error
- Double-check token ID format: `user@realm!tokenname`
- Verify token secret was copied completely
- Check token hasn't been deleted/expired

### "Connection refused" error
- Verify Proxmox host IP address
- Check firewall allows port 8006
- Confirm Proxmox service is running

## Minimum Required Permissions

If you don't want to use Administrator role, create a custom role with:

**VM Permissions:**
- VM.Allocate
- VM.Audit
- VM.Clone
- VM.Config.CDROM
- VM.Config.Cloudinit
- VM.Config.CPU
- VM.Config.Disk
- VM.Config.HWType
- VM.Config.Memory
- VM.Config.Network
- VM.Config.Options
- VM.Monitor
- VM.PowerMgmt

**Storage Permissions:**
- Datastore.AllocateSpace
- Datastore.AllocateTemplate
- Datastore.Audit

**System Permissions:**
- Sys.Audit
- Pool.Allocate

## Security Best Practices

1. **Never commit tokens to git** - use environment variables
2. **Use dedicated terraform user** - don't use root token
3. **Enable TLS verification** in production (set `proxmox_tls_insecure = false`)
4. **Rotate tokens periodically** - create new ones every 90 days
5. **Limit scope** - use minimal required permissions
6. **Audit regularly** - review API token usage in Proxmox logs

## Next Steps

Once your token is working:
1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Fill in your Proxmox details
3. Run `terraform init`
4. Run `terraform plan`
