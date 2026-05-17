#!/bin/bash
sleep 15
curl -sf http://localhost/health/ || exit 1
