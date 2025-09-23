provider "aws" {
  shared_config_files      = ["~/.aws/credentials"]
  shared_credentials_files = ["~/.aws/config"]
  profile                  = "default"
}
module "main_vpc" {
  source   = "./vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name

}
module "subnet" {
  source            = "./subnet"
  for_each          = var.subnets
  subnet_name       = each.key
  vpc_id            = module.main_vpc.vpc_id
  subnet_cidr       = each.value
  availability_zone = "us-east-1${regex("[a-z]$", each.key)}"
  map_public_ip     = split("-", each.key)[0] == "public" ? true : false
}
module "igw" {
  source   = "./igw"
  vpc_id   = module.main_vpc.vpc_id
  igw_name = var.igw_name
}
module "nat_gw" {
  source    = "./nat_eip"
  subnet_id = module.subnet["public-0.0-a"].subnet_id
  name_nat  = var.natgw_name
}
module "public_route_table" {
  source = "./route_table"
  #for_each = toset(var.rt_name) # var.rt_name = ["public", "private"]
  vpc_id         = module.main_vpc.vpc_id
  destination_ip = var.destination_ip
  #gw_id = each.key == "public" ? module.igw.igw_id : module.nat_gw.nat_gw_id
  gw_id   = module.igw.igw_id
  rt_name = "public"
}
module "public_route_table_assoc" {
  source         = "./route_table_association"
  for_each       = { for k, v in var.subnets : k => v if split("-", k)[0] == "public" }
  subnet_id      = module.subnet[each.key].subnet_id
  route_table_id = module.public_route_table.route_table_id
  #region = substr(each.key, length(each.key) - 1, 1)
}
resource "aws_main_route_table_association" "main_to_public" {
  vpc_id         = module.main_vpc.vpc_id
  route_table_id = module.public_route_table.route_table_id
}
module "private_route_table" {
  source = "./route_table"
  #for_each = toset(var.rt_name) # var.rt_name = ["public", "private"]
  vpc_id         = module.main_vpc.vpc_id
  destination_ip = var.destination_ip
  #gw_id = each.key == "public" ? module.igw.igw_id : module.nat_gw.nat_gw_id
  gw_id   = module.nat_gw.nat_gw_id
  rt_name = "private"
}
module "private_route_table_assoc" {
  source         = "./route_table_association"
  for_each       = { for k, v in var.subnets : k => v if split("-", k)[0] == "private" }
  subnet_id      = module.subnet[each.key].subnet_id
  route_table_id = module.private_route_table.route_table_id
  #region = substr(each.key, length(each.key) - 1, 1)
}
/*data "http" "my_ip" {
  url = "https://checkip.amazonaws.com/"
}
locals {
  my_ip = "${chomp(data.http.my_ip.response_body)}/32"
}*/

module "sg_proxy" {
  source = "./sec_group"
  vpc_id = module.main_vpc.vpc_id
  name   = "proxy-sg"
  ingress = [
    {
      from        = 22
      to          = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from        = 80
      to          = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

module "sg_backend" {
  source = "./sec_group"
  vpc_id = module.main_vpc.vpc_id
  name   = "backend-sg"
  ingress = [
    {
      from            = 80
      to              = 80
      protocol        = "tcp"
      security_groups = [module.sg_proxy.sg_id]
    },
    {
      from            = 22
      to              = 22
      protocol        = "tcp"
      security_groups = [module.sg_proxy.sg_id]
    }
  ]
}
module "sg-private-load_balancer" {
  source = "./sec_group"
  vpc_id = module.main_vpc.vpc_id
  name   = "lb-private-sg"
  ingress = [
    {
      from            = 80
      to              = 80
      protocol        = "tcp"
      security_groups = [module.sg_proxy.sg_id]
    },
    {
      from        = 80
      to          = 80
      protocol    = "tcp"
      cidr_blocks = [module.main_vpc.vpc_cidr]
    }
  ]
}
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}
module "ec2_proxy" {
  source            = "./ec2"
  ami_id            = data.aws_ami.amazon_linux.id
  instance_type     = var.instance_type
  public_ip_address = true
  subnet_ids        = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "public"]
  sg_id             = module.sg_proxy.sg_id
  key_pem           = "terra-infra-key"
  user_data         = file("scripts/user_data_script.sh")
  connection_user   = var.connection_user
  instance_name     = "public"
}
module "ec2_backend" {
  source            = "./ec2"
  ami_id            = data.aws_ami.amazon_linux.id
  subnet_ids        = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "private"]
  sg_id             = module.sg_backend.sg_id
  instance_type     = var.instance_type
  public_ip_address = false
  instance_name     = "private"
  user_data         = file("scripts/user_data_script.sh")
  key_pem           = "terra-infra-key"
  connection_user   = var.connection_user
}

