#!/usr/bin/env python3
"""
Manually create Terraform state for existing Proxmox VMs
This is a workaround for the proxmox-api-go provider bug
"""

import json
import sys

# Define VMs to import
vms = {
    "control_vms": {
        "k3s-01": {"vmid": 201, "node": "um773a"},
        "k3s-02": {"vmid": 202, "node": "um773b"},
        "k3s-03": {"vmid": 203, "node": "um773c"},
    },
    "worker_vms": {
        "k3s-04": {"vmid": 204, "node": "um773b"},
        "k3s-05": {"vmid": 205, "node": "um773c"},
        "k3s-06": {"vmid": 206, "node": "um773a"},
    },
    "longhorn_vms": {
        "lh-01": {"vmid": 250, "node": "um773a"},
        "lh-02": {"vmid": 251, "node": "um773b"},
        "lh-03": {"vmid": 252, "node": "um773c"},
    },
}

# Terraform state structure
state = {
    "version": 4,
    "terraform_version": "1.6.0",
    "serial": 1,
    "lineage": "proxmox-existing-cluster",
    "outputs": {},
    "resources": []
}

# Build resources for each VM type
module_types = [
    ("control_vms", "control", "control_vm"),
    ("worker_vms", "workers", "worker_vm"),
    ("longhorn_vms", "longhorn", "longhorn_vm"),
]

for vm_type_key, module_name, resource_name in module_types:
    instances = []
    for vm_key, vm_data in vms[vm_type_key].items():
        vm_id = f"{vm_data['node']}/qemu/{vm_data['vmid']}"
        instances.append({
            "index_key": vm_key,
            "attributes": {
                "id": vm_id,
                "vmid": str(vm_data["vmid"]),
                "name": vm_key,
                "target_node": vm_data["node"],
            },
            "sensitive_attributes": [],
            "private": "bnVsbA=="
        })
    
    resource = {
        "module": f"module.{module_name}",
        "mode": "managed",
        "type": "proxmox_vm_qemu",
        "name": resource_name,
        "instances": instances
    }
    state["resources"].append(resource)

# Write state file
try:
    with open("terraform.tfstate", "w") as f:
        json.dump(state, f, indent=2)
    print("✅ Created terraform.tfstate with", sum(len(vms[k]) for k in vms), "VMs")
    sys.exit(0)
except Exception as e:
    print(f"❌ Error creating state file: {e}")
    sys.exit(1)
