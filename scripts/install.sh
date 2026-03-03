#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${TINYPM_PREFIX:-$HOME/.tinypm}"
BIN_DIR="$PREFIX/bin"
LOCAL_BIN="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tinypm"
CONFIG_FILE="$CONFIG_DIR/config"

print_logo() {
    [[ -r "$HERE/share/logo.txt" ]] && { cat "$HERE/share/logo.txt" >&2; printf '\n' >&2; }
}

print_seed_logo() {
    [[ -r "$HERE/share/seed-logo.txt" ]] && { cat "$HERE/share/seed-logo.txt" >&2; printf '\n' >&2; }
}

detect_native_pm() {
    command -v apt-get >/dev/null 2>&1 && { echo apt; return; }
    command -v xbps-install >/dev/null 2>&1 && { echo xbps; return; }
    command -v pacman >/dev/null 2>&1 && { echo pacman; return; }
    command -v dnf >/dev/null 2>&1 && { echo dnf; return; }
    command -v zypper >/dev/null 2>&1 && { echo zypper; return; }
    command -v apk >/dev/null 2>&1 && { echo apk; return; }
    command -v emerge >/dev/null 2>&1 && { echo emerge; return; }
    echo seed
}

choose_native_pm() {
    local detected choice
    detected="$(detect_native_pm)"

    print_logo
    if [[ "$detected" == "seed" ]]; then
        print_seed_logo
        printf "No native package manager was detected. Seed can act as TinyPM's mini package manager.\n\n" >&2
    fi

    printf 'TinyPM Installer\n' >&2
    printf 'Detected native source: %s\n\n' "$detected" >&2
    printf 'Choose your primary native package manager:\n' >&2
    printf '  1. auto (%s)\n' "$detected" >&2
    printf '  2. apt\n' >&2
    printf '  3. xbps\n' >&2
    printf '  4. pacman\n' >&2
    printf '  5. dnf\n' >&2
    printf '  6. zypper\n' >&2
    printf '  7. apk\n' >&2
    printf '  8. emerge\n' >&2
    printf '  9. seed\n' >&2
    printf '\nSelect an option [1-9]: ' >&2
    IFS= read -r choice || choice=1

    case "$choice" in
        1|'') echo "$detected" ;;
        2) echo apt ;;
        3) echo xbps ;;
        4) echo pacman ;;
        5) echo dnf ;;
        6) echo zypper ;;
        7) echo apk ;;
        8) echo emerge ;;
        9) echo seed ;;
        *) echo "$detected" ;;
    esac
}

install_runtime() {
    local cmd

    mkdir -p "$BIN_DIR" "$LOCAL_BIN" "$DESKTOP_DIR" "$CONFIG_DIR"

    cp -R "$HERE/lib" "$BIN_DIR/"
    cp -R "$HERE/share" "$BIN_DIR/"
    cp -R "$HERE/assets" "$BIN_DIR/"
    cp -f "$HERE/_spinner" "$BIN_DIR/_spinner"
    cp -f "$HERE/tinypm" "$BIN_DIR/tinypm"
    cp -f "$HERE/tinypm-app" "$BIN_DIR/tinypm-app"
    cp -f "$HERE/seed" "$BIN_DIR/seed"
    cp -f "$HERE/version" "$BIN_DIR/version"
    cp -f "$HERE/tinypm.desktop" "$BIN_DIR/tinypm.desktop"
    if [[ -f "$HERE/syspm.sh" ]]; then
        cp -f "$HERE/syspm.sh" "$BIN_DIR/syspm"
    fi

    chmod +x "$BIN_DIR/_spinner" "$BIN_DIR/tinypm" "$BIN_DIR/tinypm-app" "$BIN_DIR/seed" "$BIN_DIR/version"
    [[ -f "$BIN_DIR/syspm" ]] && chmod +x "$BIN_DIR/syspm"

    ln -sfn "$BIN_DIR/tinypm" "$BIN_DIR/tiny"
    for cmd in ainstall search term start supdate; do
        ln -sfn "$BIN_DIR/tinypm" "$BIN_DIR/$cmd"
    done

    ln -sfn "$BIN_DIR/tinypm" "$LOCAL_BIN/tinypm"
    ln -sfn "$BIN_DIR/tinypm" "$LOCAL_BIN/tiny"
    for cmd in ainstall search term start supdate; do
        ln -sfn "$BIN_DIR/tinypm" "$LOCAL_BIN/$cmd"
    done
    ln -sfn "$BIN_DIR/tinypm-app" "$LOCAL_BIN/tinypm-app"
    ln -sfn "$BIN_DIR/seed" "$LOCAL_BIN/seed"
    [[ -f "$BIN_DIR/syspm" ]] && ln -sfn "$BIN_DIR/syspm" "$LOCAL_BIN/syspm"
    ln -sfn "$BIN_DIR/version" "$LOCAL_BIN/version"
    ln -sfn "$BIN_DIR/_spinner" "$LOCAL_BIN/_spinner"
    rm -f "$LOCAL_BIN/atiny"

    sed "s#^Exec=.*#Exec=tinypm-app#" "$HERE/tinypm.desktop" >"$DESKTOP_DIR/tinypm.desktop"
}

write_config() {
    printf 'native_pm=%s\n' "$1" > "$CONFIG_FILE"
}

ensure_local_bin_on_path() {
    local shell_rc="$HOME/.bashrc"
    [[ -n "${ZSH_VERSION:-}" ]] && shell_rc="$HOME/.zshrc"

    if ! grep -q 'HOME/.local/bin' "$shell_rc" 2>/dev/null; then
        printf '\n# TinyPM\nexport PATH="$HOME/.local/bin:$PATH"\n' >>"$shell_rc"
    fi
}

main() {
    local selected_pm
    selected_pm="$(choose_native_pm)"
    install_runtime
    write_config "$selected_pm"
    ensure_local_bin_on_path

    [[ "$selected_pm" == "seed" ]] && print_seed_logo

    printf '\nTinyPM installed to %s\n' "$BIN_DIR"
    printf 'Primary native source: %s\n' "$selected_pm"
    printf 'Commands linked into %s\n' "$LOCAL_BIN"
    printf '\nOpen a new terminal or run:\n'
    printf '  export PATH="$HOME/.local/bin:$PATH"\n'
    printf '\nThen test:\n'
    printf '  tinypm help\n'
    printf '  tiny --version\n'
    printf '  syspm update\n'
    printf '  seed store\n'
    printf '  tinypm doctor\n'
}

main "$@"
