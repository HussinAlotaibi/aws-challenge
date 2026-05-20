#!/bin/bash
set -e

# Wait for cloud-init, don't fail if it errors
cloud-init status --wait || true

# Install and start SSM agent if not already installed
dnf install -y amazon-ssm-agent 2>/dev/null || true
systemctl enable amazon-ssm-agent 2>/dev/null || true
systemctl start amazon-ssm-agent 2>/dev/null || true

# Load env vars — fall back to deriving them if app.sh missing
if [ -f /etc/profile.d/app.sh ]; then
  source /etc/profile.d/app.sh
else
  export AWS_REGION="eu-central-1"
  export SECRET_NAME="aws-challenge/rds-credentials"
  export S3_BUCKET="aws-challenge-905813140854"
fi

cd /opt/app
pip3 install -r requirements.txt
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput
