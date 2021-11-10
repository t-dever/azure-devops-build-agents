terraform {
  backend "azurerm" {
    # POPULATED THROUGH PIPELINE
    use_azuread_auth     = true
  }
}