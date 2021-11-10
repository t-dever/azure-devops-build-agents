variable "resource_prefix" {
  description = "The prefix to the resource group that will be used for all created resources"
}
variable "user_principal_id" {
  description = "The ID of the user that needs to access the key vault via Azure Portal GUI. This is used to give key vault secrets officer role"
}