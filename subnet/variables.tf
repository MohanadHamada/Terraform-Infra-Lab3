variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string

}
variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  type        = string

}
variable "availability_zone" {
  description = "The availability zone for the subnet"
  type        = string

}
variable "subnet_name" {
  description = "The name of the subnet"
  type        = string
}
variable "map_public_ip" {
  type = bool
}