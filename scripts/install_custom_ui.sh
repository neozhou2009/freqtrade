#!/usr/bin/env bash
set -euo pipefail

# Simple helper to install the local 'trading_dashboard' as the UI served by freqtrade's API.
# Usage:
#   ./scripts/install_custom_ui.sh [--erase] [--skip-restart]
#   --erase: delete the installed UI contents before copying
#   --skip-restart: don't attempt to restart the current running process (which may require permissions)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="${SCRIPT_DIR%/scripts}"
SOURCE_DIR="${REPO_ROOT}/trading_dashboard"
TARGET_DIR="${REPO_ROOT}/freqtrade/rpc/api_server/ui/installed"

# Parse args
ERASE="false"
SKIP_RESTART="false"

for arg in "$@"; do
  case "$arg" in
    --erase) ERASE="true" ;;
    --skip-restart) SKIP_RESTART="true" ;;
    *) echo "Unknown arg: $arg"; exit 1 ;;
  esac
done

if [ ! -d "$SOURCE_DIR" ]; then
  echo "Source directory not found: $SOURCE_DIR"
  exit 1
fi

# Ensure target exists
mkdir -p "$TARGET_DIR"

if [ "$ERASE" = "true" ]; then
  echo "Erasing $TARGET_DIR/ contents except .uiversion and fallback_file.html"
  shopt -s dotglob
  for f in "$TARGET_DIR"/*; do
    basename=$(basename "$f")
    if [[ "$basename" = ".uiversion" || "$basename" = "fallback_file.html" || "$basename" = "favicon.ico" ]]; then
      continue
    fi
    rm -rf "$f"
  done
  shopt -u dotglob
fi

# Copy dashboard contents into the UI installed directory
echo "Copying $SOURCE_DIR --> $TARGET_DIR/trading_dashboard"
rm -rf "$TARGET_DIR/trading_dashboard"
mkdir -p "$TARGET_DIR/trading_dashboard"
cp -r "$SOURCE_DIR/"* "$TARGET_DIR/trading_dashboard/"

# warn if copying fail
if [ $? -eq 0 ]; then
  echo "Custom UI installed to $TARGET_DIR/trading_dashboard"
else
  echo "Copy failed" >&2
  exit 1
fi

# Optionally restart the running API server is outside this script's scope.
# If you are running the bot locally like 'freqtrade trade', just stop and restart the process.
if [ "$SKIP_RESTART" = "false" ]; then
  echo "If you want the API to serve the new UI, restart the bot or the API server process."
fi

exit 0
