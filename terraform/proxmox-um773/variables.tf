variable "vm_name" {
  description = "The name of the Ubuntu virtual machine"
  type        = string
  default     = "ubuntu-vm"
}

variable "vmid" {
  description = "The unique ID for the virtual machine"
  type        = number
  default     = 100
}

variable "cores" {
  description = "Number of CPU cores for the virtual machine"
  type        = number
  default     = 2
}

variable "memory" {
  description = "Memory size in MB for the virtual machine"
  type        = number
  default     = 2048
}

variable "sockets" {
  description = "Number of CPU sockets for the virtual machine"
  type        = number
  default     = 1
}

variable "disk_size" {
  description = "Size of the virtual machine disk"
  type        = string
  default     = "20G"
}

variable "storage" {
  description = "Storage location for the virtual machine"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Network bridge for the virtual machine"
  type        = string
  default     = "vmbr0"
}

variable "iso_image" {
  description = "ISO image for the virtual machine installation"
  type        = string
  default     = "local:iso/ubuntu-22.04-live-server-amd64.iso"
}

variable "ciuser" {
  description = "Cloud-init user for the virtual machine"
  type        = string
  default     = "ubuntu"
}

variable "cipassword" {
  description = "Cloud-init password for the virtual machine"
  type        = string
  default     = "ubuntu_password"
}

variable "sshkeys" {
  description = "SSH public keys for the virtual machine"
  type        = string
  default     = file("~/.ssh/id_rsa.pub")
}