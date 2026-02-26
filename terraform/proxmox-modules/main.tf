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

# Example usage - uncomment to create VMs
# module "vms_web" {
#   source = "./modules/vm"
#   
#   vm_name           = "k3s-web-node"
#   target_node       = var.target_node
#   vmid              = var.web_vm_id
#   clone_template    = var.clone_template
#   cores             = var.web_cores
#   memory            = var.web_memory
#   disk_size         = var.web_disk_size
#   bridge            = var.bridge_vlan0
#   cloud_init_user   = var.cloud_init_user
#   cloud_init_password = var.cloud_init_password
#   ipconfig          = var.web_ipconfig
# }
# 
# module "vms_worker" {
#   source = "./modules/vm"
#   
#   for_each = var.worker_vms
# 
#   vm_name           = each.value.name
#   target_node       = each.value.target_node
#   vmid              = each.value.vmid
#   clone_template    = var.clone_template
#   cores             = each.value.cores
#   memory            = each.value.memory
#   disk_size         = each.value.disk_size
#   bridge            = var.bridge_vlan0
#   cloud_init_user   = var.cloud_init_user
#   cloud_init_password = var.cloud_init_password
#   ipconfig          = each.value.ipconfig
# }
