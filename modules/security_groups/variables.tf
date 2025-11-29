# Security Groups Module Variables

variable "vpc_id" {
  description = "ID of the VPC where security groups will be created"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "multi-tier-proxy"
}

variable "management_cidr" {
  description = "CIDR block for management access (SSH)"
  type        = string
  default     = "0.0.0.0/0"
}