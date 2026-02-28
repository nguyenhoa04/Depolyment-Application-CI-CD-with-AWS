#!/bin/bash
set -euxo pipefail

get_region() {
  if [ -n "${AWS_REGION:-}" ]; then
    echo "$AWS_REGION"
    return
  fi

  local token
  token=$(curl -fsS -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600" || true)

  local region
  if [ -n "$token" ]; then
    region=$(curl -fsS -H "X-aws-ec2-metadata-token: $token" \
      http://169.254.169.254/latest/dynamic/instance-identity/document \
      | sed -n 's/.*"region"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
  fi

  if [ -z "${region:-}" ]; then
    region=$(curl -fsS http://169.254.169.254/latest/meta-data/placement/region || true)
  fi

  if [ -z "${region:-}" ]; then
    region="ap-southeast-2"
  fi

  echo "$region"
}

ensure_compose() {
  if docker compose version >/dev/null 2>&1; then
    return
  fi

  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL --retry 5 --retry-delay 2 \
    https://github.com/docker/compose/releases/download/v2.27.2/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

  docker compose version >/dev/null 2>&1
}

REGION=$(get_region)
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ECR_REPO_NAME="vprofile-devops-dev-vprofile"
ECR_URL="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$ECR_REPO_NAME"

aws ecr get-login-password --region "$REGION" | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

ensure_compose

cd /opt/vprofile-deploy

cat > .env <<ENVEOF
ECR_IMAGE=$ECR_URL:latest
ENVEOF

docker compose pull
docker compose up -d
