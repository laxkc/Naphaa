#!/usr/bin/env bash
set -euo pipefail

# Apply macOS fork fix only if running on Darwin
if [[ "$(uname)" == "Darwin" ]]; then
  export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES
fi

cd "$(dirname "$0")"

if [[ -x ".venv/bin/gunicorn" ]]; then
  GUNICORN_BIN=".venv/bin/gunicorn"
else
  GUNICORN_BIN="gunicorn"
fi

exec "$GUNICORN_BIN" \
  --bind "0.0.0.0:${PORT:-${APP_PORT:-8080}}" \
  --workers 2 \
  --timeout 120 \
  -k uvicorn.workers.UvicornWorker \
  app.main:app
