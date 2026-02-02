output "resource_group_name" {
  description = "Name of the resource group containing state storage"
  value       = azurerm_resource_group.state.name
}

output "storage_account_name" {
  description = "Name of the storage account for state"
  value       = azurerm_storage_account.state.name
}

output "container_name" {
  description = "Name of the blob container for state files"
  value       = azurerm_storage_container.state.name
}

output "backend_config_file" {
  description = "Location of generated backend config file"
  value       = abspath(local_file.backend_config.filename)
}

output "next_steps" {
  description = "Instructions for using the backend"
  value       = <<-EOF
    
    Backend storage created successfully!
    
    Next steps:
    1. Change to the parent directory:
       cd ..
    
    2. Initialize with the backend:
       tofu init -backend-config=backend-config.tfvars
    
    3. Deploy your infrastructure:
       tofu plan
       tofu apply
    
  EOF
}
