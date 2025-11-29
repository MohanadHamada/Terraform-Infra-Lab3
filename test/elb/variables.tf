variable "name" {}
variable "internal" {
  type    = bool
  default = false
}
variable "subnets" { type = list(string) }
variable "sg_id" {}
variable "vpc_id" { type = string }
variable "target_instance_ids" { type = list(string) }