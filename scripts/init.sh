#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

mkdir -p archivebox-data

docker compose run --rm archivebox init --setup

docker compose up -d
