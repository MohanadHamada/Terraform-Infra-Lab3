output "vpc_id" {
  description = "The ID of VPC"
  value       = aws_vpc.vpc.id
}
output "vpc_cidr" {
  description = "The CIDR block of VPC"
  value       = aws_vpc.vpc.cidr_block
}