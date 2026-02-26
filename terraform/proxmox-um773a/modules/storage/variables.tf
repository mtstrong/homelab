variable "pool_name" {
  description = "Storage pool name"
  type        = string
}

variable "storage_type" {
  description = "Storage type (lvmthin, dir, etc.)"
  type        = string
  validation {
    condition     = contains(["lvmthin", "dir", "zfspool"], var.storage_type)
    error_message = "Storage type must be lvmthin, dir, or zfspool."
  }
}

variable "nodes" {
  description = "List of nodes this storage is available on"
  type        = list(string)
}

variable "content_types" {
  description = "Content types for storage (e.g., images, rootdir, backup)"
  type        = list(string)
}

variable "disabled" {
  description = "Disable the storage"
  type        = bool
  default     = false
}

variable "volume_group" {
  description = "LVM volume group name (for lvmthin)"
  type        = string
  default     = ""
}

variable "thinpool" {
  description = "LVM thin pool name (for lvmthin)"
  type        = string
  default     = ""
}

variable "path" {
  description = "Directory path (for dir storage)"
  type        = string
  default     = ""
}

variable "maxfiles" {
  description = "Maximum files (for dir storage)"
  type        = number
  default     = 0
}
