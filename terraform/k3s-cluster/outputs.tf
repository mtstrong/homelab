# ========================================
# MASTER NODE OUTPUTS
# ========================================

output "master_nodes" {
  description = "Information about all master nodes"
  value = {
    master1 = {
      name       = proxmox_vm_qemu.k3s_master1.name
      vmid       = proxmox_vm_qemu.k3s_master1.vmid
      ip_address = var.master_nodes["master1"].ip_address
      host       = var.master_nodes["master1"].target_node
      ssh        = "ssh ${var.ciuser}@${var.master_nodes["master1"].ip_address}"
    }
    master2 = {
      name       = proxmox_vm_qemu.k3s_master2.name
      vmid       = proxmox_vm_qemu.k3s_master2.vmid
      ip_address = var.master_nodes["master2"].ip_address
      host       = var.master_nodes["master2"].target_node
      ssh        = "ssh ${var.ciuser}@${var.master_nodes["master2"].ip_address}"
    }
    master3 = {
      name       = proxmox_vm_qemu.k3s_master3.name
      vmid       = proxmox_vm_qemu.k3s_master3.vmid
      ip_address = var.master_nodes["master3"].ip_address
      host       = var.master_nodes["master3"].target_node
      ssh        = "ssh ${var.ciuser}@${var.master_nodes["master3"].ip_address}"
    }
  }
}

# ========================================
# WORKER NODE OUTPUTS
# ========================================

output "worker_nodes" {
  description = "Information about all worker nodes"
  value = {
    worker1 = {
      name       = proxmox_vm_qemu.k3s_worker1.name
      vmid       = proxmox_vm_qemu.k3s_worker1.vmid
      ip_address = var.worker_nodes["worker1"].ip_address
      host       = var.worker_nodes["worker1"].target_node
      ssh        = "ssh ${var.ciuser}@${var.worker_nodes["worker1"].ip_address}"
    }
    worker2 = {
      name       = proxmox_vm_qemu.k3s_worker2.name
      vmid       = proxmox_vm_qemu.k3s_worker2.vmid
      ip_address = var.worker_nodes["worker2"].ip_address
      host       = var.worker_nodes["worker2"].target_node
      ssh        = "ssh ${var.ciuser}@${var.worker_nodes["worker2"].ip_address}"
    }
  }
}

# ========================================
# LONGHORN NODE OUTPUTS
# ========================================

output "longhorn_nodes" {
  description = "Information about all Longhorn nodes"
  value = {
    longhorn1 = {
      name       = proxmox_vm_qemu.lh_node1.name
      vmid       = proxmox_vm_qemu.lh_node1.vmid
      ip_address = var.longhorn_nodes["longhorn1"].ip_address
      host       = var.longhorn_nodes["longhorn1"].target_node
      ssh        = "ssh ${var.ciuser}@${var.longhorn_nodes["longhorn1"].ip_address}"
    }
    longhorn2 = {
      name       = proxmox_vm_qemu.lh_node2.name
      vmid       = proxmox_vm_qemu.lh_node2.vmid
      ip_address = var.longhorn_nodes["longhorn2"].ip_address
      host       = var.longhorn_nodes["longhorn2"].target_node
      ssh        = "ssh ${var.ciuser}@${var.longhorn_nodes["longhorn2"].ip_address}"
    }
    longhorn3 = {
      name       = proxmox_vm_qemu.lh_node3.name
      vmid       = proxmox_vm_qemu.lh_node3.vmid
      ip_address = var.longhorn_nodes["longhorn3"].ip_address
      host       = var.longhorn_nodes["longhorn3"].target_node
      ssh        = "ssh ${var.ciuser}@${var.longhorn_nodes["longhorn3"].ip_address}"
    }
  }
}

# ========================================
# CLUSTER SUMMARY
# ========================================

output "cluster_summary" {
  description = "Summary of the K3s cluster"
  value = {
    total_masters = 3
    total_workers = 2
    total_longhorn = 3
    master_ips = [
      var.master_nodes["master1"].ip_address,
      var.master_nodes["master2"].ip_address,
      var.master_nodes["master3"].ip_address,
    ]
    worker_ips = [
      var.worker_nodes["worker1"].ip_address,
      var.worker_nodes["worker2"].ip_address,
    ]
    longhorn_ips = [
      var.longhorn_nodes["longhorn1"].ip_address,
      var.longhorn_nodes["longhorn2"].ip_address,
      var.longhorn_nodes["longhorn3"].ip_address,
    ]
  }
}

# ========================================
# ANSIBLE INVENTORY FORMAT
# ========================================

output "ansible_inventory" {
  description = "Ansible inventory format for the cluster"
  value = <<-EOT
    [k3s_masters]
    ${var.master_nodes["master1"].hostname} ansible_host=${var.master_nodes["master1"].ip_address}
    ${var.master_nodes["master2"].hostname} ansible_host=${var.master_nodes["master2"].ip_address}
    ${var.master_nodes["master3"].hostname} ansible_host=${var.master_nodes["master3"].ip_address}

    [k3s_workers]
    ${var.worker_nodes["worker1"].hostname} ansible_host=${var.worker_nodes["worker1"].ip_address}
    ${var.worker_nodes["worker2"].hostname} ansible_host=${var.worker_nodes["worker2"].ip_address}

    [longhorn_nodes]
    ${var.longhorn_nodes["longhorn1"].hostname} ansible_host=${var.longhorn_nodes["longhorn1"].ip_address}
    ${var.longhorn_nodes["longhorn2"].hostname} ansible_host=${var.longhorn_nodes["longhorn2"].ip_address}
    ${var.longhorn_nodes["longhorn3"].hostname} ansible_host=${var.longhorn_nodes["longhorn3"].ip_address}

    [k3s_cluster:children]
    k3s_masters
    k3s_workers
    longhorn_nodes

    [k3s_cluster:vars]
    ansible_user=${var.ciuser}
    ansible_ssh_private_key_file=~/.ssh/id_ed25519
  EOT
}
