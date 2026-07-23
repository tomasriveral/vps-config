#!/usr/bin/env bash
set -euo pipefail

################################################################################
# Configuration
################################################################################

REPO="https://github.com/tomasriveral/vps-config"
REPO_DIR="vps-config"

################################################################################
# Helpers
################################################################################

step() {
    echo
    echo "=============================================================================="
    echo "$1"
    echo "=============================================================================="
}

################################################################################
# System update
################################################################################

step "Updating system"

apt update
apt upgrade -y

################################################################################
# Base packages
################################################################################

step "Installing base packages"

apt install -y \
    ca-certificates \
    curl \
    git \
    gnupg \
    htop \
    jq \
    fail2ban \
    ripgrep \
    rclone \
    rsync \
    ufw \
    unattended-upgrades \
    unzip \
    vim

################################################################################
# Docker
################################################################################

step "Installing Docker repository"

install -d -m 0755 /etc/apt/keyrings

curl -fsSL \
    https://download.docker.com/linux/debian/gpg \
    -o /etc/apt/keyrings/docker.asc

chmod a+r /etc/apt/keyrings/docker.asc

. /etc/os-release

cat >/etc/apt/sources.list.d/docker.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/$ID \
$VERSION_CODENAME stable
EOF

apt update

step "Installing Docker"

apt install -y \
    containerd.io \
    docker-buildx-plugin \
    docker-ce \
    docker-ce-cli \
    docker-compose-plugin

systemctl enable --now docker

################################################################################
# User
################################################################################

step "Creating administrator"

read -rp "Username: " USERNAME

adduser "$USERNAME"

usermod -aG sudo,docker "$USERNAME"

mkdir -p "/home/$USERNAME/.ssh"

cp /root/.ssh/authorized_keys \
   "/home/$USERNAME/.ssh/authorized_keys"

chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"

chmod 700 "/home/$USERNAME/.ssh"
chmod 600 "/home/$USERNAME/.ssh/authorized_keys"

################################################################################
# Repository
################################################################################

step "Cloning configuration repository"

if [ ! -d "$REPO_DIR" ]; then
    git clone "$REPO" /home/$USERNAME/$REPO_DIR
fi
cd "/HOME/$USERNAME/$REPO_DIR"
chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/"

################################################################################
# Security
################################################################################

step "Configuring firewall"

ufw default deny incoming
ufw default allow outgoing

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp

ufw --force enable

step "Enabling services"

systemctl enable --now ssh
systemctl enable --now fail2ban

dpkg-reconfigure unattended-upgrades

################################################################################
# Storage
################################################################################

step "Preparing storage"

mkdir -p \
    /mnt/kdrive \
    /opt/server/archivebox/archivebox-data

echo
echo "Configure rclone now."
rclone config

cp systemd/kdrive-rclone.service \
   /etc/systemd/system/

systemctl daemon-reload
systemctl enable --now kdrive-rclone

sleep 1
echo "Mounting kdrive"
sleep 1
echo "."
sleep 1
echo ".."
sleep 1
echo "..."
sleep 1
mountpoint /mnt/kdrive
ls /mnt/kdrive

################################################################################
# ArchiveBox
################################################################################

step "Initializing ArchiveBox"

docker compose run --rm archivebox init --setup

################################################################################
# Done
################################################################################

step "Bootstrap completed"

docker --version
docker compose version

echo
echo "You can now login as:"
echo
echo "    ssh $USERNAME@<server>"
echo
echo "Deploy by running the deploy.sh script"
