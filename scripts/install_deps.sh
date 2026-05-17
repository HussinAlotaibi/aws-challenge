#!/bin/bash
set -e
cd /opt/app
dnf install -y python3-devel mysql-devel gcc pkg-config
pip3 install -r requirements.txt
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput
