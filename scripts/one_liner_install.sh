#!/usr/bin/env bash
set -euo pipefail

echo "[ATiny] Starting installation..."

ATINY_PREFIX="${ATINY_PREFIX:-$HOME/.atiny}"
BIN_DIR="$ATINY_PREFIX/bin"
LOG_DIR="$ATINY_PREFIX/logs"

mkdir -p "$BIN_DIR" "$LOG_DIR"

# -----------------------
# Ensure Git is installed
# -----------------------
if ! command -v git >/dev/null 2>&1; then
    echo "[ATiny] Git not found. Installing Git..."
    if command -v apt >/dev/null 2>&1; then
        sudo apt update && sudo apt install -y git
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y git
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -Sy --noconfirm git
    else
        echo "[ATiny] Could not detect package manager. Please install Git manually."
        exit 1
    fi
fi

# -----------------------
# Clone or update repo
# -----------------------
REPO_DIR="$ATINY_PREFIX/repo"
if [ -d "$REPO_DIR/.git" ]; then
    echo "[ATiny] Repo exists, updating..."
    cd "$REPO_DIR"
    git pull --rebase origin main || true
else
    git clone https://github.com/AnimatedGTVR/ATiny.git "$REPO_DIR"
    cd "$REPO_DIR"
fi

# -----------------------
# Copy core script
# -----------------------
cp -f src/atiny "$BIN_DIR/atiny"
chmod +x "$BIN_DIR/atiny"

# -----------------------
# Create symlinks
# -----------------------
for c in ainstall finstall sinstall term fterm sterm search fsearch ssearch supdate list run start helptiny mantiny; do
    ln -sf "$BIN_DIR/atiny" "$BIN_DIR/$c"
done

# -----------------------
# Update PATH safely
# -----------------------
SHELL_RC="$HOME/.bashrc"
if [ "${ZSH_VERSION:-}" ]; then SHELL_RC="$HOME/.zshrc"; fi

if ! grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
    echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
    echo "[ATiny] Added $BIN_DIR to PATH in $SHELL_RC."
    echo "[ATiny] Restart terminal or run: source $SHELL_RC"
fi

echo "[ATiny] Installation complete! Test with: atiny --version"
