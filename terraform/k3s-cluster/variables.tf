# Proxmox Connection Variables
variable "um773a_api_url" {
  description = "Proxmox API URL for UM773A host"
  type        = string
}

variable "um773b_api_url" {
  description = "Proxmox API URL for UM773B host"
  type        = string
}

variable "um773c_api_url" {
  description = "Proxmox API URL for UM773C host"
  type        = string
}

variable "pm_user" {
  description = "Proxmox user (e.g., root@pam)"
  type        = string
}

variable "pm_password" {
  description = "Proxmox password"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Skip TLS verification for Proxmox API"
  type        = bool
  default     = true
}

# VM Template Variables
variable "template_name" {
  description = "Name of the cloud-init enabled template to clone"
  type        = string
  default     = "ubuntu-22.04-cloud-init"
}

# Master Node Variables
variable "master_cores" {
  description = "Number of CPU cores for master nodes"
  type        = number
  default     = 4
}

variable "master_sockets" {
  description = "Number of CPU sockets for master nodes"
  type        = number
  default     = 1
}

variable "master_memory" {
  description = "Memory size in MB for master nodes"
  type        = number
  default     = 8192
}

variable "master_disk_size" {
  description = "Disk size for master nodes (e.g., 64G)"
  type        = string
  default     = "64G"
}

variable "master_storage" {
  description = "Storage location for master nodes"
  type        = string
  default     = "local-lvm"
}

# Worker Node Variables
variable "worker_cores" {
  description = "Number of CPU cores for worker nodes"
  type        = number
  default     = 8
}

variable "worker_sockets" {
  description = "Number of CPU sockets for worker nodes"
  type        = number
  default     = 1
}

variable "worker_memory" {
  description = "Memory size in MB for worker nodes"
  type        = number
  default     = 16384
}

variable "worker_disk_size" {
  description = "Disk size for worker nodes (e.g., 128G)"
  type        = string
  default     = "128G"
}

variable "worker_storage" {
  description = "Storage location for worker nodes"
  type        = string
  default     = "local-lvm"
}

# Network Variables
variable "network_bridge" {
  description = "Network bridge for VMs"
  type        = string
  default     = "vmbr0"
}

variable "network_model" {
  description = "Network model for VMs"
  type        = string
  default     = "virtio"
}

# Cloud-init Variables
variable "ciuser" {
  description = "Cloud-init default user"
  type        = string
  default     = "homelab"
}

variable "ssh_public_key" {
  description = "SSH public key for cloud-init"
  type        = string
}

# Master Node Configurations
variable "master_nodes" {
  description = "Master node configurations"
  type = map(object({
    vmid       = number
    hostname   = string
    ip_address = string
    target_node = string
  }))
  default = {
    master1 = {
      vmid        = 201
      hostname    = "k3s-01"
      ip_address  = "192.168.2.106"
      target_node = "um773a"
    }
    master2 = {
      vmid        = 202
      hostname    = "k3s-02"
      ip_address  = "192.168.2.102"
      target_node = "um773b"
    }
    master3 = {
      vmid        = 203
      hostname    = "k3s-03"
      ip_address  = "192.168.2.103"
      target_node = "um773c"
    }
  }
}

# Worker Node Configurations
variable "worker_nodes" {
  description = "Worker node configurations"
  type = map(object({
    vmid       = number
    hostname   = string
    ip_address = string
    target_node = string
  }))
  default = {
    worker1 = {
      vmid        = 204
      hostname    = "k3s-04"
      ip_address  = "192.168.2.104"
      target_node = "um773b"
    }
    worker2 = {
      vmid        = 205
      hostname    = "k3s-05"
      ip_address  = "192.168.2.105"
      target_node = "um773c"
    }
  }
}

# Longhorn Worker Node Configurations
variable "longhorn_nodes" {
  description = "Longhorn worker node configurations"
  type = map(object({
    vmid       = number
    hostname   = string
    ip_address = string
    target_node = string
  }))
  default = {
    longhorn1 = {
      vmid        = 250
      hostname    = "lh-01"
      ip_address  = "192.168.2.107"
      target_node = "um773a"
    }
    longhorn2 = {
      vmid        = 251
      hostname    = "lh-02"
      ip_address  = "192.168.2.108"
      target_node = "um773b"
    }
    longhorn3 = {
      vmid        = 252
      hostname    = "lh-03"
      ip_address  = "192.168.2.109"
      target_node = "um773c"
    }
  }
}

# Longhorn Node Variables
variable "longhorn_cores" {
  description = "Number of CPU cores for Longhorn nodes"
  type        = number
  default     = 4
}

variable "longhorn_sockets" {
  description = "Number of CPU sockets for Longhorn nodes"
  type        = number
  default     = 1
}

variable "longhorn_memory" {
  description = "Memory size in MB for Longhorn nodes"
  type        = number
  default     = 4096
}

variable "longhorn_disk_size" {
  description = "Disk size for Longhorn nodes (e.g., 250G)"
  type        = string
  default     = "250G"
}

variable "longhorn_storage" {
  description = "Storage location for Longhorn nodes"
  type        = string
  default     = "local-lvm"
}

# Network Configuration
variable "gateway" {
  description = "Default gateway for the VMs"
  type        = string
  default     = "192.168.2.1"
}

variable "nameserver" {
  description = "DNS nameserver for the VMs"
  type        = string
  default     = "192.168.2.1"
}

variable "searchdomain" {
  description = "DNS search domain"
  type        = string
  default     = "local"
}
