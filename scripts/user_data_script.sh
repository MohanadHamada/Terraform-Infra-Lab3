#!/bin/bash
sudo amazon-linux-extras enable nginx1
sudo yum install -y nginx
sudo systemctl enable --now nginx


sudo systemctl enable nginx
sudo systemctl start nginx

PUB_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 || true)
PRIV_IP=$(curl -s http://169.254.169.254/latest/meta-data/local-ipv4)

if [[ "$PUB_IP" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    IP=$PUB_IP
else
    IP=$PRIV_IP
fi

sudo tee /usr/share/nginx/html/index.html > /dev/null <<EOF
Hello from Backend
IP: $IP
EOF

sudo systemctl restart nginx
