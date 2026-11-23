#!/bin/sh
# DIAGNOSTIC version: prints markers so the Render log shows exactly
# how far startup gets, and reports the app's exit code instead of
# exec-ing away silently. Revert to the exec version once diagnosed.
set -e

echo "[entrypoint] starting, args: $*"
echo "[entrypoint] LITESTREAM_BUCKET set: ${LITESTREAM_BUCKET:+yes}"
echo "[entrypoint] DATA_DIR=$DATA_DIR PORT=$PORT"

DB_PATH="${DATA_DIR:-/app/data}/storage.sqlite"

if [ -n "$LITESTREAM_BUCKET" ]; then
  if [ ! -f "$DB_PATH" ]; then
    echo "[litestream] No local database found, restoring from backup..."
    litestream restore -if-replica-exists -config /etc/litestream.yml "$DB_PATH" || true
  fi
  echo "[litestream] Starting app with continuous backup..."
  /app/check-permissions.sh litestream replicate -config /etc/litestream.yml --exec "$*"
  echo "[entrypoint] litestream exited with code $?"
else
  echo "[entrypoint] no bucket configured, starting app directly"
  /app/check-permissions.sh "$@"
  echo "[entrypoint] app exited with code $?"
fi
