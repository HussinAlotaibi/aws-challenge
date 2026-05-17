#!/bin/bash
set -e
cd /opt/app

# Ensure app.sh exists for gunicorn EnvironmentFile
if [ ! -f /etc/profile.d/app.sh ]; then
  REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
  cat > /etc/profile.d/app.sh << ENVEOF
export AWS_REGION="$REGION"
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
systemctl restart nginx
