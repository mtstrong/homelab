variable "resource_group_name" {
  description = "Name of the resource group for state storage"
  type        = string
  default     = "rg-tofu-state"
}

variable "location" {
  description = "Azure region for state storage resources"
  type        = string
  default     = "eastus"
}

variable "storage_account_name" {
  description = "Name of the storage account for state (must be globally unique, 3-24 lowercase alphanumeric)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 lowercase alphanumeric characters."
  }
}

variable "container_name" {
  description = "Name of the blob container for state files"
  type        = string
  default     = "tfstate"
}
