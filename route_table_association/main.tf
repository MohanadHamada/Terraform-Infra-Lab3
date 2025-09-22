resource "aws_route_table_association" "rt_assoc" {
  subnet_id      = var.subnet_id #aws_subnet.subnet["public"].id
  route_table_id = var.route_table_id
  #region = var.region
}