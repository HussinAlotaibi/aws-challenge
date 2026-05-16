#!/bin/bash
set -e
cd /opt/app

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
