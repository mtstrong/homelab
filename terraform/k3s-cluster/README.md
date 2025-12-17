# Terraform K3s Cluster Configuration for Proxmox

This Terraform configuration manages a high-availability K3s cluster across multiple Proxmox hosts.

## Cluster Architecture

- **3 Master Nodes**: Distributed across 3 Proxmox hosts for HA
  - `k3s-01` (192.168.2.106) on um773a - VMID 201
  - `k3s-02` (192.168.2.102) on um773b - VMID 202
  - `k3s-03` (192.168.2.103) on um773c - VMID 203

- **2 Worker Nodes**: Distributed across Proxmox hosts
  - `k3s-04` (192.168.2.104) on um773b - VMID 204
  - `k3s-05` (192.168.2.105) on um773c - VMID 205

- **3 Longhorn Storage Nodes**: Distributed across 3 Proxmox hosts for HA
  - `lh-01` (192.168.2.107) on um773a - VMID 250
  - `lh-02` (192.168.2.108) on um773b - VMID 251
  - `lh-03` (192.168.2.109) on um773c - VMID 252

## Prerequisites

### 1. Terraform
Install Terraform >= 1.0.0:
```bash
# On Ubuntu/Debian
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform
```

### 2. Proxmox Template
Create a cloud-init enabled Ubuntu template on **all three Proxmox hosts**:

```bash
# Download Ubuntu cloud image
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Create VM template (run on each Proxmox host)
qm create 9000 --name ubuntu-22.04-cloud-init --memory 2048 --net0 virtio,bridge=vmbr0
qm importdisk 9000 jammy-server-cloudimg-amd64.img local-lvm
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1
qm template 9000
```

### 3. Proxmox API User (Optional)
For better security, create a dedicated Terraform user instead of using root:

```bash
# On each Proxmox host
pveum user add terraform@pve
pveum passwd terraform@pve
pveum roleadd TerraformProv -privs "VM.Allocate VM.Clone VM.Config.CDROM VM.Config.CPU VM.Config.Cloudinit VM.Config.Disk VM.Config.HWType VM.Config.Memory VM.Config.Network VM.Config.Options VM.Monitor VM.Audit VM.PowerMgmt Datastore.AllocateSpace Datastore.Audit"
pveum aclmod / -user terraform@pve -role TerraformProv
```

## Setup

### 1. Clone and Configure
```bash
cd /home/matt/code/homelab/terraform/k3s-cluster

# Create your variables file from the example
cp terraform.tfvars.example terraform.tfvars

# Edit with your actual values
nano terraform.tfvars
```

### 2. Configure `terraform.tfvars`
```hcl
# Proxmox API URLs
um773a_api_url = "https://192.168.2.xxx:8006/api2/json"
um773b_api_url = "https://192.168.2.xxx:8006/api2/json"
um773c_api_url = "https://192.168.2.xxx:8006/api2/json"

# Credentials
pm_user     = "root@pam"  # or "terraform@pve"
pm_password = "your-secure-password"

# SSH Key
ssh_public_key = file("~/.ssh/id_ed25519.pub")

# Template name (must exist on all hosts)
template_name = "ubuntu-22.04-cloud-init"

# Network settings
gateway      = "192.168.2.1"
nameserver   = "192.168.2.1"
```

### 3. Initialize Terraform
```bash
terraform init
```

## Usage

### Plan Changes
Review what Terraform will create:
```bash
terraform plan
```

### Apply Configuration
Create the VMs:
```bash
terraform apply
```

### View Outputs
After applying, view cluster information:
```bash
# All outputs
terraform output

# Specific output
terraform output cluster_summary
terraform output ansible_inventory
```

### Generate Ansible Inventory
```bash
terraform output -raw ansible_inventory > ../../ansible/inventory/k3s-cluster.ini
```

## Customization

### Change VM Resources
Edit `variables.tf` or override in `terraform.tfvars`:

```hcl
# Master nodes
master_cores     = 4
master_memory    = 8192
master_disk_size = "64G"

# Worker nodes
worker_cores     = 8
worker_memory    = 16384
worker_disk_size = "128G"

# Longhorn storage nodes
longhorn_cores     = 4
longhorn_memory    = 4096
longhorn_disk_size = "250G"
```

