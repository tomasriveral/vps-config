#!/usr/bin/env bash
set -euo pipefail

echo "== Updating system =="
apt update
apt upgrade -y

echo "== Installing base packages =="
apt install -y \
  ca-certificates \
  curl \
  gnupg \
  git \
  vim \
  htop \
  unzip \
  rsync \
  rclone \
  jq \
  fail2ban \
  unattended-upgrades \
  ripgrep \
  ufw

echo "== Installing Docker repository key =="
install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg \
  -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

echo "== Adding Docker repository =="
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
  https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" \
  > /etc/apt/sources.list.d/docker.list

apt update

echo "== Installing Docker =="
apt install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

systemctl enable docker
systemctl start docker

echo "== Configuring firewall =="
ufw default deny incoming
ufw default allow outgoing

# SSH
ufw allow 22/tcp

# Web
ufw allow 80/tcp
ufw allow 443/tcp

ufw --force enable

echo "== Enabling useful services =="
systemctl enable --now ssh
systemctl enable --now fail2ban
dpkg-reconfigure unattended-upgrades

echo "== installing systemd systems"
mkdir -p /opt/server/archivebox/archivebox-data
mkdir -p /mnt/kdrive/
rclone config

cp systemd/kdrive-rclone.service /etc/systemd/system/

systemctl daemon-reload
systemctl enable kdrive-rclone
systemctl start kdrive-rclone
mountpoint /mnt/kdrive
ls /mnt/kdrive
echo
echo "================================"
echo "Bootstrap finished!"
echo
docker --version
docker compose version
echo "================================"
