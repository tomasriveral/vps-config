#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."


systemctl status kdrive-rclone | (echo "Exiting kDrive is not running..." & exit 1)
docker compose pull
docker compose up -d
docker compose run archivebox server
