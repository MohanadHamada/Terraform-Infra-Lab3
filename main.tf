# Main Terraform Configuration for Multi-Tier Proxy Infrastructure

# Remote Backend Module - Creates S3 bucket and DynamoDB table for state management
module "remote_backend" {
  source = "./modules/remote_backend"

  bucket_name          = var.state_bucket_name
  dynamodb_table_name  = var.state_dynamodb_table_name
  region              = var.aws_region
}

# VPC Module - Creates VPC, subnets, and internet gateway
module "vpc" {
  source = "./modules/vpc"

  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  availability_zones   = var.availability_zones
  project_name         = var.project_name
}

# NAT Gateway Module - Creates NAT gateway for private subnet internet access
module "nat_gateway" {
  source = "./modules/nat_gateway"

  public_subnet_id        = module.vpc.public_subnet_id
  private_route_table_id  = module.vpc.private_route_table_id
  internet_gateway_id     = module.vpc.internet_gateway_id
  project_name           = var.project_name

  depends_on = [module.vpc]
}

# Security Groups Module - Creates security groups for all tiers
module "security_groups" {
  source = "./modules/security_groups"

  vpc_id          = module.vpc.vpc_id
  project_name    = var.project_name
  management_cidr = var.management_cidr

  depends_on = [module.vpc]
}

# Proxy EC2 Instances - Public subnet nginx proxy instances
module "proxy_instances" {
  source = "./modules/ec2"

  instance_count      = 2
  instance_type       = var.instance_type
  subnet_id           = module.vpc.public_subnet_id
  security_group_ids  = [module.security_groups.proxy_sg_id]
  associate_public_ip = true
  # key_name removed - using AWS Console/Session Manager for access
  name_prefix        = "${var.project_name}-proxy"
  instance_type_tag  = "proxy"
  ip_prefix          = "public-ip"

  # Use user data script with private ALB DNS placeholder
  user_data_script = replace(var.proxy_user_data_script, "PRIVATE_ALB_DNS_PLACEHOLDER", module.private_alb.alb_dns_name)

  depends_on = [module.vpc, module.security_groups, module.private_alb]
}

# Backend EC2 Instances - Private subnet web server instances
module "backend_instances" {
  source = "./modules/ec2"

  instance_count      = 2
  instance_type       = var.instance_type
  subnet_id           = module.vpc.private_subnet_id
  security_group_ids  = [module.security_groups.backend_sg_id]
  associate_public_ip = false
  
  name_prefix        = "${var.project_name}-backend"
  instance_type_tag  = "backend"
  ip_prefix          = "private-ip"

  user_data_script = var.backend_user_data_script

  depends_on = [module.vpc, module.security_groups, module.nat_gateway]
}

# Public Application Load Balancer - Internet-facing ALB for proxy instances
module "public_alb" {
  source = "./modules/load_balancer"

  name                = "multi-tier-public-alb"
  internal            = false
  subnet_ids          = module.vpc.public_subnet_ids
  security_group_ids  = [module.security_groups.public_alb_sg_id]
  target_instance_ids = module.proxy_instances.instance_ids
  target_port         = 80
  vpc_id              = module.vpc.vpc_id

  depends_on = [module.vpc, module.security_groups, module.proxy_instances]
}

# Private Application Load Balancer - Internal ALB for backend instances
module "private_alb" {
  source = "./modules/load_balancer"

  name                = "multi-tier-private-alb"
  internal            = true
  subnet_ids          = module.vpc.private_subnet_ids
  security_group_ids  = [module.security_groups.private_alb_sg_id]
  target_instance_ids = module.backend_instances.instance_ids
  target_port         = 80
  vpc_id              = module.vpc.vpc_id

  depends_on = [module.vpc, module.security_groups, module.backend_instances]
}