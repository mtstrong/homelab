provider "proxmox" {
  pm_api_url      = "https://proxmox.example.com:8006/api2/json"
  pm_user         = "root@pam"
  pm_password     = "your_password"
  pm_tls_insecure = true
}

module "proxmox_node1" {
  source = "./hosts/proxmox-node1.tf"
}

module "proxmox_node2" {
  source = "./hosts/proxmox-node2.tf"
}

module "proxmox_node3" {
  source = "./hosts/proxmox-node3.tf"
}