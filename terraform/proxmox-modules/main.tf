terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure = var.proxmox_tls_insecure
}

# Control/Master Node
module "control" {
  source = "./modules/control_vm"
  
  count = var.create_control_vm ? 1 : 0

  vm_name             = var.control_vm_name
  target_node         = var.target_node
  vmid                = var.control_vmid
  clone_template      = var.clone_template
  cores               = var.control_cores
  memory              = var.control_memory
  disk_size           = var.control_disk_size
  bridge              = var.bridge_name
  vlan_tag            = var.vlan_tag
  cloud_init_user     = var.cloud_init_user
  cloud_init_password = var.cloud_init_password
  ipconfig            = var.control_ipconfig
}

# Worker Nodes
module "workers" {
  source = "./modules/worker_vm"
  
  for_each = var.create_worker_vms ? var.worker_vms : {}

  vm_name             = each.value.name
  target_node         = each.value.target_node
  vmid                = each.value.vmid
  clone_template      = var.clone_template
  cores               = each.value.cores
  memory              = each.value.memory
  disk_size           = each.value.disk_size
  bridge              = var.bridge_name
  vlan_tag            = var.vlan_tag
  cloud_init_user     = var.cloud_init_user
  cloud_init_password = var.cloud_init_password
  ipconfig            = each.value.ipconfig
}

# Longhorn Storage Nodes
module "longhorn_nodes" {
  source = "./modules/longhorn_vm"
  
  for_each = var.create_longhorn_vms ? var.longhorn_vms : {}

  vm_name             = each.value.name
  target_node         = each.value.target_node
  vmid                = each.value.vmid
  clone_template      = var.clone_template
  cores               = each.value.cores
  memory              = each.value.memory
  disk_size           = each.value.disk_size
  bridge              = var.bridge_name
  vlan_tag            = var.vlan_tag
  cloud_init_user     = var.cloud_init_user
  cloud_init_password = var.cloud_init_password
  ipconfig            = each.value.ipconfig
}
