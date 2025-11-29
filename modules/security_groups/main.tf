# Security Groups Module - Creates security groups for multi-tier architecture

# Security Group for Public Application Load Balancer
resource "aws_security_group" "public_alb" {
  name        = "multi-tier-proxy-public-alb-sg"
  description = "Security group for public Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from internet
  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from internet
  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "multi-tier-proxy-public-alb-sg"
  }
}

# Security Group for Proxy Instances
resource "aws_security_group" "proxy" {
  name        = "multi-tier-proxy-instances-sg"
  description = "Security group for nginx proxy instances"
  vpc_id      = var.vpc_id

  # Allow HTTP from Public ALB
  ingress {
    description     = "HTTP from Public ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.public_alb.id]
  }

  # Allow SSH for management (restrict to your IP in production)
  ingress {
    description = "SSH for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Restrict this in production
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "multi-tier-proxy-instances-sg"
  }
}

# Security Group for Private Application Load Balancer
resource "aws_security_group" "private_alb" {
  name        = "multi-tier-proxy-private-alb-sg"
  description = "Security group for private Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from Proxy instances
  ingress {
    description     = "HTTP from Proxy instances"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.proxy.id]
  }

  # Allow all outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "multi-tier-proxy-private-alb-sg"
  }
}

# Security Group for Backend Instances
resource "aws_security_group" "backend" {
  name        = "multi-tier-proxy-backend-sg"
  description = "Security group for backend web server instances"
  vpc_id      = var.vpc_id

  # Allow HTTP from Private ALB
  ingress {
    description     = "HTTP from Private ALB"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.private_alb.id]
  }

  # Allow SSH through NAT Gateway (for management)
  ingress {
    description = "SSH for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.0/24"]  # Only from public subnet
  }

  # Allow all outbound traffic (for package installation through NAT)
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "multi-tier-proxy-backend-sg"
  }
}