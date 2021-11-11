terraform {
  backend "azurerm" {
    # POPULATED THROUGH PIPELINE
    use_azuread_auth     = true
  }
}

data "terraform_remote_state" "resources_state" {
  backend = "azurerm"
  config = {
    storage_account_name = var.state_storage_account_name
    container_name       = "tfstate"
    key                  = "resources.tfstate"
    use_azuread_auth     = true
  }
}