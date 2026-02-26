terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

resource "proxmox_vm_qemu" "vm" {
  name       = var.vm_name
  target_node = var.target_node
  vmid       = var.vmid
  clone      = var.clone_template

  cores      = var.cores
  sockets    = var.sockets
  memory     = var.memory
  balloon    = var.balloon

  disk {
    type    = "scsi"
    storage = var.storage
    size    = var.disk_size
  }

  network {
    model  = "virtio"
    bridge = var.bridge
  }

  ciuser  = var.cloud_init_user
  cipassword = var.cloud_init_password
  
  ipconfig0 = var.ipconfig

  lifecycle {
    ignore_changes = [
      cipassword,
      network
    ]
  }
}
