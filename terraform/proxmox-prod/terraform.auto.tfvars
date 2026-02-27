# Auto-loaded Terraform variables (can be committed to git)
# Secrets are provided via environment variables

proxmox_api_url      = "https://bd790i.local:8006/api2/json"
proxmox_tls_insecure = true
clone_template       = "ubuntu-cloud"

## Control Planes (1 per node for HA)
control_vms = {
  "k3s-01" = {
    name        = "k3s-01"
    target_node = "um773a"
    vmid        = 201
    cores       = 8
    memory      = 8192
    disk_size   = "40G"
    ipconfig    = "ip=dhcp"
  }
  "k3s-02" = {
    name        = "k3s-02"
    target_node = "um773b"
    vmid        = 202
    cores       = 8
    memory      = 8192
    disk_size   = "40G"
    ipconfig    = "ip=dhcp"
  }
  "k3s-03" = {
    name        = "k3s-03"
    target_node = "um773c"
    vmid        = 203
    cores       = 8
    memory      = 8192
    disk_size   = "40G"
    ipconfig    = "ip=dhcp"
  }
}

## Worker Nodes
worker_vms = {
  "k3s-04" = {
    name        = "k3s-04"
    target_node = "um773b"
    vmid        = 204
    cores       = 8
    memory      = 8192
    disk_size   = "40G"
    ipconfig    = "ip=dhcp"
  }
  "k3s-05" = {
    name        = "k3s-05"
    target_node = "um773c"
    vmid        = 205
    cores       = 8
    memory      = 8192
    disk_size   = "40G"
    ipconfig    = "ip=dhcp"
  }
  "k3s-06" = {
    name        = "k3s-06"
    target_node = "um773a"
    vmid        = 206
    cores       = 8
    memory      = 8192
    disk_size   = "40G"
    ipconfig    = "ip=dhcp"
  }
}

## Longhorn Storage Nodes
longhorn_vms = {
  "lh-01" = {
    name        = "lh-01"
    target_node = "um773a"
    vmid        = 250
    cores       = 4
    memory      = 4096
    disk_size   = "250G"
    ipconfig    = "ip=dhcp"
  }
  "lh-02" = {
    name        = "lh-02"
    target_node = "um773b"
    vmid        = 251
    cores       = 4
    memory      = 4096
    disk_size   = "250G"
    ipconfig    = "ip=dhcp"
  }
  "lh-03" = {
    name        = "lh-03"
    target_node = "um773c"
    vmid        = 252
    cores       = 4
    memory      = 4096
    disk_size   = "250G"
    ipconfig    = "ip=dhcp"
  }
}
