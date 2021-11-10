terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.80.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
  skip_provider_registration = true
  storage_use_azuread        = true
}

data "azurerm_client_config" "current" {}

data "azurerm_resource_group" "resource_group" {
  name = "${var.resource_prefix}-rg"
}

data "azurerm_storage_account" "storage_account" {
  name                = replace("${var.resource_prefix}sa", "-", "")
  resource_group_name = data.azurerm_resource_group.resource_group.name
}

resource "azurerm_role_assignment" "storage_account_user_blob_owner" {
  scope                = data.azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.user_principal_id
}

resource "azurerm_role_assignment" "storage_account_pipeline_contributor" {
  scope                = data.azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "storage_account_user_contributor" {
  scope                = data.azurerm_storage_account.storage_account.id
  role_definition_name = "Storage Account Contributor"
  principal_id         = var.user_principal_id
}

resource "azurerm_storage_account" "images_storage_account" {
  name                     = replace("${var.resource_prefix}imagesa", "-", "")
  resource_group_name      = data.azurerm_resource_group.resource_group.name
  location                 = data.azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_shared_image_gallery" "image_gallery" {
  name                = replace("${var.resource_prefix}-image-gallery", "-", "")
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  description         = "Shared build agent images."
}

resource "azurerm_key_vault" "key_vault" {
  name                        = "${var.resource_prefix}-kv"
  location                    = data.azurerm_resource_group.resource_group.location
  resource_group_name         = data.azurerm_resource_group.resource_group.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true
  sku_name                    = "standard"
}

resource "azurerm_role_assignment" "key_vault_pipeline_service_principal" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "key_vault_user" {
  scope                = azurerm_key_vault.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = var.user_principal_id
}

resource "random_password" "generate_build_agent_secret" {
  length           = 24
  min_upper        = 2
  min_numeric      = 2
  min_special      = 2
  special          = true
  override_special = "_%@"
}

resource "azurerm_key_vault_secret" "build_agent_admin_secret" {
  name         = "build-agent-admin-pw"
  value        = random_password.generate_build_agent_secret.result
  key_vault_id = azurerm_key_vault.key_vault.id
}
