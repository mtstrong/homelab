## Proxmox Provider Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://bd790i.local:8006/api2/json"
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID (format: user@realm!tokenname)"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "Disable SSL verification for Proxmox API"
  type        = bool
  default     = true
}

## Template Configuration
variable "clone_template" {
  description = "Template VM name to clone from"
  type        = string
  default     = "ubuntu-cloud"
}

variable "target_node" {
  description = "Default Proxmox node to deploy to"
  type        = string
  default     = "um773a"
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
  description = "Network bridge name"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag for k3s network"
  type        = number
  default     = 2
}

## Control VM Configuration
variable "create_control_vm" {
  description = "Create control/master node"
  type        = bool
  default     = false
}

variable "control_vm_name" {
  description = "Control VM name"
  type        = string
  default     = "k3s-control"
}

variable "control_vmid" {
  description = "Control VM ID (100-199 range)"
  type        = number
  default     = 100
}

variable "control_cores" {
  description = "Control node CPU cores"
  type        = number
  default     = 8
}

variable "control_memory" {
  description = "Control node memory in MB"
  type        = number
  default     = 8192
}

variable "control_disk_size" {
  description = "Control node disk size"
  type        = string
  default     = "40G"
}

variable "control_ipconfig" {
  description = "Control node IP configuration"
  type        = string
  default     = "ip=dhcp"
}

## Worker VM Configuration
variable "create_worker_vms" {
  description = "Create worker nodes"
  type        = bool
  default     = false
}

variable "worker_vms" {
  description = "Worker VM configurations"
  type = map(object({
    name        = string
    target_node = string
    vmid        = number
    cores       = number
    memory      = number
    disk_size   = string
    ipconfig    = string
  }))
  default = {}
}

## Longhorn VM Configuration
variable "create_longhorn_vms" {
  description = "Create Longhorn storage nodes"
  type        = bool
  default     = false
}

variable "longhorn_vms" {
  description = "Longhorn storage VM configurations"
  type = map(object({
    name        = string
    target_node = string
    vmid        = number
    cores       = number
    memory      = number
    disk_size   = string
    ipconfig    = string
  }))
  default = {}
}
