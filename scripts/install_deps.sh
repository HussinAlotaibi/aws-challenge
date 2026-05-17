#!/bin/bash
set -e

# Wait for cloud-init (user_data) to fully complete
cloud-init status --wait

source /etc/profile.d/app.sh

cd /opt/app
pip3 install -r requirements.txt
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput
