#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/home/tomasr/vps-config"
ENV_FILE="$REPO_DIR/.env"

ICLOUDPD="/home/tomasr/.venvs/icloudpd/bin/icloudpd"
COOKIE_DIR="/home/tomasr/.icloudpd"

if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: $ENV_FILE does not exist."
    exit 1
fi

get_env_value() {
    local key="$1"

    sed -n "s/^${key}=//p" "$ENV_FILE" | head -n 1
}

ICLOUD_EMAIL="$(get_env_value ICLOUD_EMAIL)"
ICLOUD_PASSWORD="$(get_env_value ICLOUD_PASSWORD)"

if [[ -z "$ICLOUD_EMAIL" ]]; then
    echo "ERROR: ICLOUD_EMAIL is not configured."
    exit 1
fi

if [[ -z "$ICLOUD_PASSWORD" ]]; then
    echo "ERROR: ICLOUD_PASSWORD is not configured."
    exit 1
fi

mkdir -p "$COOKIE_DIR"
chmod 700 "$COOKIE_DIR"

echo "Authenticating icloudpd as $ICLOUD_EMAIL"
echo

"$ICLOUDPD" \
    --auth-only \
    --username "$ICLOUD_EMAIL" \
    --password "$ICLOUD_PASSWORD" \
    --cookie-directory "$COOKIE_DIR"

echo
echo "iCloud authentication completed."
