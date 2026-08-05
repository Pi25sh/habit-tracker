#!/usr/bin/env bash
# Restore a backup created by backup.sh.
# Usage: ./scripts/restore.sh backups/backup-YYYYmmdd-HHMMSS.tar.gz
set -euo pipefail

ARCHIVE="${1:?usage: restore.sh <backup.tar.gz>}"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

tar xzf "$ARCHIVE" -C "$WORK"
DUMP="$(find "$WORK" -name 'db-*.dump' | head -1)"
MINIO_DIR="$(find "$WORK" -maxdepth 1 -type d -name 'minio-*' | head -1)"

echo "!! This will OVERWRITE the current database and photo bucket."
read -r -p "Type 'restore' to continue: " CONFIRM
[ "$CONFIRM" = "restore" ] || { echo "aborted"; exit 1; }

echo "==> Restoring PostgreSQL..."
docker compose exec -T postgres pg_restore -U "${POSTGRES_USER:-habit}" -d "${POSTGRES_DB:-habitdb}" \
  --clean --if-exists < "$DUMP"

if [ -n "$MINIO_DIR" ]; then
  echo "==> Restoring MinIO bucket..."
  docker compose run --rm --entrypoint sh -v "$MINIO_DIR:/restore:ro" minio -c "
    mc alias set local http://minio:9000 \$MINIO_ROOT_USER \$MINIO_ROOT_PASSWORD &&
    mc mirror --overwrite /restore local/habit-photos"
fi

echo "==> Restore complete."
