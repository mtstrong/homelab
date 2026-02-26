variable "vm_name" {
  description = "VM name"
  type        = string
}

variable "target_node" {
  description = "Proxmox node to deploy to"
  type        = string
}

variable "vmid" {
  description = "VM ID in Proxmox"
  type        = number
}

variable "clone_template" {
  description = "Template VM to clone from"
  type        = string
}

variable "cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "balloon" {
  description = "Enable memory ballooning"
  type        = number
  default     = 0
}

variable "storage" {
  description = "Storage location for disks"
  type        = string
  default     = "local-lvm"
}

variable "disk_size" {
  description = "Disk size in GB"
  type        = string
  default     = "20G"
}

variable "bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "cloud_init_user" {
  description = "Cloud-init user"
  type        = string
  default     = "ubuntu"
}

variable "cloud_init_password" {
  description = "Cloud-init password"
  type        = string
  sensitive   = true
  default     = ""
}

variable "ipconfig" {
  description = "IP configuration (e.g., 'ip=192.168.1.100/24,gw=192.168.1.1')"
  type        = string
  default     = "ip=dhcp"
}
