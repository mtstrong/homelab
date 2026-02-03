terraform {
  backend "azurerm" {
    resource_group_name  = "rg-uptimekuma-monitoring"
    storage_account_name = "tfstatehomelabmatt"
    container_name       = "tfstate"
    key                  = "uptimekuma.tfstate"
    use_oidc             = true
  }
}
