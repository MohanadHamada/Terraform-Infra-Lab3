variable "ami_id" {}
variable "instance_type" {}
variable "subnet_ids" { type = list(string) }
variable "sg_id" {}
#variable "user_data" { default = "" }
variable "public_ip_address" {
  type = bool
}
variable "connection_user" { default = "ec2-user" }
variable "key_pem" {
  type = string

}
variable "instance_name" {
  type = string
}
variable "user_data" {
  type    = string
  default = ""
} 