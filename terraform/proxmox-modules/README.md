# Proxmox Terraform Modules

This directory contains reusable Terraform modules for managing Proxmox infrastructure.

## Modules

### VM Module (`modules/vm`)

Provisions a Proxmox VM with support for cloning from templates, cloud-init, and flexible CPU/memory configuration.

**Key Features:**
- Clone from existing VM templates
- Cloud-init user data support
- Flexible CPU, memory, and disk configuration
- Network bridge selection
- Static or DHCP IP configuration

**Usage Example:**
```hcl
module "my_vm" {
  source = "./modules/vm"
  
  vm_name        = "my-server"
  target_node    = "proxmox-node-1"
  vmid           = 100
  clone_template = "ubuntu-22.04-cloud"
  cores          = 4
  memory         = 4096
  disk_size      = "50G"
  ipconfig       = "ip=192.168.1.100/24,gw=192.168.1.1"
}
```

### Network Bridge Module (`modules/network_bridge`)

Manages network bridges on Proxmox nodes for VM networking.

**Key Features:**
- Create/manage network bridges
- Support for multiple addresses
- VLAN tagging support
- Route configuration

### Storage Module (`modules/storage`)

Manages storage pools on Proxmox.

**Key Features:**
- Support for LVMThin, Directory, and ZFS storage
- Content type specification
- Multi-node storage pools
- Validation of storage types

## Quick Start

### 1. Create API Token in Proxmox

In the Proxmox web UI:
- Navigate to Datacenter → Permissions → API Tokens
- Click "Add"
- Create a token for your terraform user
- Note the Token ID (e.g., `terraform@pam!terraform`)
- Copy the token secret (only shown once)

### 2. Set Up Terraform Variables

```bash
# Copy the example config
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual values
vim terraform.tfvars
```

### 3. Initialize and Plan

```bash
# Set sensitive variables (recommended way)
export TF_VAR_proxmox_token_id="terraform@pam!terraform"
export TF_VAR_proxmox_token_secret="your-token-secret"

# Initialize Terraform
terraform init

# Validate
terraform validate

# Plan
terraform plan
```

### 4. Create Infrastructure

```bash
# Create the VMs
terraform apply

# Check outputs
terraform output
```

## Cloud-Init

To use cloud-init for VM provisioning, ensure your template supports cloud-init. Ubuntu cloud images do by default.

You can pass custom user-data via the `ipconfig` variable or extend the VM module to support a `user_data` parameter.

## Security Considerations

1. **Never commit terraform.tfvars** - use `.gitignore`
2. **Use environment variables for sensitive data:**
   ```bash
   export TF_VAR_proxmox_token_secret="your-secret"
   export TF_VAR_cloud_init_password="vm-password"
   ```
3. **Enable TLS verification** in production by setting `proxmox_tls_insecure = false`
4. **Manage API tokens** - rotate and revoke unused tokens

## Proxmox API Permissions

The terraform user/token needs the following permissions:
- Datastore.AllocateSpace
- Datastore.AllocateTemplate
- Datastore.AuditTemplate
- SDN.Allocate
- SDN.Audit
- SDN.Modify
- Sys.Audit
- VirtQueue.Audit
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
- Nodes.Audit
- Pool.Allocate

You can create a custom role with these permissions in Proxmox.

## Directory Structure

```
proxmox-um773a/
├── modules/
│   ├── vm/                 # VM provisioning module
│   ├── network_bridge/     # Network bridge configuration
│   └── storage/            # Storage pool management
├── main.tf                 # Root module using the modules
├── variables.tf            # Root module variables
├── outputs.tf              # Root module outputs
├── terraform.tfvars.example  # Example configuration
└── README.md               # This file
```

## Extending the Modules

To create a K3S cluster module combining VMs and K3S provisioning:

```hcl
# modules/k3s_cluster/main.tf
module "control_plane" {
  source = "../vm"
  # VM config for control plane
}

module "workers" {
  source = "../vm"
  for_each = var.worker_count # Create multiple workers
}

# Use file provisioner or cloud-init to install k3s-agent
```

## Troubleshooting

### "Permission denied" errors
- Verify API token has correct permissions
- Check token hasn't expired

### VM clone fails
- Ensure template VM exists on target node
- Template name matches exactly
- Template is stopped before cloning

### IP configuration issues
- Verify cloud-init is enabled in template
- Check network bridge is correctly configured
- Confirm IP range doesn't conflict with existing VMs

## Resources

- [Telmate Proxmox Provider Documentation](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [Proxmox VE API Documentation](https://pve.proxmox.com/pve-docs/api-viewer/)
- [Terraform Language Reference](https://www.terraform.io/language)
