#!/usr/bin/env bash
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PREFIX="${TINYPM_PREFIX:-$HOME/.tinypm}"
BIN_DIR="$PREFIX/bin"
LOCAL_BIN="$HOME/.local/bin"
DESKTOP_DIR="$HOME/.local/share/applications"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/tinypm"
CONFIG_FILE="$CONFIG_DIR/config"
DEFAULT_FLAVOR="default"

forced_native_pm=""
non_interactive=0
selected_flavor="${TINYPM_FLAVOR:-$DEFAULT_FLAVOR}"

flavor_root() {
    printf '%s\n' "$HERE/flavors/$selected_flavor"
}

flavor_file() {
    local relative_path="$1"
    local candidate

    candidate="$(flavor_root)/$relative_path"
    [[ -r "$candidate" ]] && {
        printf '%s\n' "$candidate"
        return 0
    }

    return 1
}

resolved_logo_file() {
    flavor_file logo.txt || printf '%s\n' "$HERE/share/logo.txt"
}

resolved_catalog_file() {
    flavor_file catalog.tsv || printf '%s\n' "$HERE/share/catalog.tsv"
}

resolved_desktop_file() {
    flavor_file tinypm.desktop || printf '%s\n' "$HERE/tinypm.desktop"
}

load_flavor_metadata() {
    local config_file

    FLAVOR_NAME="TinyPM"

    config_file="$(flavor_file flavor.conf || true)"
    [[ -n "$config_file" ]] && . "$config_file"
    return 0
}

print_logo() {
    [[ -r "$(resolved_logo_file)" ]] && { cat "$(resolved_logo_file)" >&2; printf '\n' >&2; }
}

print_seed_logo() {
    [[ -r "$HERE/share/seed-logo.txt" ]] && { cat "$HERE/share/seed-logo.txt" >&2; printf '\n' >&2; }
}

detect_native_pm() {
    command -v apt-get >/dev/null 2>&1 && { echo apt; return; }
    command -v dnf >/dev/null 2>&1 && { echo dnf; return; }
    command -v pacman >/dev/null 2>&1 && { echo pacman; return; }
    command -v xbps-install >/dev/null 2>&1 && { echo xbps; return; }
    command -v zypper >/dev/null 2>&1 && { echo zypper; return; }
    command -v apk >/dev/null 2>&1 && { echo apk; return; }
    command -v emerge >/dev/null 2>&1 && { echo emerge; return; }
    command -v brew >/dev/null 2>&1 && { echo brew; return; }
    command -v nix-env >/dev/null 2>&1 && { echo nix; return; }
    echo seed
}

is_valid_native_pm() {
    case "$1" in
        auto|apt|dnf|pacman|xbps|zypper|apk|emerge|brew|nix|seed) return 0 ;;
        *) return 1 ;;
    esac
}

parse_cli_options() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --flavor=*)
                selected_flavor="${1#*=}"
                shift
                ;;
            --flavor)
                shift
                [[ $# -gt 0 ]] || { echo "Missing value for --flavor" >&2; exit 1; }
                selected_flavor="$1"
                shift
                ;;
            -y|--yes|--non-interactive)
                non_interactive=1
                shift
                ;;
            --auto)
                forced_native_pm="auto"
                shift
                ;;
            --native=*)
                forced_native_pm="${1#*=}"
                shift
                ;;
            --native)
                shift
                [[ $# -gt 0 ]] || { echo "Missing value for --native" >&2; exit 1; }
                forced_native_pm="$1"
                shift
                ;;
            -h|--help)
                cat <<'EOH'
TinyPM installer

Usage:
  ./install.sh [--auto] [--native <pm>] [--flavor <name>] [--yes]

Native pm values:
  auto, apt, dnf, pacman, xbps, zypper, apk, emerge, brew, nix, seed
EOH
                exit 0
                ;;
            *)
                echo "Unknown option: $1" >&2
                exit 1
                ;;
        esac
    done

    if [[ -n "$forced_native_pm" ]] && ! is_valid_native_pm "$forced_native_pm"; then
        echo "Invalid native pm: $forced_native_pm" >&2
        exit 1
    fi

    if [[ "$selected_flavor" != "$DEFAULT_FLAVOR" && ! -d "$(flavor_root)" ]]; then
        echo "Unknown flavor: $selected_flavor" >&2
        exit 1
    fi
}

