#!/usr/bin/env bash
set -e

docker compose pull
docker compose up -d
docker compose run archivebox server
