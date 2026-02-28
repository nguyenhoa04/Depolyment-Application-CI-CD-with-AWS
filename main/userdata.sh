#!/bin/bash
set -euxo pipefail

dnf update -y

# Docker
dnf install -y docker
systemctl enable docker
systemctl start docker
usermod -aG docker ec2-user || true

# Docker compose plugin
if ! command -v curl >/dev/null 2>&1; then
  dnf install -y curl-minimal || dnf install -y curl --allowerasing
fi
if ! docker compose version >/dev/null 2>&1; then
  mkdir -p /usr/local/lib/docker/cli-plugins
  curl -fsSL --retry 5 --retry-delay 2 \
    https://github.com/docker/compose/releases/download/v2.27.2/docker-compose-linux-x86_64 \
    -o /usr/local/lib/docker/cli-plugins/docker-compose || true
  chmod +x /usr/local/lib/docker/cli-plugins/docker-compose || true
fi

# CodeDeploy agent
dnf install -y ruby wget
cd /tmp
wget --tries=5 --waitretry=3 \
  https://aws-codedeploy-ap-southeast-2.s3.ap-southeast-2.amazonaws.com/latest/install
chmod +x ./install
./install auto

# AL2023 installs CodeDeploy agent as init script; create a native systemd unit.
cat >/etc/systemd/system/codedeploy-agent.service <<'UNIT'
[Unit]
Description=AWS CodeDeploy Agent
After=network.target

[Service]
Type=forking
ExecStart=/etc/init.d/codedeploy-agent start
ExecStop=/etc/init.d/codedeploy-agent stop
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable codedeploy-agent
systemctl restart codedeploy-agent
