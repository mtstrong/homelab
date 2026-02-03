variable "resource_group_name" {
  description = "Name of the Azure resource group"
  type        = string
  default     = "rg-uptimekuma-monitoring"
}

variable "location" {
  description = "Azure region for resources (eastus is typically cheapest)"
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Name of the storage account (must be globally unique, 3-24 lowercase alphanumeric)"
  type        = string
  default     = "stuptkma" # Change this to something unique
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "container_name" {
  description = "Name of the container group"
  type        = string
  default     = "uptimekuma"
}

variable "dns_name_label" {
  description = "DNS name label for the container (must be globally unique)"
  type        = string
  default     = "uptimekuma-monitor" # Change this to something unique
}

variable "cpu_cores" {
  description = "Number of CPU cores for the container"
  type        = string
  default     = "0.5"
}

variable "memory_in_gb" {
  description = "Memory in GB for the container"
  type        = string
  default     = "1.0"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Production"
    Project     = "Homelab-Monitoring"
    ManagedBy   = "OpenTofu"
  }
}

variable "dockerhub_username" {
  description = "Docker Hub username (optional, helps avoid rate limiting)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "dockerhub_password" {
  description = "Docker Hub password or access token (optional)"
  type        = string
  default     = ""
  sensitive   = true
}
