#!/bin/bash

yum install -y httpd

# Get private IP
IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

echo "Hello from backend IP: $IP" > /var/www/html/index.html

systemctl enable httpd
systemctl start httpd
