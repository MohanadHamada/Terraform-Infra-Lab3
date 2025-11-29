# NAT Gateway Module - Creates NAT Gateway and configures routing for private subnet

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "multi-tier-proxy-nat-eip"
  }

  depends_on = [var.internet_gateway_id]
}

# NAT Gateway
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "multi-tier-proxy-nat-gateway"
  }

  depends_on = [var.internet_gateway_id]
}

# Route for private subnet to NAT Gateway
resource "aws_route" "private_nat" {
  route_table_id         = var.private_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}