### Change IP Addresses
Edit the `master_nodes` and `worker_nodes` variables in `variables.tf`:

```hcl
variable "master_nodes" {
  default = {
    master1 = {
      vmid        = 201
      hostname    = "k3s-01"
      ip_address  = "192.168.2.106"
      target_node = "um773a"
    }
    # ... more nodes
  }
}

# Or for worker nodes
variable "worker_nodes" {
  default = {
    worker1 = {
      vmid        = 204
      hostname    = "k3s-04"
      ip_address  = "192.168.2.104"
      target_node = "um773b"
    }
    # ... more nodes
  }
}

# Or for Longhorn nodes
variable "longhorn_nodes" {
  default = {
    longhorn1 = {
      vmid        = 250
      hostname    = "lh-01"
      ip_address  = "192.168.2.107"
      target_node = "um773a"
    }
    # ... more nodes
  }
}
```

### Change VMID Range
If you have conflicts with existing VMs, update the `vmid` values in `variables.tf`.

## Maintenance

### Update VMs
After modifying the configuration:
```bash
terraform plan
terraform apply
```

### Destroy VMs
**Warning: This will delete all VMs!**
```bash
terraform destroy
```

### Destroy Specific Node
```bash
# Destroy a specific worker node
terraform destroy -target=proxmox_vm_qemu.k3s_worker2

# Destroy a specific Longhorn node
terraform destroy -target=proxmox_vm_qemu.lh_node1
```

## Integration with k3s.sh

After Terraform creates the VMs, you can use your existing `k3s.sh` script to install K3s:

```bash
cd /home/matt
./k3s.sh
```

The IP addresses and node configuration in `k3s.sh` already match this Terraform configuration.

## Troubleshooting

### Template Not Found
Ensure the template exists on all Proxmox hosts:
```bash
qm list | grep ubuntu-22.04-cloud-init
```

### Connection Issues
1. Verify Proxmox API URLs are correct
2. Check credentials
3. Ensure TLS certificate is valid or set `pm_tls_insecure = true`

### VM Won't Start
1. Check VM logs in Proxmox UI
2. Verify storage has enough space
3. Ensure network bridge exists

### Cloud-init Not Working
1. Verify template has cloud-init configured
2. Check that qemu-guest-agent is installed in template
3. Review cloud-init logs: `ssh homelab@IP "cloud-init status --long"`

## State Management

The Terraform state file (`terraform.tfstate`) contains sensitive information. Consider:

### Using Remote State (Recommended)
```hcl
# backend.tf
terraform {
  backend "s3" {
    bucket = "my-terraform-state"
    key    = "k3s-cluster/terraform.tfstate"
    region = "us-east-1"
  }
}
```

### Backup State Regularly
```bash
cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d)
```

## Additional Resources

- [Terraform Proxmox Provider Docs](https://registry.terraform.io/providers/Telmate/proxmox/latest/docs)
- [K3s Documentation](https://docs.k3s.io/)
- [Proxmox Cloud-Init Guide](https://pve.proxmox.com/wiki/Cloud-Init_Support)

## File Structure

```
k3s-cluster/
├── provider.tf              # Proxmox provider configuration
├── variables.tf             # Variable definitions
├── main.tf                  # VM resources
├── outputs.tf               # Output definitions
├── terraform.tfvars.example # Example variables file
├── terraform.tfvars         # Your variables (gitignored)
└── README.md               # This file
```

## VM Resource Summary

| Node Type | Count | CPU Cores | Memory | Disk | Purpose |
|-----------|-------|-----------|--------|------|---------|
| Master | 3 | 4 | 8GB | 64GB | K3s control plane nodes |
| Worker | 2 | 8 | 16GB | 128GB | K3s workload nodes |
| Longhorn | 3 | 4 | 4GB | 250GB | Distributed storage nodes |
| **Total** | **8** | **36** | **60GB** | **1.1TB** | Full cluster |

## Notes

- This configuration uses the Telmate Proxmox provider v2.9.x
- VMs are configured with cloud-init for automatic provisioning
- Network uses static IPs (no DHCP)
- QEMU guest agent is enabled for better VM management
- Storage uses `local-lvm` by default (adjust if using different storage)
- Longhorn nodes provide distributed block storage for persistent volumes
- All node types are distributed across the three Proxmox hosts for high availability
