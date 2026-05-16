#!/bin/bash
set -e
cd /opt/app
pip3 install -r requirements.txt
python3 manage.py migrate --noinput
python3 manage.py collectstatic --noinput
