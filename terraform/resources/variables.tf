variable "resource_prefix" {
  description = "The prefix to the resource group that will be used for all created resources"
}
variable "user_principal_id" {
  description = "The ID of the user that needs to access the key vault via Azure Portal GUI. This is used to give key vault secrets officer role"
}

variable "storage_account_name" {
  description = "The name of the storage account used."
}

variable "image_storage_account_name" {
  description = "The name of the storage account to store images."
  default = replace("${var.resource_prefix}imagesa", "-", "")
}

variable "image_gallery_name" {
  description = "The image gallery name"
  default = replace("${var.resource_prefix}-image-gallery", "-", "")
}