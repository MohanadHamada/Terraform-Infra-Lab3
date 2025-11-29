# Root Variables Configuration

# AWS Configuration
variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.aws_region))
    error_message = "AWS region must be in the format like 'us-east-1'."
  }
}

variable "availability_zones" {
  description = "List of availability zones for resources"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]

  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "At least two availability zones must be specified for ALB requirements."
  }
}

# Remote Backend Configuration
variable "state_bucket_name" {
  description = "Name of the S3 bucket for Terraform state storage"
  type        = string
  default     = "terraform-iti-s3-bucket"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.state_bucket_name))
    error_message = "S3 bucket name must be lowercase, contain only letters, numbers, and hyphens."
  }
}

variable "state_dynamodb_table_name" {
  description = "Name of the DynamoDB table for Terraform state locking"
  type        = string
  default     = "terraform-state-lock-multi-tier-proxy"
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be a valid IPv4 CIDR block."
  }
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.3.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) >= 2
    error_message = "At least two public subnet CIDRs must be specified."
  }
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.2.0/24", "10.0.4.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnet CIDRs must be specified."
  }
}

# EC2 Configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"

  validation {
    condition = contains([
      "t3.micro", "t3.small", "t3.medium", "t3.large",
      "t2.micro", "t2.small", "t2.medium", "t2.large"
    ], var.instance_type)
    error_message = "Instance type must be a valid EC2 instance type."
  }
}

# Key pair removed - using AWS Console/Session Manager for access



# Project Configuration
variable "project_name" {
  description = "Name of the project for resource tagging"
  type        = string
  default     = "multi-tier-proxy"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Load Balancer Configuration
variable "enable_deletion_protection" {
  description = "Enable deletion protection for load balancers"
  type        = bool
  default     = false
}

variable "health_check_path" {
  description = "Health check path for load balancer targets"
  type        = string
  default     = "/health"
}

variable "management_cidr" {
  description = "CIDR block for management access (SSH)"
  type        = string
  default     = "0.0.0.0/0"
}

# User Data Scripts
variable "proxy_user_data_script" {
  description = "User data script for proxy EC2 instances"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    
    # Create health check endpoint first
    echo "Proxy OK" > /var/www/html/health
    
    # Configure Apache as reverse proxy to private ALB
    cat > /etc/httpd/conf.d/proxy.conf << 'APACHE_EOF'
LoadModule proxy_module modules/mod_proxy.so
LoadModule proxy_http_module modules/mod_proxy_http.so

<VirtualHost *:80>
    # Health check endpoint - serve locally, don't proxy
    ProxyPass /health !
    
    # Proxy all other requests to private ALB
    ProxyPreserveHost On
    ProxyPass / http://PRIVATE_ALB_DNS_PLACEHOLDER/
    ProxyPassReverse / http://PRIVATE_ALB_DNS_PLACEHOLDER/
</VirtualHost>
APACHE_EOF
    
    # Start and enable httpd
    systemctl start httpd
    systemctl enable httpd
  EOF
}

variable "backend_user_data_script" {
  description = "User data script for backend EC2 instances"
  type        = string
  default     = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" -s)
    echo "<h1>Hello from Terraform Lab2 - Backend Server</h1>" > /var/www/html/index.html
    echo "<p>Instance ID: $(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/instance-id)</p>" >> /var/www/html/index.html
    echo "<p>Private IP: $(hostname -I)</p>" >> /var/www/html/index.html
    echo "<p>Public IP: $(curl -H "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)</p>" >> /var/www/html/index.html
    echo "<p>Server Type: Backend</p>" >> /var/www/html/index.html
    
    # Create health check endpoint
    echo "Backend OK" > /var/www/html/health
  EOF
}
