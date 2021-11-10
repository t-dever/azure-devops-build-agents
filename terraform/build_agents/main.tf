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

resource "azurerm_shared_image_gallery" "image_gallery" {
  name                = replace("${var.resource_prefix}-image-gallery", "-", "")
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  description         = "Shared build agent images."
}

resource "azurerm_nat_gateway" "nat_gateway" {
  name                    = "${var.resource_prefix}-nat-gateway"
  location                = data.azurerm_resource_group.resource_group.location
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
}

resource "azurerm_public_ip" "public_ip" {
  name                    = "${var.resource_prefix}-public-ip"
  location                = data.azurerm_resource_group.resource_group.location
  resource_group_name     = data.azurerm_resource_group.resource_group.name
  sku                     = "Standard"
  allocation_method       = "Static"
  idle_timeout_in_minutes = 30
}

resource "azurerm_nat_gateway_public_ip_association" "nat_gateway_association" {
  nat_gateway_id       = azurerm_nat_gateway.nat_gateway.id
  public_ip_address_id = azurerm_public_ip.public_ip.id
}

resource "azurerm_virtual_network" "virtual_network" {
  name                = "${var.resource_prefix}-vnet"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = data.azurerm_resource_group.resource_group.name
  virtual_network_name = azurerm_virtual_network.virtual_network.name
  address_prefixes     = ["10.0.2.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet_nat_gateway_association" "nat_gateway_association" {
  subnet_id      = azurerm_subnet.internal.id
  nat_gateway_id = azurerm_nat_gateway.nat_gateway.id
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

resource "azurerm_storage_account" "scale_set_boot_diagnostics_storage_account" {
  name                     = replace("${var.resource_prefix}bootsa", "-", "")
  resource_group_name      = data.azurerm_resource_group.resource_group.name
  location                 = data.azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "images_storage_account" {
  name                     = replace("${var.resource_prefix}imagesa", "-", "")
  resource_group_name      = data.azurerm_resource_group.resource_group.name
  location                 = data.azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_linux_virtual_machine_scale_set" "ubuntu20_virtual_machine_scale_set" {
  count = var.create_ubuntu20_scale_set ? 1 : 0
  lifecycle {
    ignore_changes = [instances, tags, automatic_os_upgrade_policy, extension]
  }
  name                = "${var.resource_prefix}-ubuntu20-vmss"
  resource_group_name = data.azurerm_resource_group.resource_group.name
  location            = data.azurerm_resource_group.resource_group.location
  sku                 = "Standard_D2_v3"
  #   sku                 = "Standard_DS1_v2"
  #   sku                 = "Standard_D4ds_v4"
  instances                       = 1
  admin_username                  = "builderAdmin"
  admin_password                  = random_password.generate_build_agent_secret.result
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.resource_group.name}/providers/Microsoft.Compute/galleries/${azurerm_shared_image_gallery.image_gallery.name}/images/ubuntu.20.04"
  disable_password_authentication = false
  overprovision                   = false
  upgrade_mode                    = "Manual"
  single_placement_group          = false
  priority                        = var.scale_set_spot_instance ? "Spot" : "Regular"
  eviction_policy                 = var.scale_set_spot_instance ? "Deallocate" : null
  max_bid_price                   = var.scale_set_spot_instance ? -1 : null

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  network_interface {
    name                          = "default"
    primary                       = true
    enable_accelerated_networking = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.internal.id
    }
  }
  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.scale_set_boot_diagnostics_storage_account.primary_blob_endpoint
  }
}
