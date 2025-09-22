output "vpc_id" {
  description = "The ID of VPC"
  value = aws_vpc.vpc.id
}