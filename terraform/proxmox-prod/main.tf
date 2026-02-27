terraform {
  required_version = ">= 1.0"
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

provider "proxmox" {
  pm_api_url          = var.proxmox_api_url
  pm_api_token_id     = var.proxmox_token_id
  pm_api_token_secret = var.proxmox_token_secret
  pm_tls_insecure     = var.proxmox_tls_insecure
}

# Reference modules from the module registry (parent directory)
module "control" {
  source = "../proxmox-modules/modules/control_vm"

  for_each = var.control_vms

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

module "workers" {
  source = "../proxmox-modules/modules/worker_vm"

  for_each = var.worker_vms

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

module "longhorn" {
  source = "../proxmox-modules/modules/longhorn_vm"

  for_each = var.longhorn_vms

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
