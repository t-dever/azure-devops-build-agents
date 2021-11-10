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