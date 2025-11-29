
output "proxy_public_ips" {
  value = module.ec2_proxy.public_ips
}

output "backend_private_ips" {
  value = module.ec2_backend.private_ips
}

output "public_elb_dns" {
  value = module.public_elb.dns_name
}

output "private_elb_dns" {
  value = module.private_elb.dns_name
}