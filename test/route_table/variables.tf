variable "vpc_id" {
  description = "The ID of the VPC"
  type        = string

}
variable "destination_ip" {
  type = string
}
variable "gw_id" {
  description = "The ID of the Internet Gateway"
  type        = string

}
variable "rt_name" {
  description = "The name of Rout Table"
  type        = string
}