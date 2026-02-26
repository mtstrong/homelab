# Production Proxmox Infrastructure

This directory contains Terraform configuration for managing your production Kubernetes cluster across three Proxmox nodes: `um773a`, `um773b`, and `um773c`.

## Architecture

```
um773a          um773b          um773c
├─ k3s-control-a  ├─ k3s-control-b  ├─ k3s-control-c  (Control Planes)
├─ k3s-worker-1   ├─ k3s-worker-3   ├─ k3s-worker-5   (Workers)
├─ k3s-worker-2   ├─ k3s-worker-4   ├─ k3s-worker-6
└─ lh-01          └─ lh-02          └─ lh-03           (Longhorn Storage)
```

**Total Infrastructure:**
- 3 Control Plane VMs (1 per node for HA)
- 6 Worker VMs (2 per node)
- 3 Longhorn Storage VMs (1 per node)
- **Total: 12 VMs**

## Setup

### 1. Configure GitHub Secrets

Add these secrets to your GitHub repository settings:

```
PROXMOX_TOKEN_ID       = terraform@pam!terraform
PROXMOX_TOKEN_SECRET   = xxxxx-xxxxx-xxxxx-xxxxx  # ⚠️ Use environment variables
CLOUD_INIT_PASSWORD    = your-vm-password
```

**Path:** Settings → Secrets and variables → Actions

### 2. Local Development

For local `terraform plan` and `apply`:

```bash
cd terraform/proxmox-prod

# Export variables (or add to ~/.bashrc)
export TF_VAR_proxmox_token_id='terraform@pam!terraform'
export TF_VAR_proxmox_token_secret='709f991f-...'
export TF_VAR_cloud_init_password='your-vm-password'

# Initialize
terraform init

# Plan changes
terraform plan

# Apply (if changes are correct)
terraform apply
```

### 3. Monitor Drift Nightly

A GitHub Action runs every night at 2 AM UTC to detect drift:
- Compares actual infrastructure to Terraform configuration
- Creates an issue if differences are found
- Summarizes findings in workflow run

**View Results:**
- GitHub Actions tab → "Proxmox Drift Detection"
- Issues tab → Filter by `drift-detection` label

## Configuration

### terraform.tfvars

All infrastructure is defined in `terraform.tfvars`. Customize:

- **Node assignments** - Change which nodes host which VMs
- **VM specs** - CPU, memory, disk size
- **Network config** - IP addresses, VLAN tags
- **VM names** - Naming conventions

⚠️ **NEVER commit `terraform.tfvars`** - it contains sensitive data. Use `.gitignore` to prevent accidental commits.

### Modules

These inherit from the module registry at `../proxmox-modules/modules/`:

- `control_vm/` - High-spec control plane nodes (8 CPU, 8GB RAM)
- `worker_vm/` - Balanced worker nodes (8 CPU, 8GB RAM)
- `longhorn_vm/` - Storage nodes (4 CPU, 4GB RAM, 250GB disk)

## Operations

### View Current Infrastructure

```bash
terraform output cluster_topology
```

Shows all VMs, their status, and IP addresses.

### Update Infrastructure

```bash
# Make changes to terraform.tfvars
vim terraform.tfvars

# Preview changes
terraform plan

# Apply changes
terraform apply
```

### Add a New Worker Node

Example: Add worker-7 to um773a:

```hcl
# In terraform.tfvars:
"um773a-worker-3" = {
  name        = "k3s-worker-7"
  target_node = "um773a"
  vmid        = 202  # Increment VMID
  cores       = 8
  memory      = 8192
  disk_size   = "40G"
  ipconfig    = "ip=dhcp"
}
```

### Detect Drift Manually

```bash
# See what changed
terraform plan

# If drift detected (manual changes):
terraform plan -out=plan.tfplan
terraform show plan.tfplan
# Decide to apply or investigate
```

## Troubleshooting

### "Permission denied" errors

Verify API token in GitHub Secrets:
```bash
curl -k -H 'Authorization: PVEAPIToken=token' https://bd790i.local:8006/api2/json/version
```

### VM won't clone

Check:
- Template `ubuntu-cloud` exists and is stopped
- Template is on the target node
- Disk space available

### Drift keeps appearing

This usually means:
1. **Manual changes** - Someone edited VMs in UI instead of Terraform
2. **Stale state** - Run `terraform refresh`
3. **Config drift** - Update `terraform.tfvars` to match actual state

### How to Recover from Drift

```bash
# Option 1: Accept actual state (dangerous!)
terraform import proxmox_vm_qemu.vm_name <vmid>

# Option 2: Revert to config
terraform apply  # Forces config state

# Option 3: Manual fix
# Edit VMs in Proxmox UI to match terraform.tfvars
# Then run: terraform refresh
```

## Maintenance

### Backup State

GitHub Actions doesn't persist state by default. For prod, consider:

```bash
# Back up state file
terraform state pull > terraform.tfstate.bak

# Push to secure storage (not git!)
aws s3 cp terraform.tfstate s3://my-backups/ --sse
```

### State Locking

For multi-user teams, enable backend locking:

```hcl
# terraform.tf
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "proxmox-prod.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
  }
}
```

### Regular Audits

Run monthly:
```bash
terraform plan -out=audit.tfplan
terraform show audit.tfplan
# Review all VMs are as expected
```

## Disaster Recovery

To rebuild from Terraform state:

```bash
# Export current state
terraform state pull > state-backup.json

# On new machine:
git clone <repo>
cd terraform/proxmox-prod
terraform init
terraform state push state-backup.json
terraform plan  # Should show no changes
```

## Security Best Practices

1. ✅ Never commit `terraform.tfvars`
2. ✅ Rotate API tokens every 90 days
3. ✅ Use GitHub Secrets for sensitive data
4. ✅ Review `terraform plan` before `apply`
5. ✅ Enable audit logging on Proxmox
6. ✅ Restrict who can merge to main branch
7. ✅ Use separate tokens for dev/prod environments

## Support

For issues or questions:
- Check GitHub Issues (labeled `proxmox`, `infrastructure`)
- Review workflow logs: Actions → Proxmox Drift Detection
- Run local `terraform plan` for diagnostics
