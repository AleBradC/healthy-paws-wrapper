#!/usr/bin/env bash
#
# Nightly Postgres backup -> S3.
#
# This script runs on the EC2 host (NOT inside a container) and shells into
# the `db` service via `docker compose exec` to take a logical dump. The
# resulting file is gzipped, named with a UTC timestamp, and copied to S3
# with server-side encryption. Local copies older than KEEP_LOCAL_DAYS are
# pruned so we don't fill the EC2 root volume.
#
# Usage:
#   sudo crontab -e
#   0 3 * * * /home/ec2-user/healthy-paws-wrapper/scripts/backup.sh >> /var/log/healthy-paws-backup.log 2>&1
#
# Required env (export in /etc/profile.d/healthy-paws.sh or the cron entry):
#   AWS_REGION       e.g. eu-central-1
#   S3_BUCKET        bucket name, no s3:// prefix
#   S3_PREFIX        optional prefix, no trailing slash (defaults to "backups/postgres")
#   COMPOSE_DIR      absolute path to the wrapper dir holding docker-compose.yml
#   DB_USER/DB_DATABASE  must match the .env used by docker compose
#
# Permissions:
#   The EC2 instance role needs s3:PutObject on the bucket+prefix. No keys
#   on disk — IAM role only.

set -euo pipefail

: "${AWS_REGION:?AWS_REGION is required}"
: "${S3_BUCKET:?S3_BUCKET is required}"
: "${COMPOSE_DIR:?COMPOSE_DIR is required}"
: "${DB_USER:?DB_USER is required}"
: "${DB_DATABASE:?DB_DATABASE is required}"

S3_PREFIX="${S3_PREFIX:-backups/postgres}"
KEEP_LOCAL_DAYS="${KEEP_LOCAL_DAYS:-3}"
LOCAL_DIR="${LOCAL_DIR:-/var/backups/healthy-paws}"

mkdir -p "${LOCAL_DIR}"

TIMESTAMP="$(date -u +%Y-%m-%dT%H-%M-%SZ)"
FILENAME="healthy-paws_${TIMESTAMP}.sql.gz"
LOCAL_PATH="${LOCAL_DIR}/${FILENAME}"
S3_KEY="${S3_PREFIX}/${FILENAME}"

echo "[$(date -u --iso-8601=seconds)] backup start -> ${S3_KEY}"

# `pg_dump --clean --if-exists` makes restore reproducible: dropping objects
# before recreating them so a re-run on a non-empty DB doesn't error out.
# We pipe through gzip on the host to keep the container image lean.
docker compose -f "${COMPOSE_DIR}/docker-compose.yml" exec -T db \
  pg_dump --clean --if-exists --no-owner --no-privileges \
          -U "${DB_USER}" -d "${DB_DATABASE}" \
  | gzip -9 > "${LOCAL_PATH}"

# Sanity check: a healthy gzipped dump of an even tiny DB is several KB.
# Anything under 1 KB almost certainly means pg_dump failed and we piped an
# empty stream into gzip.
SIZE=$(stat -c '%s' "${LOCAL_PATH}")
if [[ "${SIZE}" -lt 1024 ]]; then
  echo "ERROR: backup file is suspiciously small (${SIZE} bytes). Aborting." >&2
  rm -f "${LOCAL_PATH}"
  exit 1
fi

# SSE-AES256 is sufficient for backups; SSE-KMS adds cost and complexity that
# only matters if you also need per-restore audit trails.
aws s3 cp "${LOCAL_PATH}" "s3://${S3_BUCKET}/${S3_KEY}" \
  --region "${AWS_REGION}" \
  --sse AES256 \
  --no-progress

# Local retention. S3 lifecycle policy on the bucket handles long-term
# retention (suggest: 30 days standard, then expire).
find "${LOCAL_DIR}" -name "healthy-paws_*.sql.gz" -mtime "+${KEEP_LOCAL_DAYS}" -delete

echo "[$(date -u --iso-8601=seconds)] backup complete (${SIZE} bytes) -> s3://${S3_BUCKET}/${S3_KEY}"
