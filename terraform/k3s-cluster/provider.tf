terraform {
  required_version = ">= 1.0.0"
  
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
}

# Provider for UM773A (Master1 - 192.168.2.106)
provider "proxmox" {
  alias           = "um773a"
  pm_api_url      = var.um773a_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
}

# Provider for UM773B (Master2 - 192.168.2.102)
provider "proxmox" {
  alias           = "um773b"
  pm_api_url      = var.um773b_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
}

# Provider for UM773C (Master3 & Workers - 192.168.2.103, 104, 105)
provider "proxmox" {
  alias           = "um773c"
  pm_api_url      = var.um773c_api_url
  pm_user         = var.pm_user
  pm_password     = var.pm_password
  pm_tls_insecure = var.pm_tls_insecure
}
