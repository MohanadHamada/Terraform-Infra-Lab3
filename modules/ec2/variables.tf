# EC2 Module Variables

variable "instance_count" {
  description = "Number of EC2 instances to create"
  type        = number
  default     = 1
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "subnet_id" {
  description = "ID of the subnet where instances will be launched"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to assign to instances"
  type        = list(string)
}

variable "associate_public_ip" {
  description = "Whether to associate a public IP address with instances"
  type        = bool
  default     = false
}

variable "user_data_script" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

# key_name removed - using AWS Console/Session Manager for access

variable "name_prefix" {
  description = "Prefix for instance names"
  type        = string
}

variable "instance_type_tag" {
  description = "Tag to identify the type of instance (proxy, backend, etc.)"
  type        = string
}



variable "ip_prefix" {
  description = "Prefix for IP address entries in all-ips.txt file"
  type        = string
}