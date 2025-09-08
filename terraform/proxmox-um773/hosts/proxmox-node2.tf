provider "proxmox" {
  pm_api_url      = "https://proxmox.example.com:8006/api2/json"
  pm_user         = "root@pam"
  pm_password     = "your_password"
  pm_tls_insecure = true
}

resource "proxmox_vm_qemu" "ubuntu_vm" {
  name        = "ubuntu-vm-node2"
  target_node = "proxmox-node2"
  vmid        = 101
  cores       = 2
  memory      = 2048
  sockets     = 1
  cpu         = "host"
  scsihw      = "virtio-scsi-pci"
  boot        = "cdn"
  bootdisk    = "scsi0"
  agent       = 1

  network {
    model    = "virtio"
    bridge   = "vmbr0"
  }

  disk {
    slot     = 0
    size     = "20G"
    type     = "scsi"
    storage  = "local-lvm"
    iothread = 1
  }

  os_type    = "cloud-init"
  iso        = "local:iso/ubuntu-22.04-live-server-amd64.iso"

  ciuser     = "ubuntu"
  cipassword = "ubuntu_password"
  sshkeys    = file("~/.ssh/id_rsa.pub")
}