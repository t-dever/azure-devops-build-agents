variable "resource_prefix" {
  description = "The prefix to the resource group that will be used for all created resources"
}

variable "state_storage_account_name" {
  description = "The name of the storage account where state is stored."
  type = string
}

variable "scale_set_spot_instance" {
  description = "Set this to true if you want the scale set to be spot instances for price savings."
  type = bool
  default = false
}

variable "create_ubuntu20_scale_set" {
  description = "Set this to true if you want to create an ubunt20 scale set."
  type = bool
  default = false
}