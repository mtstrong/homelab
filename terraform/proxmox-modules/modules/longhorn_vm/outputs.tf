output "vm_id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.longhorn_vm.vmid
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.longhorn_vm.name
}

output "vm_status" {
  description = "VM status"
  value       = proxmox_vm_qemu.longhorn_vm.status
}

output "default_ipv4_address" {
  description = "Default IPv4 address"
  value       = try(proxmox_vm_qemu.longhorn_vm.default_ipv4_address, null)
}
