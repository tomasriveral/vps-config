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
    hledger-web \
    vim \
    acl

# base setup
echo 'export SYSTEMD_PAGER=cat' >> ~/.bashr
source /home/tomasr/.bashrc

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
cd "/home/$USERNAME/$REPO_DIR"
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
ufw allow from 172.18.0.0/16 to any port 5000

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
    /opt/server/archivebox/archivebox-data \
    /opt/server/freshrss \
    /opt/server/uptime-kuma \
    /opt/server/ntfy \
    /opt/server/flatnotes \
    /opt/server/radicale/config \
    /opt/server/radicale/data \
    /opt/server/metube \
    /opt/server/transmute \
    /opt/server/caddy/data \
    /opt/server/caddy/config \
    /opt/server/resspublica/feed \
    /opt/server/resspublica/images \
    /opt/server/fav-archiver \
    /opt/server/booklogr/api

sudo chown -R tomasr:tomasr /opt/server/resspublica
sudo chmod -R u+rwX /opt/server/resspublica

sudo chown -R tomasr:tomasr /opt/server/fav-archiver
sudo chmod -R u+rwX /opt/server/fav-archiver

sudo setfacl -R -m u:tomasr:rX /opt/server/freshrss/users/tomasr
sudo setfacl -m u:tomasr:rw /opt/server/freshrss/users/tomasr/db.sqlite

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

# backup of things not in kdrive

cp systemd/server-backup.* /etc/systemd/system/
cp systemd/freshrss-fav-archiver.* /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now server-backup.timer
systemctl enable --now update-server.timer
systemctl enable --now freshrss-fav-archiver.timer

###############################################################################
# hledger-web
##############################################################################

step "Initializing hledger-web"
cp systemd/hledger-web.service \
   /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now hledger-web


################################################################################
# ArchiveBox
################################################################################

step "Initializing ArchiveBox"

docker compose run --rm archivebox init --setup
docker compose run archivebox config --set PUBLIC_INDEX=False PUBLIC_SNAPSHOTS=False
docker compose run --rm archivebox config --set SAVE_WGET=True SAVE_READABILITY=True SAVE_SINGLEFILE=True SAVE_PDF=True SAVE_SCREENSHOT=False SAVE_MEDIA=True SAVE_ARCHIVE_DOT_ORG=False SAVE_MERCURY=False
docker compose run --rm archivebox config --set 'YOUTUBEDL_ARGS=["--write-description","--write-info-json","--write-thumbnail","--write-subs","--write-auto-subs","--convert-subs=srt","--no-call-home","--continue","--no-abort-on-error","--ignore-errors","--geo-bypass","--add-metadata","--format=bestvideo[height<=1080]+bestaudio/best[height<=1080]"]'

####################################################################
# Radicalé
##################\\\\\\\\\\\

step "Initializing Radicalé"

echo "Create user: tomasr"
docker run --rm -it \
  -v /opt/server/radicale/data:/data \
  httpd:2.4-alpine \
  htpasswd -B -c /data/users tomasr

######################################################################3
# freshrss-fav-archiver
###########################

step "Initializing freshrss-fav-archiver"

systemctl enable --now freshrss-fav-archiver.timer

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
