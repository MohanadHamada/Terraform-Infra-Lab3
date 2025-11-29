# Security Groups Module Outputs

output "public_alb_sg_id" {
  description = "ID of the public Application Load Balancer security group"
  value       = aws_security_group.public_alb.id
}

output "proxy_sg_id" {
  description = "ID of the proxy instances security group"
  value       = aws_security_group.proxy.id
}

output "private_alb_sg_id" {
  description = "ID of the private Application Load Balancer security group"
  value       = aws_security_group.private_alb.id
}

output "backend_sg_id" {
  description = "ID of the backend instances security group"
  value       = aws_security_group.backend.id
}