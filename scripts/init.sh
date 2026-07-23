#!/usr/bin/env bash
set -e

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

echo "== initializing archivebox"
docker compose run --rm archivebox init --setup
