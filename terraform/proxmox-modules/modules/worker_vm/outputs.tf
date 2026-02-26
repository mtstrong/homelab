output "vm_id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.worker_vm.vmid
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.worker_vm.name
}

output "default_ipv4_address" {
  description = "Default IPv4 address"
  value       = try(proxmox_vm_qemu.worker_vm.default_ipv4_address, null)
}
