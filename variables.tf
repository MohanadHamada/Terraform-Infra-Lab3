variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
  default = "10.0.0.0/16"
}
variable "vpc_name" {
  description = "The name of the VPC"
  type        = string
  default = "vpc-main"
}
variable "subnets" {
  description = "A map of subnet names to CIDR blocks"
  type        = map(string)
  
}
variable "igw_name" {
  type = string
  default = "igw-infra"
}
variable "destination_ip" {
  type = string
  default = "0.0.0.0/0"
}
variable "rt_name" {
  type = list(string)
}
variable "natgw_name" {
  type = string
  default = "nat-gw-infra"
}
variable "connection_user" {default = "ec2-user"}
variable "instance_type" { default = "t3.micro" }