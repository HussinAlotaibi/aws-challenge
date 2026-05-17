#!/bin/bash
sleep 15
# Check index page (no DB dependency) to confirm nginx+gunicorn are up
curl -sf http://localhost/ | grep -q "AWS Challenge" || exit 1
