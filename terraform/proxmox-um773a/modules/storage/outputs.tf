output "pool_name" {
  description = "Storage pool name"
  value       = proxmox_storage_pool.pool.name
}

output "pool_type" {
  description = "Storage pool type"
  value       = proxmox_storage_pool.pool.type
}
