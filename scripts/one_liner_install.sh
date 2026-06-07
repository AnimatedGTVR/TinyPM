#!/usr/bin/env bash
set -euo pipefail

PREFIX="${TINYPM_PREFIX:-$HOME/.tinypm}"
REPO_DIR="$PREFIX/repo"

if ! command -v git >/dev/null 2>&1; then
    echo 'TinyPM installer requires git.' >&2
    exit 1
fi

mkdir -p "$PREFIX"

if [[ -d "$REPO_DIR/.git" ]]; then
    # Force-sync to upstream main. A plain `pull --rebase || true` silently keeps
    # stale code on divergence, which leaves new launchers (grab-de, grab-add-repo)
    # missing even after re-running the installer.
    git -C "$REPO_DIR" fetch origin main
    git -C "$REPO_DIR" reset --hard origin/main
else
    git clone https://github.com/AnimatedGTVR/TinyPM.git "$REPO_DIR"
fi

exec "$REPO_DIR/install.sh"
