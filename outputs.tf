# Root Outputs Configuration

# Remote Backend Outputs
output "s3_bucket_name" {
  description = "Name of the S3 bucket for Terraform state"
  value       = module.remote_backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table for state locking"
  value       = module.remote_backend.dynamodb_table_name
}

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = module.vpc.public_subnet_id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = module.vpc.private_subnet_id
}

# NAT Gateway Outputs
output "nat_gateway_public_ip" {
  description = "Public IP address of the NAT Gateway"
  value       = module.nat_gateway.nat_gateway_public_ip
}

# Load Balancer Outputs
output "public_alb_dns_name" {
  description = "DNS name of the public Application Load Balancer"
  value       = module.public_alb.alb_dns_name
}

output "private_alb_dns_name" {
  description = "DNS name of the private Application Load Balancer"
  value       = module.private_alb.alb_dns_name
}

output "public_alb_url" {
  description = "URL of the public Application Load Balancer"
  value       = "http://${module.public_alb.alb_dns_name}"
}

# EC2 Instance Outputs
output "proxy_instance_ids" {
  description = "IDs of the proxy instances"
  value       = module.proxy_instances.instance_ids
}

output "proxy_public_ips" {
  description = "Public IP addresses of the proxy instances"
  value       = module.proxy_instances.public_ips
}

output "proxy_private_ips" {
  description = "Private IP addresses of the proxy instances"
  value       = module.proxy_instances.private_ips
}

output "backend_instance_ids" {
  description = "IDs of the backend instances"
  value       = module.backend_instances.instance_ids
}

output "backend_private_ips" {
  description = "Private IP addresses of the backend instances"
  value       = module.backend_instances.private_ips
}

# Security Group Outputs
output "security_group_ids" {
  description = "Map of security group IDs"
  value = {
    public_alb  = module.security_groups.public_alb_sg_id
    proxy       = module.security_groups.proxy_sg_id
    private_alb = module.security_groups.private_alb_sg_id
    backend     = module.security_groups.backend_sg_id
  }
}

# Infrastructure Summary
output "infrastructure_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    vpc_cidr             = var.vpc_cidr
    public_subnet_cidrs  = var.public_subnet_cidrs
    private_subnet_cidrs = var.private_subnet_cidrs
    proxy_instances      = length(module.proxy_instances.instance_ids)
    backend_instances    = length(module.backend_instances.instance_ids)
    public_alb_url       = "http://${module.public_alb.alb_dns_name}"
    environment          = var.environment
  }
}
