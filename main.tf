provider "aws" {
  shared_config_files = [ "~/.aws/credentials" ]
  shared_credentials_files = [ "~/.aws/config" ]
  profile = "default"
}
module "main_vpc" {
  source = "./vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  
}
module "subnet" {
  source = "./subnet"
  for_each = var.subnets
  subnet_name = each.key
  vpc_id = module.main_vpc.vpc_id
  subnet_cidr = each.value
  availability_zone = "us-east-1${regex("[a-z]$", each.key)}"
  map_public_ip = split("-", each.key)[0] == "public" ? true : false
}
module "igw" {
  source = "./igw"
  vpc_id = module.main_vpc.vpc_id
  igw_name = var.igw_name
}
module "nat_gw" {
  source = "./nat_eip"
  subnet_id = module.subnet["public-0.0-a"].subnet_id
  name_nat = var.natgw_name
}
module "public_route_table" {
  source = "./route_table"
  #for_each = toset(var.rt_name) # var.rt_name = ["public", "private"]
  vpc_id = module.main_vpc.vpc_id
  destination_ip = var.destination_ip
  #gw_id = each.key == "public" ? module.igw.igw_id : module.nat_gw.nat_gw_id
  gw_id = module.igw.igw_id
  rt_name = "public"
}
module "public_route_table_assoc" {
  source   = "./route_table_association"
  for_each = { for k, v in var.subnets : k => v if split("-", k)[0] == "public" }
  subnet_id = module.subnet[each.key].subnet_id
  route_table_id = module.public_route_table.route_table_id
  #region = substr(each.key, length(each.key) - 1, 1)
}
resource "aws_main_route_table_association" "main_to_public" {
  vpc_id         = module.main_vpc.vpc_id
  route_table_id = module.public_route_table.route_table_id
}
module "private_route_table" {
  source = "./route_table"
  #for_each = toset(var.rt_name) # var.rt_name = ["public", "private"]
  vpc_id = module.main_vpc.vpc_id
  destination_ip = var.destination_ip
  #gw_id = each.key == "public" ? module.igw.igw_id : module.nat_gw.nat_gw_id
  gw_id = module.nat_gw.nat_gw_id
  rt_name = "private"
}
module "private_route_table_assoc" {
  source   = "./route_table_association"
  for_each = { for k, v in var.subnets : k => v if split("-", k)[0] == "private" }
  subnet_id = module.subnet[each.key].subnet_id
  route_table_id = module.private_route_table.route_table_id
  #region = substr(each.key, length(each.key) - 1, 1)
}
module "sg_proxy" {
  source = "./sec_group"
  vpc_id = module.main_vpc.vpc_id
  name   = "proxy-sg"
  ingress = [
    { from = 80, to = 80, protocol = "tcp", cidr_blocks = ["0.0.0.0/0"] } # allow http
  ]
}

module "sg_backend" {
  source = "./sec_group"
  vpc_id = module.main_vpc.vpc_id
  name   = "backend-sg"
  ingress = [
    { from = 80, to = 80, protocol = "tcp", cidr_blocks = [var.subnets["private-1.0-a"],var.subnets["private-3.0-b"]] } # only from private subnets (or ALB)
  ]
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
module "ec2_proxy" {
  source = "./ec2"
  ami_id = data.aws_ami.amazon_linux.id
  #instance_type = "t3.micro"
  subnet_ids = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "public"]
  sg_id = module.sg_proxy.sg_id
  user_data = file("scripts/proxy_user_data.sh")
  connection_user = "ec2-user"
  connection_private_key = local_file.private_key.filename
  remote_install = true
}
module "ec2_backend" {
  source = "./ec2"
  ami_id = data.aws_ami.amazon_linux.id
  #instance_type = "t3.micro"
  subnet_ids = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "private"]
  sg_id = module.sg_backend.sg_id
  user_data = file("scripts/backend_user_data.sh")
  connection_user = var.key_pair_user
  connection_private_key = local_file.private_key.filename
  remote_install = false
}
module "public_elb" {
  source = "./elb"
  name = "app-alb"
  internal = false
  subnets = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "public"]
  sg_id = module.sg_proxy.sg_id
  vpc_id = module.main_vpc.vpc_id
  target_instance_ids = module.ec2_backend.instance_ids
}
module "private_elb" {
  source = "./elb"
  name = "app-alb-internal"
  internal = true
  subnets = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "private"]
  sg_id = module.sg_backend.sg_id
  vpc_id = module.main_vpc.vpc_id
  target_instance_ids = module.ec2_backend.instance_ids
  
}
# Save all IPs to all-ips.txt using local-exec
resource "null_resource" "write_ips" {
  triggers = {
    proxy_ips   = join(",", module.ec2_proxy.public_ips)
    backend_ips = join(",", module.ec2_backend.private_ips)
  }

  provisioner "local-exec" {
    command = <<EOT
cat > all-ips.txt <<EOF
public-ip1 ${module.ec2_proxy.public_ips[0]}
public-ip2 ${element(module.ec2_proxy.public_ips,1)}
private-ip1 ${module.ec2_backend.private_ips[0]}
private-ip2 ${element(module.ec2_backend.private_ips,1)}
EOF
EOT
  }
}

