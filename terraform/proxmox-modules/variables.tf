## Proxmox Provider Configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
  default     = "https://192.168.1.100:8006/api2/json"
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
  default     = "ubuntu-22.04-cloud"
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
  default     = "ubuntu"
}

variable "cloud_init_password" {
  description = "Cloud-init password"
  type        = string
  sensitive   = true
}

## Network Configuration
variable "bridge_vlan0" {
  description = "Bridge interface for VLAN0"
  type        = string
  default     = "vmbr0"
}

## K3S Web Node Configuration
variable "create_web_vms" {
  description = "Create K3S web/control plane nodes"
  type        = bool
  default     = false
}

variable "web_vm_id" {
  description = "VM ID for web node"
  type        = number
  default     = 200
}

variable "web_cores" {
  description = "Web node CPU cores"
  type        = number
  default     = 4
}

variable "web_memory" {
  description = "Web node memory in MB"
  type        = number
  default     = 4096
}

variable "web_disk_size" {
  description = "Web node disk size"
  type        = string
  default     = "50G"
}

variable "web_ipconfig" {
  description = "Web node IP configuration"
  type        = string
  default     = "ip=dhcp"
}

## K3S Worker Nodes Configuration
variable "create_worker_vms" {
  description = "Create K3S worker nodes"
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
