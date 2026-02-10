terraform {
  required_version = ">= 1.5"

  # -------------------------------------------------------
  # Remote state in Azure Blob Storage
  # -------------------------------------------------------
  backend "azurerm" {
    resource_group_name  = "rg-tofu-state"
    storage_account_name = "stmthomelabstate"
    container_name       = "tfstate"
    key                  = "cloudflare-dns.tfstate"
    use_oidc             = true
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}
