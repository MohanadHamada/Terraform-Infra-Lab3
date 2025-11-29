# Terraform Variables Values

# AWS Configuration
aws_region         = "us-east-1"
availability_zones = ["us-east-1a", "us-east-1b"]

# Remote Backend Configuration
state_bucket_name         = "terraform-iti-s3-bucket"
state_dynamodb_table_name = "terraform-state-lock-multi-tier-proxy"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.3.0/24"]
private_subnet_cidrs = ["10.0.2.0/24", "10.0.4.0/24"]

# EC2 Configuration
instance_type = "t3.micro"


# Project Configuration
project_name = "multi-tier-proxy"
environment  = "dev"

# Load Balancer Configuration
enable_deletion_protection = false
health_check_path          = "/health"


