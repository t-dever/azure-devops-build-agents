terraform {
  backend "azurerm" {
    # POPULATED THROUGH PIPELINE
    use_azuread_auth = true
    key              = "resources.tfstate"
    container_name   = "tfstate"
  }
}
