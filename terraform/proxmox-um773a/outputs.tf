output "vm_id" {
  description = "VM ID of the created machine"
  value       = proxmox_vm_qemu.ubuntu_vm.vmid
}

output "vm_name" {
  description = "Name of the created VM"
  value       = proxmox_vm_qemu.ubuntu_vm.name
}

output "node" {
  description = "Proxmox node where VM was created"
  value       = proxmox_vm_qemu.ubuntu_vm.target_node
}
