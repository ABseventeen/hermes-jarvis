#!/usr/bin/env bash
set -e

# Defaults if not provided
export HERMES_WEBUI_HOST="${HERMES_WEBUI_HOST:-0.0.0.0}"
export HERMES_WEBUI_PORT="${HERMES_WEBUI_PORT:-8787}"
export HERMES_WEBUI_STATE_DIR="${HERMES_WEBUI_STATE_DIR:-/home/hermeswebui/.hermes/webui}"
export HERMES_WEBUI_DEFAULT_WORKSPACE="${HERMES_WEBUI_DEFAULT_WORKSPACE:-/workspace}"

# Map Railway's PORT to Hermes port
export PORT="${PORT:-$HERMES_WEBUI_PORT}"
export HERMES_WEBUI_PORT="$PORT"

mkdir -p "$HERMES_WEBUI_STATE_DIR" "$HERMES_WEBUI_DEFAULT_WORKSPACE"

cd /apptoo

# Create venv if needed
if [ ! -d venv ]; then
  uv venv venv
fi

# Activate venv
source venv/bin/activate

# Install deps (simple but can be optimized later)
uv pip install -r requirements.txt --trusted-host pypi.org --trusted-host files.pythonhosted.org

echo "Starting Hermes WebUI on ${HERMES_WEBUI_HOST}:${HERMES_WEBUI_PORT}"
exec python server.py
