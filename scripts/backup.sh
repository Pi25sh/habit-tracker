#!/usr/bin/env bash
# Backup PostgreSQL + MinIO data. Run from the project root on the host.
# Usage: ./scripts/backup.sh [output-dir]   (default: ./backups)
set -euo pipefail

OUT="${1:-./backups}"
STAMP="$(date -u +%Y%m%d-%H%M%S)"
mkdir -p "$OUT"

echo "==> Dumping PostgreSQL..."
docker compose exec -T postgres pg_dump -U "${POSTGRES_USER:-habit}" -d "${POSTGRES_DB:-habitdb}" -Fc \
  > "$OUT/db-$STAMP.dump"

echo "==> Mirroring MinIO bucket..."
docker compose run --rm --entrypoint sh -v "$(pwd)/$OUT:/backup" minio -c "
  mc alias set local http://minio:9000 \$MINIO_ROOT_USER \$MINIO_ROOT_PASSWORD &&
  mc mirror local/habit-photos /backup/minio-$STAMP"

echo "==> Compressing..."
tar czf "$OUT/backup-$STAMP.tar.gz" -C "$OUT" "db-$STAMP.dump" "minio-$STAMP"
rm -rf "$OUT/db-$STAMP.dump" "$OUT/minio-$STAMP"

# Keep the 14 newest backups.
ls -1t "$OUT"/backup-*.tar.gz | tail -n +15 | xargs -r rm -f

echo "==> Done: $OUT/backup-$STAMP.tar.gz"
