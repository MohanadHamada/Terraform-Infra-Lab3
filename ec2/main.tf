resource "aws_instance" "instance" {
  count = length(var.subnet_ids)
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index]
  vpc_security_group_ids = [var.sg_id]
  associate_public_ip_address = var.public_ip_address  # proxies need public IPs; for private instances instance will be false if subnet has no map_public_ip_on_launch
  #user_data     = var.user_data
  tags = { Name = "custom-ec2-${var.instance_name}-${count.index}" }
  key_name = var.key_pem
  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = var.connection_user
      private_key = var.private_key_pem
      host        = var.public_ip_address ? self.public_ip : self.private_ip 
    }
    inline = [
      "sudo yum update -y || sudo apt update -y",
      "sudo yum install -y nginx || sudo apt install -y nginx",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "echo 'Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)'",
      "if curl -s http://169.254.169.254/latest/meta-data/public-ipv4 >/dev/null 2>&1; then echo 'Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)'; fi"
    ]
    
  }
  provisioner "local-exec" {
    command = "echo ${var.instance_name}-ip${count.index + 1} ${self.public_ip != "" ? self.public_ip : self.private_ip} >> all-ips.txt"
  }
}