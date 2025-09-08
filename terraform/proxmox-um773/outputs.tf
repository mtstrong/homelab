output "ubuntu_vm_ips" {
  value = [
    proxmox_vm_qemu.ubuntu_vm_node1.ipv4,
    proxmox_vm_qemu.ubuntu_vm_node2.ipv4,
    proxmox_vm_qemu.ubuntu_vm_node3.ipv4,
  ]
}

output "ubuntu_vm_ids" {
  value = [
    proxmox_vm_qemu.ubuntu_vm_node1.vmid,
    proxmox_vm_qemu.ubuntu_vm_node2.vmid,
    proxmox_vm_qemu.ubuntu_vm_node3.vmid,
  ]
}