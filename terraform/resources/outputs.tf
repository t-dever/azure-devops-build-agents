output "resource_group_name" {
    value = data.azurerm_resource_group.resource_group.name
}
output "resource_group_location" {
    value = data.azurerm_resource_group.resource_group.location
}
output "build_agent_subnet_id" {
    value = azurerm_subnet.internal.id
}
output "build_agent_secret" {
    value = random_password.generate_build_agent_secret.result
    sensitive = true
}
output "boot_diagnostics_storage_account_primary_endpoint" {
    value = azurerm_storage_account.scale_set_boot_diagnostics_storage_account.primary_blob_endpoint
}