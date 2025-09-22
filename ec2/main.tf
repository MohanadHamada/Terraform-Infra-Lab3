resource "aws_instance" "instance" {
  count = length(var.subnet_ids)
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = var.subnet_ids[count.index]
  vpc_security_group_ids = [var.sg_id]
  associate_public_ip_address = true  # proxies need public IPs; for private instances instance will be false if subnet has no map_public_ip_on_launch
  user_data     = var.user_data
  tags = { Name = "custom-ec2-${count.index}" }
}

# Remote-exec provisioner only for instances that have public IP available
resource "null_resource" "remote_provision" {
  count = length(aws_instance.instance)

  triggers = {
    instance_id     = aws_instance.instance[count.index].id
    public_ip       = aws_instance.instance[count.index].public_ip
    remote_install  = tostring(var.remote_install)
  }

  provisioner "remote-exec" {
    when = create
    inline = [
      "sudo yum update -y || true",
      "sudo yum install -y httpd || true",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd"
    ]

    connection {
      type        = "ssh"
      user        = var.connection_user
      private_key = file(var.connection_private_key)
      host        = aws_instance.instance[count.index].public_ip
      timeout     = "2m"
    }
  }

  depends_on = [aws_instance.instance]
}