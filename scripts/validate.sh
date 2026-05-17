#!/bin/bash
sleep 15

# Collect debug info and upload to S3 so we can read it
debug_file="/tmp/validate_debug.txt"
{
  echo "=== date ==="
  date
  echo "=== gunicorn status ==="
  systemctl status gunicorn --no-pager 2>&1 || true
  echo "=== gunicorn journal ==="
  journalctl -u gunicorn --no-pager -n 30 2>&1 || true
  echo "=== nginx status ==="
  systemctl status nginx --no-pager 2>&1 || true
  echo "=== /etc/sysconfig/gunicorn ==="
  cat /etc/sysconfig/gunicorn 2>&1 || echo "MISSING"
  echo "=== curl / ==="
  curl -sv http://localhost/ 2>&1 || true
} > "$debug_file" 2>&1

aws s3 cp "$debug_file" s3://aws-challenge-905813140854/debug/validate_debug.txt \
  --region eu-central-1 2>/dev/null || true

# Validate
curl -sf http://localhost/ | grep -q "AWS Challenge" || exit 1
