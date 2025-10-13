terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = ">= 2.9.0"
    }
  }
}

provider "proxmox" {
  pm_api_url      = var.proxmox_url
  pm_user         = var.proxmox_user
  pm_password     = var.proxmox_password
  pm_tls_insecure = var.proxmox_tls_insecure
}

resource "proxmox_vm_qemu" "ubuntu_vm" {
  name        = var.vm_name
  target_node = var.node
  vmid        = var.vm_id

  cores   = var.cores
  sockets = 1
  memory  = var.memory
  # Clone from a template (assumes template exists).
  clone = var.template

  network {
    model  = "virtio"
    bridge = "vmbr0"
  }

  disk {
    size         = "${var.disk_size_gb}G"
    type         = "scsi"
    storage      = var.storage_pool
    cache        = "writeback"
    discard      = "on"
  }

  # Boot firmware and SCSI controller
  scsihw = "virtio-scsi-pci"
  boot   = "order=scsi0"

  # Cloud-init settings (require a cloud-init enabled template)
  ciuser  = "ubuntu"
  sshkeys = var.ssh_authorized_key

  # Enable QEMU Guest Agent (recommended)
  agent = 1
}
