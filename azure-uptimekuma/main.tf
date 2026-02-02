terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "uptimekuma" {
  name     = var.resource_group_name
  location = var.location
  
  tags = var.tags
}

# Storage Account for persistent data
resource "azurerm_storage_account" "uptimekuma" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.uptimekuma.name
  location                 = azurerm_resource_group.uptimekuma.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  
  tags = var.tags
}

# File Share for Uptime Kuma data persistence
resource "azurerm_storage_share" "uptimekuma" {
  name                 = "uptimekuma-data"
  storage_account_name = azurerm_storage_account.uptimekuma.name
  quota                = 1 # 1GB minimum
}

# Container Instance
resource "azurerm_container_group" "uptimekuma" {
  name                = var.container_name
  location            = azurerm_resource_group.uptimekuma.location
  resource_group_name = azurerm_resource_group.uptimekuma.name
  ip_address_type     = "Public"
  dns_name_label      = var.dns_name_label
  os_type             = "Linux"
  
  container {
    name   = "uptimekuma"
    image  = "louislam/uptime-kuma:1"
    cpu    = var.cpu_cores
    memory = var.memory_in_gb
    
    ports {
      port     = 3001
      protocol = "TCP"
    }
    
    volume {
      name                 = "uptimekuma-data"
      mount_path           = "/app/data"
      storage_account_name = azurerm_storage_account.uptimekuma.name
      storage_account_key  = azurerm_storage_account.uptimekuma.primary_access_key
      share_name           = azurerm_storage_share.uptimekuma.name
    }
  }
  
  tags = var.tags
}
