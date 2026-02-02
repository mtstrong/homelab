output "uptimekuma_url" {
  description = "URL to access Uptime Kuma"
  value       = "http://${azurerm_container_group.uptimekuma.fqdn}:3001"
}

output "uptimekuma_fqdn" {
  description = "Fully qualified domain name of the container"
  value       = azurerm_container_group.uptimekuma.fqdn
}

output "uptimekuma_ip" {
  description = "Public IP address of the container"
  value       = azurerm_container_group.uptimekuma.ip_address
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.uptimekuma.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.uptimekuma.name
}
