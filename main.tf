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
module "seq_grp" {
  source = "./sec_group"
  vpc_id = module.main_vpc.vpc_id
}