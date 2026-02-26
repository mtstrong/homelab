terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc07"
    }
  }
}

resource "proxmox_vm_qemu" "longhorn_vm" {
  name       = var.vm_name
  target_node = var.target_node
  vmid       = var.vmid

  clone      = var.clone_template

  cpu {
    cores   = var.cores
    sockets = var.sockets
  }
  memory = var.memory
  balloon = 0

  network {
    id     = 0
    model  = "virtio"
    bridge = var.bridge
    tag    = var.vlan_tag
  }

  ciuser      = var.cloud_init_user
  cipassword  = var.cloud_init_password
  sshkeys     = var.ssh_keys
  
  ipconfig0   = var.ipconfig

  bootdisk    = "scsi0"
  boot        = "c"
  
  scsihw      = "virtio-scsi-pci"

  # Cloud-init always enabled
  define_connection_info = true

  lifecycle {
    ignore_changes = [
      cipassword,
      sshkeys,
      network
    ]
  }
}
