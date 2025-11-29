# Load Balancer Module Variables

variable "name" {
  description = "Name of the load balancer"
  type        = string
}

variable "internal" {
  description = "Whether the load balancer is internal (true) or internet-facing (false)"
  type        = bool
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs where the load balancer will be deployed"
  type        = list(string)
}

variable "security_group_ids" {
  description = "List of security group IDs for the load balancer"
  type        = list(string)
}

variable "target_instance_ids" {
  description = "List of EC2 instance IDs to register as targets"
  type        = list(string)
}

variable "target_port" {
  description = "Port on which targets receive traffic"
  type        = number
  default     = 80
}

variable "vpc_id" {
  description = "ID of the VPC where the target group will be created"
  type        = string
}