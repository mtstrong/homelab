variable "proxmox_url" {
  description = "Proxmox PVE URL (e.g. https://um773a.tehmatt.com:8006)"
  type        = string
}

variable "proxmox_user" {
  description = "Proxmox user (e.g. root@pam)"
  type        = string
  default     = "root@pam"
}

variable "proxmox_password" {
  description = "Proxmox password (use with caution)"
  type        = string
  sensitive   = true
  default     = ""
}

variable "proxmox_tls_insecure" {
  description = "Whether to skip TLS verification for Proxmox (not recommended in prod)"
  type        = bool
  default     = true
}

variable "node" {
  description = "Proxmox node name where VM will be created"
  type        = string
  default     = "um773a"
}

variable "vm_name" {
  description = "Name of the VM"
  type        = string
  default     = "ubuntu-8c-8g-64g"
}

variable "vm_id" {
  description = "Numeric VM id (choose free ID on your cluster)"
  type        = number
  default     = 200
}

variable "cores" {
  description = "Number of CPU cores for the VM"
  type        = number
  default     = 8
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 8192
}

variable "disk_size_gb" {
  description = "Disk size in GB"
  type        = number
  default     = 64
}

variable "storage_pool" {
  description = "Proxmox storage pool to put VM disk (e.g. local-lvm)"
  type        = string
  default     = "local-lvm"
}

variable "template" {
  description = "Proxmox VM template or cloud-init image to clone from (vmid or template name)"
  type        = string
  default     = "ubuntu-22-template"
}

variable "ssh_authorized_key" {
  description = "SSH public key to add to the VM via cloud-init"
  type        = string
  default     = ""
}

variable "iso_image" {
  description = "Proxmox ISO image to attach for installation. Format: '<storage>:iso/filename.iso' (e.g. 'local:iso/ubuntu-22.04-live-server-amd64.iso'). Leave empty to skip attaching an ISO."
  type        = string
  default     = ""
}
