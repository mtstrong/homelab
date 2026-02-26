## Proxmox Provider Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Disable SSL verification"
  type        = bool
  default     = true
}

## Template Configuration
variable "clone_template" {
  description = "Template VM name"
  type        = string
  default     = "ubuntu-cloud"
}

## Cloud-init Configuration
variable "cloud_init_user" {
  description = "Cloud-init user"
  type        = string
  default     = "homelab"
}

variable "cloud_init_password" {
  description = "Cloud-init password"
  type        = string
  sensitive   = true
}

## Network Configuration
variable "bridge_name" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag"
  type        = number
  default     = 2
}

## Control VMs
variable "control_vms" {
  description = "Control plane VMs"
  type = map(object({
    name        = string
    target_node = string
    vmid        = number
    cores       = number
    memory      = number
    disk_size   = string
    ipconfig    = string
  }))
}

## Worker VMs
variable "worker_vms" {
  description = "Worker VMs"
  type = map(object({
    name        = string
    target_node = string
    vmid        = number
    cores       = number
    memory      = number
    disk_size   = string
    ipconfig    = string
  }))
}

## Longhorn Storage VMs
variable "longhorn_vms" {
  description = "Longhorn storage VMs"
  type = map(object({
    name        = string
    target_node = string
    vmid        = number
    cores       = number
    memory      = number
    disk_size   = string
    ipconfig    = string
  }))
}
