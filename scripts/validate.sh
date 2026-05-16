#!/bin/bash
sleep 5
curl -sf http://localhost/health/ || exit 1
