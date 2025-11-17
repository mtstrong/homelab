# ========================================
# K3S MASTER NODES
# ========================================

# Master Node 1 (on UM773A)
resource "proxmox_vm_qemu" "k3s_master1" {
  provider    = proxmox.um773a
  
  name        = var.master_nodes["master1"].hostname
  target_node = var.master_nodes["master1"].target_node
  vmid        = var.master_nodes["master1"].vmid
  
  # Clone from template
  clone       = var.template_name
  full_clone  = true
  
  # VM Resources
  cores       = var.master_cores
  sockets     = var.master_sockets
  memory      = var.master_memory
  agent       = 1
  
  # Boot settings
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  # Disk configuration
  disk {
    size    = var.master_disk_size
    type    = "scsi"
    storage = var.master_storage
    cache   = "writeback"
    discard = "on"
  }
  
  # Network configuration
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  # Cloud-init configuration
  ipconfig0 = "ip=${var.master_nodes["master1"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  # Lifecycle
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Master Node 2 (on UM773B)
resource "proxmox_vm_qemu" "k3s_master2" {
  provider    = proxmox.um773b
  
  name        = var.master_nodes["master2"].hostname
  target_node = var.master_nodes["master2"].target_node
  vmid        = var.master_nodes["master2"].vmid
  
  clone       = var.template_name
  full_clone  = true
  
  cores       = var.master_cores
  sockets     = var.master_sockets
  memory      = var.master_memory
  agent       = 1
  
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  disk {
    size    = var.master_disk_size
    type    = "scsi"
    storage = var.master_storage
    cache   = "writeback"
    discard = "on"
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  ipconfig0 = "ip=${var.master_nodes["master2"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Master Node 3 (on UM773C)
resource "proxmox_vm_qemu" "k3s_master3" {
  provider    = proxmox.um773c
  
  name        = var.master_nodes["master3"].hostname
  target_node = var.master_nodes["master3"].target_node
  vmid        = var.master_nodes["master3"].vmid
  
  clone       = var.template_name
  full_clone  = true
  
  cores       = var.master_cores
  sockets     = var.master_sockets
  memory      = var.master_memory
  agent       = 1
  
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  disk {
    size    = var.master_disk_size
    type    = "scsi"
    storage = var.master_storage
    cache   = "writeback"
    discard = "on"
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  ipconfig0 = "ip=${var.master_nodes["master3"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# ========================================
# K3S WORKER NODES
# ========================================

# Worker Node 1 (on UM773C)
resource "proxmox_vm_qemu" "k3s_worker1" {
  provider    = proxmox.um773c
  
  name        = var.worker_nodes["worker1"].hostname
  target_node = var.worker_nodes["worker1"].target_node
  vmid        = var.worker_nodes["worker1"].vmid
  
  clone       = var.template_name
  full_clone  = true
  
  cores       = var.worker_cores
  sockets     = var.worker_sockets
  memory      = var.worker_memory
  agent       = 1
  
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  disk {
    size    = var.worker_disk_size
    type    = "scsi"
    storage = var.worker_storage
    cache   = "writeback"
    discard = "on"
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  ipconfig0 = "ip=${var.worker_nodes["worker1"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Worker Node 2 (on UM773C)
resource "proxmox_vm_qemu" "k3s_worker2" {
  provider    = proxmox.um773c
  
  name        = var.worker_nodes["worker2"].hostname
  target_node = var.worker_nodes["worker2"].target_node
  vmid        = var.worker_nodes["worker2"].vmid
  
  clone       = var.template_name
  full_clone  = true
  
  cores       = var.worker_cores
  sockets     = var.worker_sockets
  memory      = var.worker_memory
  agent       = 1
  
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  disk {
    size    = var.worker_disk_size
    type    = "scsi"
    storage = var.worker_storage
    cache   = "writeback"
    discard = "on"
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  ipconfig0 = "ip=${var.worker_nodes["worker2"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# ========================================
# LONGHORN WORKER NODES
# ========================================

# Longhorn Node 1 (on UM773A)
resource "proxmox_vm_qemu" "lh_node1" {
  provider    = proxmox.um773a
  
  name        = var.longhorn_nodes["longhorn1"].hostname
  target_node = var.longhorn_nodes["longhorn1"].target_node
  vmid        = var.longhorn_nodes["longhorn1"].vmid
  
  clone       = var.template_name
  full_clone  = true
  
  cores       = var.longhorn_cores
  sockets     = var.longhorn_sockets
  memory      = var.longhorn_memory
  agent       = 1
  
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  disk {
    size    = var.longhorn_disk_size
    type    = "scsi"
    storage = var.longhorn_storage
    cache   = "writeback"
    discard = "on"
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  ipconfig0 = "ip=${var.longhorn_nodes["longhorn1"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Longhorn Node 2 (on UM773B)
resource "proxmox_vm_qemu" "lh_node2" {
  provider    = proxmox.um773b
  
  name        = var.longhorn_nodes["longhorn2"].hostname
  target_node = var.longhorn_nodes["longhorn2"].target_node
  vmid        = var.longhorn_nodes["longhorn2"].vmid
  
  clone       = var.template_name
  full_clone  = true
  
  cores       = var.longhorn_cores
  sockets     = var.longhorn_sockets
  memory      = var.longhorn_memory
  agent       = 1
  
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  disk {
    size    = var.longhorn_disk_size
    type    = "scsi"
    storage = var.longhorn_storage
    cache   = "writeback"
    discard = "on"
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  ipconfig0 = "ip=${var.longhorn_nodes["longhorn2"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}

# Longhorn Node 3 (on UM773C)
resource "proxmox_vm_qemu" "lh_node3" {
  provider    = proxmox.um773c
  
  name        = var.longhorn_nodes["longhorn3"].hostname
  target_node = var.longhorn_nodes["longhorn3"].target_node
  vmid        = var.longhorn_nodes["longhorn3"].vmid
  
  clone       = var.template_name
  full_clone  = true
  
  cores       = var.longhorn_cores
  sockets     = var.longhorn_sockets
  memory      = var.longhorn_memory
  agent       = 1
  
  boot        = "c"
  bootdisk    = "scsi0"
  scsihw      = "virtio-scsi-pci"
  
  disk {
    size    = var.longhorn_disk_size
    type    = "scsi"
    storage = var.longhorn_storage
    cache   = "writeback"
    discard = "on"
  }
  
  network {
    model  = var.network_model
    bridge = var.network_bridge
  }
  
  ipconfig0 = "ip=${var.longhorn_nodes["longhorn3"].ip_address}/24,gw=${var.gateway}"
  
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  ciuser       = var.ciuser
  sshkeys      = var.ssh_public_key
  
  lifecycle {
    ignore_changes = [
      network,
    ]
  }
}
