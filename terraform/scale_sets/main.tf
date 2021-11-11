resource "azurerm_linux_virtual_machine_scale_set" "ubuntu20_virtual_machine_scale_set" {
  count = var.create_ubuntu20_scale_set ? 1 : 0
  lifecycle {
    ignore_changes = [instances, tags, automatic_os_upgrade_policy, extension]
  }
  name                            = "${var.resource_prefix}-ubuntu20-vmss"
  resource_group_name             = data.terraform_remote_state.resources_state.outputs.resource_group_name
  location                        = data.terraform_remote_state.resources_state.outputs.resource_group_location
  sku                             = "Standard_D2_v3"
  instances                       = 1
  admin_username                  = "builderAdmin"
  admin_password                  = data.terraform_remote_state.resources_state.outputs.build_agent_secret
  source_image_id                 = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${data.azurerm_resource_group.resource_group.name}/providers/Microsoft.Compute/galleries/${azurerm_shared_image_gallery.image_gallery.name}/images/ubuntu2004"
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
      subnet_id = data.terraform_remote_state.resources_state.outputs.build_agent_subnet_id
    }
  }
  boot_diagnostics {
    storage_account_uri = data.terraform_remote_state.resources_state.outputs.boot_diagnostics_storage_account_primary_endpoint
  }
}
