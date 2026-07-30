#!/usr/bin/env bash
set -e

apt update -y
apt upgrade -y

cd /home/tomasr/vps-config

docker compose down
docker compose pull
docker compose up -d
docker image prune -f
