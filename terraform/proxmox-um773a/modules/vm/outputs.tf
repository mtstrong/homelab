output "vm_id" {
  description = "VM ID"
  value       = proxmox_vm_qemu.vm.vmid
}

output "vm_name" {
  description = "VM name"
  value       = proxmox_vm_qemu.vm.name
}

output "vm_status" {
  description = "VM status"
  value       = proxmox_vm_qemu.vm.status
}

output "vm_default_ipv4_address" {
  description = "VM default IPv4 address"
  value       = try(proxmox_vm_qemu.vm.default_ipv4_address, null)
}
