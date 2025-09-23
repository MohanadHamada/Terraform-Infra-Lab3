#!/bin/bash
sudo yum update -y || sudo apt update -y",
sudo yum install -y nginx || sudo apt install -y nginx",
sudo systemctl enable nginx",
sudo systemctl start nginx",
echo 'Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)'",
if curl -s http://169.254.169.254/latest/meta-data/public-ipv4 >/dev/null 2>&1; then echo 'Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)'; fi"