choose_native_pm() {
    local detected choice selected
    detected="$(detect_native_pm)"

    if [[ -n "$forced_native_pm" ]]; then
        if [[ "$forced_native_pm" == "auto" ]]; then
            echo "$detected"
        else
            echo "$forced_native_pm"
        fi
        return
    fi

    if [[ "$non_interactive" -eq 1 ]]; then
        echo "$detected"
        return
    fi

    print_logo
    if [[ "$detected" == "seed" ]]; then
        print_seed_logo
        printf "No native package manager was detected. Seed can act as TinyPM's mini package manager.\n\n" >&2
    fi

    printf '%s Installer\n' "$FLAVOR_NAME" >&2
    printf 'Detected native source: %s\n\n' "$detected" >&2
    printf 'Choose your primary native package manager:\n' >&2
    printf '  1. auto (%s)\n' "$detected" >&2
    printf '  2. apt\n' >&2
    printf '  3. dnf\n' >&2
    printf '  4. pacman\n' >&2
    printf '  5. xbps\n' >&2
    printf '  6. zypper\n' >&2
    printf '  7. apk\n' >&2
    printf '  8. emerge\n' >&2
    printf '  9. brew\n' >&2
    printf ' 10. nix\n' >&2
    printf ' 11. seed\n' >&2
    printf '\nSelect an option [1-11]: ' >&2
    IFS= read -r choice || choice=1

    case "$choice" in
        1|'') selected="$detected" ;;
        2) selected=apt ;;
        3) selected=dnf ;;
        4) selected=pacman ;;
        5) selected=xbps ;;
        6) selected=zypper ;;
        7) selected=apk ;;
        8) selected=emerge ;;
        9) selected=brew ;;
        10) selected=nix ;;
        11) selected=seed ;;
        *) selected="$detected" ;;
    esac

    echo "$selected"
}

install_runtime() {
    local cmd desktop_source

    mkdir -p "$BIN_DIR" "$LOCAL_BIN" "$DESKTOP_DIR" "$CONFIG_DIR"

    cp -R "$HERE/lib" "$BIN_DIR/"
    cp -R "$HERE/share" "$BIN_DIR/"
    cp -R "$HERE/assets" "$BIN_DIR/"
    [[ -d "$HERE/flavors" ]] && cp -R "$HERE/flavors" "$BIN_DIR/"
    cp -f "$HERE/_spinner" "$BIN_DIR/_spinner"
    cp -f "$HERE/tinypm" "$BIN_DIR/tinypm"
    cp -f "$HERE/tinypm-app" "$BIN_DIR/tinypm-app"
    cp -f "$HERE/seed" "$BIN_DIR/seed"
    cp -f "$HERE/version" "$BIN_DIR/version"
    desktop_source="$(resolved_desktop_file)"
    cp -f "$desktop_source" "$BIN_DIR/tinypm.desktop"
    if [[ -f "$HERE/syspm.sh" ]]; then
        cp -f "$HERE/syspm.sh" "$BIN_DIR/syspm"
    fi

    cp -f "$(resolved_logo_file)" "$BIN_DIR/share/logo.txt"
    cp -f "$(resolved_catalog_file)" "$BIN_DIR/share/catalog.tsv"

    chmod +x "$BIN_DIR/_spinner" "$BIN_DIR/tinypm" "$BIN_DIR/tinypm-app" "$BIN_DIR/seed" "$BIN_DIR/version"
    [[ -f "$BIN_DIR/syspm" ]] && chmod +x "$BIN_DIR/syspm"

    ln -sfn "$BIN_DIR/tinypm" "$BIN_DIR/tiny"
    ln -sfn "$BIN_DIR/seed" "$BIN_DIR/seedstore"
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
    ln -sfn "$BIN_DIR/seed" "$LOCAL_BIN/seedstore"
    [[ -f "$BIN_DIR/syspm" ]] && ln -sfn "$BIN_DIR/syspm" "$LOCAL_BIN/syspm"
    ln -sfn "$BIN_DIR/version" "$LOCAL_BIN/version"
    ln -sfn "$BIN_DIR/_spinner" "$LOCAL_BIN/_spinner"

    sed "s#^Exec=.*#Exec=tinypm-app#" "$desktop_source" >"$DESKTOP_DIR/tinypm.desktop"
}

write_config() {
    printf 'native_pm=%s\n' "$1" > "$CONFIG_FILE"
    printf 'seed_update_ref=main\n' >> "$CONFIG_FILE"
    printf 'tinypm_flavor=%s\n' "$selected_flavor" >> "$CONFIG_FILE"
}

ensure_local_bin_on_path() {
    local shell_rc="$HOME/.bashrc"
    [[ -n "${ZSH_VERSION:-}" ]] && shell_rc="$HOME/.zshrc"

    if ! grep -q 'HOME/.local/bin' "$shell_rc" 2>/dev/null; then
        printf "\n# TinyPM\nexport PATH=\"\$HOME/.local/bin:\$PATH\"\n" >>"$shell_rc"
    fi
}

main() {
    local selected_pm

    parse_cli_options "$@"
    load_flavor_metadata
    selected_pm="$(choose_native_pm)"

    install_runtime
    write_config "$selected_pm"
    ensure_local_bin_on_path

    [[ "$selected_pm" == "seed" ]] && print_seed_logo

    printf '\n%s installed to %s\n' "$FLAVOR_NAME" "$BIN_DIR"
    printf 'Primary native source: %s\n' "$selected_pm"
    printf 'Flavor: %s\n' "$selected_flavor"
    printf 'Commands linked into %s\n' "$LOCAL_BIN"
    printf '\nOpen a new terminal or run:\n'
    printf '  hash -r\n'
    printf "  export PATH=\"\$HOME/.local/bin:\$PATH\"\n"
    printf '\nThen test:\n'
    printf "  \"\$HOME/.tinypm/bin/tinypm\" help\n"
    printf "  \"\$HOME/.tinypm/bin/tinypm\" selftest\n"
    printf "  \"\$HOME/.tinypm/bin/tinypm\" doctor --fix\n"
    printf '  syspm update\n'
    printf '  seed store\n'
}

main "$@"
