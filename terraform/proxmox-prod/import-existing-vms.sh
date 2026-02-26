#!/bin/bash
# Import existing Proxmox VMs into Terraform state

set -e

echo "================================================"
echo "Importing Existing K3S Cluster VMs into Terraform"
echo "================================================"
echo ""

# Check if we're in the right directory
if [ ! -f "main.tf" ]; then
    echo "ERROR: Must run from terraform/proxmox-prod/ directory"
    exit 1
fi

# Check if Terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "ERROR: Terraform not initialized. Run 'terraform init' first."
    exit 1
fi

echo "This will import 9 existing VMs into Terraform state:"
echo "  - 3 Control Plane nodes (k3s-01, k3s-02, k3s-03)"
echo "  - 3 Worker nodes (k3s-04, k3s-05, k3s-06)"
echo "  - 3 Longhorn storage nodes (lh-01, lh-02, lh-03)"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted."
    exit 0
fi

echo ""
echo "Importing Control Plane Nodes..."
echo "--------------------------------"

echo "Importing k3s-01 (um773a, vmid 201)..."
terraform import 'module.control["k3s-01"]' um773a/qemu/201

echo "Importing k3s-02 (um773b, vmid 202)..."
terraform import 'module.control["k3s-02"]' um773b/qemu/202

echo "Importing k3s-03 (um773c, vmid 203)..."
terraform import 'module.control["k3s-03"]' um773c/qemu/203

echo ""
echo "Importing Worker Nodes..."
echo "-------------------------"

echo "Importing k3s-04 (um773b, vmid 204)..."
terraform import 'module.workers["k3s-04"]' um773b/qemu/204

echo "Importing k3s-05 (um773c, vmid 205)..."
terraform import 'module.workers["k3s-05"]' um773c/qemu/205

echo "Importing k3s-06 (um773a, vmid 206)..."
terraform import 'module.workers["k3s-06"]' um773a/qemu/206

echo ""
echo "Importing Longhorn Storage Nodes..."
echo "------------------------------------"

echo "Importing lh-01 (um773a, vmid 250)..."
terraform import 'module.longhorn["lh-01"]' um773a/qemu/250

echo "Importing lh-02 (um773b, vmid 251)..."
terraform import 'module.longhorn["lh-02"]' um773b/qemu/251

echo "Importing lh-03 (um773c, vmid 252)..."
terraform import 'module.longhorn["lh-03"]' um773c/qemu/252

echo ""
echo "================================================"
echo "✅ Import Complete!"
echo "================================================"
echo ""
echo "Next steps:"
echo "  1. Run 'terraform plan' to verify no drift"
echo "  2. Review any differences between actual VMs and terraform.tfvars"
echo "  3. Update terraform.tfvars if needed to match reality"
echo "  4. Run 'terraform plan' again to ensure clean state"
echo ""
