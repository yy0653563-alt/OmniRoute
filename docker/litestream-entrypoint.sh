#!/bin/sh
# OmniRoute entrypoint with Litestream backup.
# On boot: restore the SQLite database from Backblaze B2 if the local file
# is missing (Render free instances wipe local files on every restart),
# then run the app under `litestream replicate` so every change streams
# to B2 continuously. If no bucket is configured, run the app as usual.
set -e

# Render's Docker deploy passes no command when the Docker Command field
# is left empty, so default to the app's start command.
if [ "$#" -eq 0 ]; then
  set -- node dev/run-standalone.mjs
fi

DB_PATH="${DATA_DIR:-/app/data}/storage.sqlite"

if [ -n "$LITESTREAM_BUCKET" ]; then
  if [ ! -f "$DB_PATH" ]; then
    echo "[litestream] No local database found, restoring from backup..."
    litestream restore -if-replica-exists -config /etc/litestream.yml "$DB_PATH" || true
  fi
  echo "[litestream] Starting app with continuous backup..."
  exec /app/check-permissions.sh litestream replicate -config /etc/litestream.yml --exec "$*"
else
  exec /app/check-permissions.sh "$@"
fi