module "public_elb" {
  source              = "./elb"
  name                = "app-alb"
  internal            = false
  subnets             = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "public"]
  sg_id               = module.sg_proxy.sg_id
  vpc_id              = module.main_vpc.vpc_id
  target_instance_ids = module.ec2_proxy.instance_ids
}
module "private_elb" {
  source              = "./elb"
  name                = "app-alb-internal"
  internal            = true
  subnets             = [for k, v in var.subnets : module.subnet[k].subnet_id if split("-", k)[0] == "private"]
  sg_id               = module.sg_backend.sg_id
  vpc_id              = module.main_vpc.vpc_id
  target_instance_ids = module.ec2_backend.instance_ids

}

resource "null_resource" "configuration" {
  count      = length(module.ec2_proxy.instance_ids)
  depends_on = [module.ec2_proxy, module.public_elb]

  triggers = {
    lb_dns      = module.public_elb.dns_name
    instance_id = module.ec2_proxy.public_ips[count.index]
    force_run   = timestamp() # Force re-run on every apply
  }



  provisioner "remote-exec" {
    connection {
      type        = "ssh"
      user        = "ec2-user"
      private_key = file(var.key_pem)
      host        = module.ec2_proxy.public_ips[count.index]
    }

    inline = [
      "echo 'Configuring redirect to ${module.public_elb.dns_name} on instance ${count.index + 1}'",
      "sudo yum update -y",
      "sudo amazon-linux-extras install nginx1 -y",
      "sudo rm -f /etc/nginx/nginx.conf",
      "sudo tee /etc/nginx/nginx.conf > /dev/null <<EOF",
      "events {",
      "    worker_connections 1024;",
      "}",
      "http {",
      "    upstream private_lb {",
      "        server ${module.private_elb.dns_name}:80;",
      "    }",
      "    server {",
      "        listen 80;",
      "        server_name _;",
      "        location / {",
      "            proxy_pass http://private_lb;",
      "            proxy_set_header Host \\$host;",
      "            proxy_set_header X-Real-IP \\$remote_addr;",
      "            proxy_set_header X-Forwarded-For \\$proxy_add_x_forwarded_for;",
      "            proxy_set_header X-Forwarded-Proto \\$scheme;",
      "            proxy_connect_timeout 30s;",
      "            proxy_send_timeout 30s;",
      "            proxy_read_timeout 30s;",
      "        }",
      "        location /health {",
      "            return 200 'OK from Public Instance ${count.index + 1}';",
      "            add_header Content-Type text/plain;",
      "        }",
      "    }",
      "}",
      "EOF",
      "sudo nginx -t",
      "sudo systemctl enable nginx",
      "sudo systemctl start nginx",
      "sudo systemctl status nginx",
      "echo 'Nginx reverse proxy configured successfully on instance ${count.index + 1}'"
    ]
  }
}
# Save all IPs to all-ips.txt using local-exec
resource "null_resource" "write_ips" {
  triggers = {
    proxy_ips   = join(",", module.ec2_proxy.public_ips)
    backend_ips = join(",", module.ec2_backend.private_ips)
  }

  provisioner "local-exec" {
    command = <<EOT
cat > all-ips.txt <<EOF
public-ip1 ${module.ec2_proxy.public_ips[0]}
public-ip2 ${element(module.ec2_proxy.public_ips, 1)}
private-ip1 ${module.ec2_backend.private_ips[0]}
private-ip2 ${element(module.ec2_backend.private_ips, 1)}
EOF
EOT
  }
  /*provisioner "local-exec" {
    command = "echo ${var.instance_name}-ip${count.index + 1} ${self.public_ip != "" ? self.public_ip : self.private_ip} >> all-ips2.txt"
  }*/
}

