resource "aws_eip" "nat_eip" {
  domain = "vpc"
}
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = var.subnet_id #aws_subnet.subnet["public"].id
  tags = {
    Name = var.name_nat
  }
}