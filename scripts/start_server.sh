#!/bin/bash
set -e
cd /opt/app

# Write systemd-compatible env file (no 'export' keyword — EnvironmentFile requires plain KEY=VALUE)
cat > /etc/sysconfig/gunicorn << ENVEOF
AWS_REGION=eu-central-1
SECRET_NAME=aws-challenge/rds-credentials
S3_BUCKET=aws-challenge-905813140854
ENVEOF

# Also keep app.sh for bash scripts that source it
if [ ! -f /etc/profile.d/app.sh ]; then
  cat > /etc/profile.d/app.sh << ENVEOF2
export AWS_REGION="eu-central-1"
export SECRET_NAME="aws-challenge/rds-credentials"
export S3_BUCKET="aws-challenge-905813140854"
ENVEOF2
fi

# Ensure nginx is installed and running
dnf install -y nginx 2>/dev/null || true
systemctl enable nginx
systemctl start nginx 2>/dev/null || true

cat > /etc/systemd/system/gunicorn.service << EOF
[Unit]
Description=Gunicorn Django App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/opt/app
EnvironmentFile=/etc/sysconfig/gunicorn
ExecStart=/usr/local/bin/gunicorn config.wsgi:application --bind 127.0.0.1:8000 --workers 2
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gunicorn
systemctl reset-failed gunicorn 2>/dev/null || true
systemctl start gunicorn

# Wait up to 10s for gunicorn to come up
for i in 1 2 3 4 5; do
  sleep 2
  systemctl is-active gunicorn > /dev/null 2>&1 && break
done

# Replace nginx.conf with minimal config (removes built-in default server block
# that conflicts with our app.conf on Amazon Linux 2023)
cat > /etc/nginx/nginx.conf << 'NGINXMAIN'
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;
    sendfile      on;
    keepalive_timeout 65;
    include /etc/nginx/conf.d/*.conf;
}
NGINXMAIN

# Write nginx proxy config
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
systemctl restart nginx
