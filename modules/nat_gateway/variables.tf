# NAT Gateway Module Variables

variable "public_subnet_id" {
  description = "ID of the public subnet where NAT Gateway will be placed"
  type        = string
}

variable "private_route_table_id" {
  description = "ID of the private route table to configure NAT Gateway routing"
  type        = string
}

variable "internet_gateway_id" {
  description = "ID of the Internet Gateway (for dependency)"
  type        = string
}

variable "project_name" {
  description = "Name of the project for resource naming"
  type        = string
  default     = "multi-tier-proxy"
}