#!/bin/bash
set -e

# Wait for user_data to finish creating env file (up to 5 mins)
for i in {1..30}; do
  [ -f /etc/profile.d/app.sh ] && break
  echo "Waiting for app.sh... attempt $i"
  sleep 10
done
source /etc/profile.d/app.sh

cd /opt/app
pip3 install -r requirements.txt
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput
