#!/usr/bin/env bash
set -euo pipefail

PREFIX="${TINYPM_PREFIX:-$HOME/.tinypm}"
LOCAL_BIN="$HOME/.local/bin"
DESKTOP_FILE="$HOME/.local/share/applications/tinypm.desktop"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tinypm"
STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/tinypm"

echo "[TinyPM] Removing runtime from $PREFIX ..."
rm -rf "$PREFIX"
for cmd in tinypm tiny ainstall search term start supdate tinypm-app seed syspm version _spinner; do
    rm -f "$LOCAL_BIN/$cmd"
done
rm -f "$DESKTOP_FILE"
rm -rf "$CONFIG_DIR"
rm -rf "$STATE_DIR"
echo "[TinyPM] Uninstallation complete!"
