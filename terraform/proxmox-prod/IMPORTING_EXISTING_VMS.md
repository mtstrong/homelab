# Importing Existing VMs into Terraform

Your VMs already exist in Proxmox, so instead of creating new ones, we need to **import** them into Terraform state.

## Current Infrastructure

**Control Plane Nodes (3):**
- k3s-01 (vmid 201) on um773a
- k3s-02 (vmid 202) on um773b
- k3s-03 (vmid 203) on um773c

**Worker Nodes (3):**
- k3s-04 (vmid 204) on um773b
- k3s-05 (vmid 205) on um773c
- k3s-06 (vmid 206) on um773a

**Longhorn Storage Nodes (3):**
- lh-01 (vmid 250) on um773a
- lh-02 (vmid 251) on um773b
- lh-03 (vmid 252) on um773c

**Total: 9 VMs**

## Prerequisites

Before importing, you need to set your Proxmox credentials:

```bash
export PROXMOX_TOKEN_ID="terraform@pam!terraform"
export PROXMOX_TOKEN_SECRET="your-actual-token-secret"
export TF_VAR_proxmox_token_id="$PROXMOX_TOKEN_ID"
export TF_VAR_proxmox_token_secret="$PROXMOX_TOKEN_SECRET"
export TF_VAR_cloud_init_password="your-cloud-init-password"
```

## Import Process

1. **Ensure terraform.tfvars matches your actual VMs:**
   ```bash
   cd /home/matt/code/homelab/terraform/proxmox-prod
   cat terraform.tfvars
   ```

2. **Initialize Terraform (if not already done):**
   ```bash
   terraform init
   ```

3. **Run the import script:**
   ```bash
   ./import-existing-vms.sh
   ```

4. **Verify no drift:**
   ```bash
   terraform plan
   ```

   You want to see: **"No changes. Your infrastructure matches the configuration."**

## Resolving Drift

If `terraform plan` shows differences, it means your `terraform.tfvars` doesn't exactly match your actual VM configuration.

Common differences:
- **Disk size** (actual may be 30G vs configured 40G)
- **Memory** (actual may be 16GB vs configured 8GB)
- **CPU cores** (actual may be 4 vs configured 8)
- **Network config** (static IP vs DHCP)

### Option 1: Update terraform.tfvars to match reality (recommended)
Query actual VM specs and update terraform.tfvars to match.

### Option 2: Apply changes to make VMs match config
If you want to standardize and terraform.tfvars is correct:
```bash
terraform apply
```

⚠️ **Warning:** This will modify running VMs! Review the plan carefully first.

## Testing the Import

After import, you can test various operations:

```bash
# Show imported state
terraform show

# View specific resources
terraform state list

# Check a specific VM's state
terraform state show 'module.control["k3s-01"]'

# Generate outputs (cluster topology)
terraform output cluster_topology
```

## Manual Import (if needed)

If the script fails, you can import VMs one at a time:

```bash
# Control nodes
terraform import 'module.control["k3s-01"]' um773a/qemu/201
terraform import 'module.control["k3s-02"]' um773b/qemu/202
terraform import 'module.control["k3s-03"]' um773c/qemu/203

# Worker nodes
terraform import 'module.workers["k3s-04"]' um773b/qemu/204
terraform import 'module.workers["k3s-05"]' um773c/qemu/205
terraform import 'module.workers["k3s-06"]' um773a/qemu/206

# Longhorn nodes
terraform import 'module.longhorn["lh-01"]' um773a/qemu/250
terraform import 'module.longhorn["lh-02"]' um773b/qemu/251
terraform import 'module.longhorn["lh-03"]' um773c/qemu/252
```

## Troubleshooting

**Error: "resource already exists in state"**
- The VM was already imported. You can skip it or remove from state first:
  ```bash
  terraform state rm 'module.control["k3s-01"]'
  ```

**Error: "authentication failed"**
- Check your PROXMOX_TOKEN_ID and PROXMOX_TOKEN_SECRET environment variables
- Verify the token exists in Proxmox and has correct permissions

**Error: "VM not found"**
- Verify the VMID and node name are correct
- Check that the VM exists: `pvesh get /nodes/{NODE}/qemu/{VMID}/status/current`
