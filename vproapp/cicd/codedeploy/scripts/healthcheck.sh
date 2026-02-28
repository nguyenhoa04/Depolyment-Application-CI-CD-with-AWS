#!/bin/bash
set -e
for i in {1..20}; do
  if curl -fsS "http://localhost:8080/" >/dev/null; then
    exit 0
  fi
  sleep 5
done
echo "Healthcheck failed"
exit 1