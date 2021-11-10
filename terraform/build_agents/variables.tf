variable "resource_prefix" {
  description = "The prefix to the resource group that will be used for all created resources"
}
variable "user_principal_id" {
  description = "The ID of the user that needs to access the key vault via Azure Portal GUI. This is used to give key vault secrets officer role"
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