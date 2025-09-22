resource "aws_route_table" "rout_table" {
  vpc_id = var.vpc_id
  route {
    cidr_block = var.destination_ip
    gateway_id = var.gw_id
  }
  tags = {Name = var.rt_name}
}