#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

docker compose pull
docker compose up -d
docker image prune -f
