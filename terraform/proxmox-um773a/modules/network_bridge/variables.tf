variable "node_name" {
  description = "Proxmox node name"
  type        = string
}

variable "bridge_name" {
  description = "Bridge interface name (e.g., vmbr1)"
  type        = string
}

variable "comment" {
  description = "Bridge description"
  type        = string
  default     = ""
}

variable "disabled" {
  description = "Disable the bridge"
  type        = bool
  default     = false
}

variable "addresses" {
  description = "IP addresses for the bridge"
  type        = list(string)
  default     = []
}

variable "routes" {
  description = "Routes for the bridge"
  type = list(object({
    address = string
    gateway = string
  }))
  default = []
}
