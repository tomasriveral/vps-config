#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/home/tomasr/vps-config"
ENV_FILE="$REPO_DIR/.env"

ICLOUDPD="/home/tomasr/.venvs/icloudpd/bin/icloudpd"
COOKIE_DIR="/home/tomasr/.icloudpd"
BACKUP_DIR="/mnt/kdrive/Photo/IPhone/icloudpd-backup"

# Load environment
if [[ ! -f "$ENV_FILE" ]]; then
    echo "ERROR: $ENV_FILE does not exist."
    exit 1
fi

# shellcheck disable=SC1090
source "$ENV_FILE"

if [[ -z "${ICLOUD_EMAIL:-}" ]]; then
    echo "ERROR: ICLOUD_EMAIL is not configured."
    exit 1
fi

if [[ -z "${ICLOUD_PASSWORD:-}" ]]; then
    echo "ERROR: ICLOUD_PASSWORD is not configured."
    exit 1
fi

if [[ -z "${NTFY_URL:-}" ]]; then
    echo "ERROR: NTFY_URL is not configured."
    exit 1
fi

if [[ -z "${NTFY_TOPIC:-}" ]]; then
    echo "ERROR: NTFY_TOPIC is not configured."
    exit 1
fi

if [[ -z "${NTFY_TOKEN:-}" ]]; then
    echo "ERROR: NTFY_TOKEN is not configured."
    exit 1
fi

mkdir -p "$BACKUP_DIR"

# Check whether the existing iCloud authentication is still valid.
if ! "$ICLOUDPD" \
    --auth-only \
    --username "$ICLOUD_EMAIL" \
    --password "$ICLOUD_PASSWORD" \
    --cookie-directory "$COOKIE_DIR" \
    --dry-run
then
    echo "ERROR: iCloud authentication has expired or is not available."

    curl \
        --fail \
        --silent \
        --show-error \
        -H "Authorization: Bearer $NTFY_TOKEN" \
        -H "Title: iCloud authentication required" \
        -H "Priority: high" \
        -d "icloudpd on the VPS is no longer authenticated. Run: sudo -u tomasr /home/tomasr/vps-config/scripts/icloud-auth.sh" \
        "$NTFY_URL/$NTFY_TOPIC"

    exit 1
fi

echo "iCloud authentication is valid."
echo "Starting iCloud backup."

exec "$ICLOUDPD" \
    --directory "$BACKUP_DIR" \
    --username "$ICLOUD_EMAIL" \
    --password "$ICLOUD_PASSWORD" \
    --cookie-directory "$COOKIE_DIR" \
    --watch-with-interval 36000 \
    --no-progress-bar
