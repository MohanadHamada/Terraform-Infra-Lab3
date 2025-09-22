variable "ami_id" {}
variable "instance_type" { default = "t3.micro" }
variable "subnet_ids" { type = list(string) }
variable "sg_id" {}
variable "user_data" { default = "" }
variable "connection_private_key" { default = "~/.ssh/id_rsa" }
variable "connection_user" { default = "ec2-user" }
variable "remote_install" { 
    type = bool
    default = true
}
