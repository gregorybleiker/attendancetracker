#!/usr/bin/env sh
# Start the published image locally with Podman. See docs/deployment.md.
set -eu

cd -P -- "$(dirname -- "$0")"

# Pick up SECRET_KEY_BASE, PHX_HOST, etc. without committing secrets here.
if [ -f .env ]; then
  set -a
  . ./.env
  set +a
fi

: "${SECRET_KEY_BASE:?set SECRET_KEY_BASE in the environment or .env}"

IMAGE="${IMAGE:-ghcr.io/gregorybleiker/attendancetracker:latest}"
HOST_PORT="${HOST_PORT:-4001}"
DATA_DIR="${DATA_DIR:-./data}"

if [ ! -d "$DATA_DIR" ]; then
  mkdir -p "$DATA_DIR"
  # The container runs as `nobody` (UID 65534); map that into the rootless
  # user namespace so it can write the SQLite database.
  podman unshare chown 65534:65534 "$DATA_DIR"
fi

exec podman run --rm \
  -v "${DATA_DIR}:/data" \
  -e DATABASE_PATH=/data/at.db \
  -e PHX_SERVER=true \
  -e PORT=4000 \
  -e SECRET_KEY_BASE \
  -e PHX_HOST="${PHX_HOST:-localhost}" \
  -p "${HOST_PORT}:4000" \
  "$IMAGE" \
  sh -c "/app/bin/migrate && /app/bin/server"
