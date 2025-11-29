# EC2 Module Outputs

output "instance_ids" {
  description = "List of EC2 instance IDs"
  value       = aws_instance.main[*].id
}

output "private_ips" {
  description = "List of private IP addresses"
  value       = aws_instance.main[*].private_ip
}

output "public_ips" {
  description = "List of public IP addresses (if applicable)"
  value       = aws_instance.main[*].public_ip
}

output "instance_arns" {
  description = "List of EC2 instance ARNs"
  value       = aws_instance.main[*].arn
}

output "ami_id" {
  description = "AMI ID used for the instances"
  value       = data.aws_ami.amazon_linux.id
}