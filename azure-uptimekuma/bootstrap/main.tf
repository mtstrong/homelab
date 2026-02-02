terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
  
  # Bootstrap uses local state
  # This creates the storage account that will store state for other projects
}

provider "azurerm" {
  features {}
}

# Resource Group for OpenTofu state storage
resource "azurerm_resource_group" "state" {
  name     = var.resource_group_name
  location = var.location
  
  tags = {
    Purpose   = "OpenTofu State Storage"
    ManagedBy = "OpenTofu"
  }
}

# Storage Account for state files
resource "azurerm_storage_account" "state" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.state.name
  location                 = azurerm_resource_group.state.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  # Security settings
  min_tls_version                = "TLS1_2"
  enable_https_traffic_only      = true
  allow_nested_items_to_be_public = false
  
  tags = {
    Purpose   = "OpenTofu State Storage"
    ManagedBy = "OpenTofu"
  }
}

# Blob Container for state files
resource "azurerm_storage_container" "state" {
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.state.name
  container_access_type = "private"
}

# Generate backend configuration file
resource "local_file" "backend_config" {
  filename = "${path.module}/../backend-config.tfvars"
  content  = <<-EOF
    resource_group_name  = "${azurerm_resource_group.state.name}"
    storage_account_name = "${azurerm_storage_account.state.name}"
    container_name       = "${azurerm_storage_container.state.name}"
    key                  = "uptimekuma.tfstate"
  EOF
  
  file_permission = "0644"
}

# Generate backend.tf file
resource "local_file" "backend_tf" {
  filename = "${path.module}/../backend.tf"
  content  = <<-EOF
    terraform {
      backend "azurerm" {
        # Configuration is loaded from backend-config.tfvars
        # Run: tofu init -backend-config=backend-config.tfvars
      }
    }
  EOF
  
  file_permission = "0644"
}
