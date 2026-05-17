#!/bin/bash
set -e
cd /opt/app

# Ensure app.sh exists for gunicorn EnvironmentFile
if [ ! -f /etc/profile.d/app.sh ]; then
  cat > /etc/profile.d/app.sh << ENVEOF
export AWS_REGION="eu-central-1"
export SECRET_NAME="aws-challenge/rds-credentials"
export S3_BUCKET="aws-challenge-905813140854"
ENVEOF
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
EnvironmentFile=/etc/profile.d/app.sh
ExecStart=/usr/local/bin/gunicorn config.wsgi:application --bind 127.0.0.1:8000 --workers 2
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gunicorn
systemctl start gunicorn

# Write nginx proxy config (in case user_data failed to do it)
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
