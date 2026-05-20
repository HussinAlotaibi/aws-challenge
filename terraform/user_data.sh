#!/bin/bash
set -e

REGION="${region}"
SECRET_NAME="${secret_name}"
RDS_ENDPOINT="${rds_endpoint}"
S3_BUCKET="${s3_bucket}"
PROJECT_NAME="${project_name}"

# System update and dependencies
dnf update -y
dnf install -y python3 python3-pip nginx ruby wget git

# CodeDeploy agent
cd /tmp
wget -q https://aws-codedeploy-$REGION.s3.$REGION.amazonaws.com/latest/install
chmod +x ./install
./install auto
systemctl enable codedeploy-agent
systemctl start codedeploy-agent

# SSM agent (pre-installed on AL2023, just needs to be enabled)
systemctl enable amazon-ssm-agent
systemctl start amazon-ssm-agent

# Python packages
pip3 install django gunicorn PyMySQL boto3 django-storages

# App directory
mkdir -p /opt/app
chown ec2-user:ec2-user /opt/app

# Environment variables for the app
cat > /etc/profile.d/app.sh << EOF
export AWS_REGION="$REGION"
export SECRET_NAME="$SECRET_NAME"
export RDS_ENDPOINT="$RDS_ENDPOINT"
export S3_BUCKET="$S3_BUCKET"
EOF

# Nginx config
cat > /etc/nginx/conf.d/app.conf << 'NGINX'
server {
    listen 80;
    server_name _;

    location /health/ {
        proxy_pass http://127.0.0.1:8000;
    }

    location /static/ {
        alias /opt/app/staticfiles/;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $http_x_forwarded_proto;
    }
}
NGINX

rm -f /etc/nginx/conf.d/default.conf
systemctl enable nginx
systemctl start nginx
