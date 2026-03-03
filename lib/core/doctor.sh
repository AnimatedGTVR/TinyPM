#!/usr/bin/env bash

doctor_command_path() {
    local name="$1"
    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
        return
    fi
    if [[ -e "$HOME/.local/bin/$name" ]]; then
        printf '%s\n' "$HOME/.local/bin/$name"
        return
    fi
    printf '%s\n' missing
}

doctor() {
    local path_state="missing"
    local gui_state="terminal-only"
    local flatpak_state="missing"
    local snap_state="missing"
    local native_state="missing"
    local seed_state="available"
    local native_pm="none"

    case ":${PATH:-}:" in
        *":$HOME/.local/bin:"*) path_state="present" ;;
    esac

    if [[ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ]]; then
        gui_state="available"
    fi

    if backend_has_cmd flatpak; then
        flatpak_state="available"
    fi

    if backend_has_cmd snap; then
        snap_state="available"
    fi

    if detect_native_pm >/dev/null 2>&1; then
        native_pm="$(detect_native_pm)"
        native_state="$(native_pm_label "$native_pm")"
    fi

    if ! seed_has_recipes; then
        seed_state="missing"
    fi

    printf 'TinyPM doctor\n'
    printf '%s\n' '------------------------------------------------------------'
    printf '  %-16s %s\n' 'script_dir' "$script_dir"
    printf '  %-16s %s\n' 'path' "$path_state"
    printf '  %-16s %s\n' 'tinypm' "$(doctor_command_path tinypm)"
    printf '  %-16s %s\n' 'tiny' "$(doctor_command_path tiny)"
    printf '  %-16s %s\n' 'syspm' "$(doctor_command_path syspm)"
    printf '  %-16s %s\n' 'seed' "$(doctor_command_path seed)"
    printf '  %-16s %s\n' 'ainstall' "$(doctor_command_path ainstall)"
    printf '  %-16s %s\n' 'search' "$(doctor_command_path search)"
    printf '  %-16s %s\n' 'term' "$(doctor_command_path term)"
    printf '  %-16s %s\n' 'start' "$(doctor_command_path start)"
    printf '  %-16s %s\n' 'supdate' "$(doctor_command_path supdate)"
    printf '  %-16s %s\n' 'tinypm-app' "$(doctor_command_path tinypm-app)"
    printf '  %-16s %s\n' 'backend_mode' "$([[ "$use_host_backend" -eq 1 ]] && echo host || echo local)"
    printf '  %-16s %s\n' 'auth_mode' "$(backend_auth_mode)"
    printf '  %-16s %s\n' 'native_pm' "$native_pm"
    printf '  %-16s %s\n' 'state_db' "$(active_state_db)"
    printf '  %-16s %s\n' 'gui' "$gui_state"
    printf '  %-16s %s\n' 'flatpak' "$flatpak_state"
    printf '  %-16s %s\n' 'snap' "$snap_state"
    printf '  %-16s %s\n' 'native' "$native_state"
    printf '  %-16s %s\n' 'seed' "$seed_state"
}
