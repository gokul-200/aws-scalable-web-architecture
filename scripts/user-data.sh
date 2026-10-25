#!/bin/bash
# EC2 user data for Ubuntu 24.04 (Canonical AMI). Runs once as root on first boot.
# Installs Python, pulls the app from this repo, and runs it as a systemd service on :8000.
# Needs outbound internet from the private subnet (NAT Gateway) for apt and GitHub.
set -euxo pipefail
exec > >(tee /var/log/user-data.log) 2>&1

REPO_RAW="https://raw.githubusercontent.com/gokul-200/aws-scalable-web-architecture/main/app"

apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y python3 curl

id webapp &>/dev/null || useradd --system --home /opt/webapp --shell /usr/sbin/nologin webapp
mkdir -p /opt/webapp
curl -fsSL --retry 5 --retry-delay 5 "$REPO_RAW/server.py"  -o /opt/webapp/server.py
curl -fsSL --retry 5 --retry-delay 5 "$REPO_RAW/index.html" -o /opt/webapp/index.html
chown -R webapp:webapp /opt/webapp

cat > /etc/systemd/system/webapp.service <<'UNIT'
[Unit]
Description=Scalable web demo app
After=network-online.target
Wants=network-online.target

[Service]
User=webapp
ExecStart=/usr/bin/python3 /opt/webapp/server.py
Restart=always
RestartSec=2

[Install]
WantedBy=multi-user.target
UNIT

systemctl daemon-reload
systemctl enable --now webapp
