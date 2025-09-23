resource "aws_instance" "instance" {
  count                       = length(var.subnet_ids)
  ami                         = var.ami_id
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_ids[count.index]
  vpc_security_group_ids      = [var.sg_id]
  associate_public_ip_address = var.public_ip_address # proxies need public IPs; for private instances instance will be false if subnet has no map_public_ip_on_launch
  user_data                   = var.user_data
  tags                        = { Name = "custom-ec2-${var.instance_name}-${count.index}" }
  key_name                    = var.key_pem
}