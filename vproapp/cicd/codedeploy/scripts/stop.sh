#!/bin/bash
set -e
cd /opt/vprofile-deploy || exit 0

if docker compose version >/dev/null 2>&1; then
  docker compose down || true
elif command -v docker-compose >/dev/null 2>&1; then
  docker-compose down || true
else
  docker rm -f vprofile-app || true
fi
