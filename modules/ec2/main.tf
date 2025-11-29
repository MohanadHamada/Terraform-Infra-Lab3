# EC2 Module - Creates EC2 instances with AMI data source and user data

# Data source for Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instances
resource "aws_instance" "main" {
  count                       = var.instance_count
  ami                         = data.aws_ami.amazon_linux.id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = var.security_group_ids
  associate_public_ip_address = var.associate_public_ip
  # key_name removed - using AWS Console/Session Manager for access
  user_data                   = var.user_data_script

  root_block_device {
    volume_type = "gp3"
    volume_size = 20
    encrypted   = true
  }

  tags = {
    Name = "${var.name_prefix}-${count.index + 1}"
    Type = var.instance_type_tag
  }

  # Local-exec provisioner to collect IP addresses
  provisioner "local-exec" {
    command = var.associate_public_ip ? "echo '${var.ip_prefix}-${count.index + 1} ${self.public_ip}' >> all-ips.txt" : "echo '${var.ip_prefix}-${count.index + 1} ${self.private_ip}' >> all-ips.txt"
  }
}