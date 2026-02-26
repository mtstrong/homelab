variable "vm_name" {
  description = "Longhorn VM name"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to deploy to"
  type        = string
}

variable "vmid" {
  description = "VM ID in Proxmox"
  type        = number
  validation {
    condition     = var.vmid >= 300 && var.vmid < 400
    error_message = "Longhorn VM IDs should be 300-399."
  }
}

variable "clone_template" {
  description = "Template VM to clone from"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 4
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "cpu_type" {
  description = "CPU type (host, kvm64, etc.)"
  type        = string
  default     = "host"
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 4096
}

variable "storage" {
  description = "Storage for disks"
  type        = string
  default     = "vms"
}

variable "disk_size" {
  description = "Root disk size (larger for Longhorn storage)"
  type        = string
  default     = "250G"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vlan_tag" {
  description = "VLAN tag for network interface"
  type        = number
  default     = 2
}

variable "cloud_init_user" {
  description = "Cloud-init username"
  type        = string
  default     = "homelab"
}

variable "cloud_init_password" {
  description = "Cloud-init password"
  type        = string
  sensitive   = true
}

variable "ssh_keys" {
  description = "SSH public keys to inject (URL encoded)"
  type        = string
  default     = ""
}

variable "ipconfig" {
  description = "IP configuration (dhcp or static IP)"
  type        = string
  default     = "ip=dhcp"
}
