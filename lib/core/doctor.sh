#!/usr/bin/env bash
# shellcheck disable=SC2154

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

doctor_fix_runtime() {
    local local_bin="$HOME/.local/bin"
    local desktop_dir="$HOME/.local/share/applications"
    local shell_rc="$HOME/.bashrc"
    local cmd

    mkdir -p "$local_bin" "$desktop_dir"

    ln -sfn "$script_dir/tinypm" "$local_bin/tinypm"
    ln -sfn "$script_dir/tinypm" "$local_bin/tiny"

    for cmd in ainstall search term start supdate; do
        ln -sfn "$script_dir/tinypm" "$local_bin/$cmd"
    done

    ln -sfn "$script_dir/tinypm-app" "$local_bin/tinypm-app"
    ln -sfn "$script_dir/seed" "$local_bin/seed"
    ln -sfn "$script_dir/seed" "$local_bin/seedstore"
    ln -sfn "$script_dir/version" "$local_bin/version"
    ln -sfn "$script_dir/_spinner" "$local_bin/_spinner"

    if [[ -x "$script_dir/syspm" ]]; then
        ln -sfn "$script_dir/syspm" "$local_bin/syspm"
    elif [[ -x "$script_dir/syspm.sh" ]]; then
        ln -sfn "$script_dir/syspm.sh" "$local_bin/syspm"
    fi

    if [[ -r "$script_dir/tinypm.desktop" ]]; then
        sed 's#^Exec=.*#Exec=tinypm-app#' "$script_dir/tinypm.desktop" > "$desktop_dir/tinypm.desktop"
    fi

    if ! grep -q 'HOME/.local/bin' "$shell_rc" 2>/dev/null; then
        printf "\n# TinyPM\nexport PATH=\"\$HOME/.local/bin:\$PATH\"\n" >> "$shell_rc"
    fi

    printf 'Doctor fix applied: launchers and desktop entry refreshed.\n'
}

selftest() {
    local failures=0
    local native_pm="none"

    printf 'TinyPM selftest\n'
    printf '%s\n' '------------------------------------------------------------'

    [[ -x "$script_dir/tinypm" ]] || { echo '[fail] missing tinypm entrypoint'; failures=$((failures+1)); }
    [[ -x "$script_dir/seed" ]] || { echo '[fail] missing seed wrapper'; failures=$((failures+1)); }
    [[ -x "$script_dir/version" ]] || { echo '[fail] missing version command'; failures=$((failures+1)); }

    if detect_native_pm >/dev/null 2>&1; then
        native_pm="$(detect_native_pm)"
        echo "[ok] native package manager detected: $native_pm"
    else
        echo '[warn] no native package manager detected (Seed fallback only)'
    fi

    if backend_has_cmd flatpak; then
        echo '[ok] flatpak detected'
    else
        echo '[warn] flatpak missing'
    fi

    if backend_has_cmd snap; then
        echo '[ok] snap detected'
    else
        echo '[warn] snap missing'
    fi

    if seed_has_recipes; then
        echo '[ok] seed recipes available'
    else
        echo '[fail] seed recipes missing'
        failures=$((failures+1))
    fi

    if discover_apps >/dev/null 2>&1; then
        echo '[ok] catalog parse works'
    else
        echo '[fail] catalog parse failed'
        failures=$((failures+1))
    fi

    if [[ "$failures" -eq 0 ]]; then
        echo '[ok] selftest passed'
        return 0
    fi

    echo "[fail] selftest failed: $failures issue(s)"
    return 1
}

doctor() {
    local path_state="missing"
    local gui_state="terminal-only"
    local flatpak_state="missing"
    local snap_state="missing"
    local native_state="missing"
    local seed_state="available"
    local native_pm="none"

    if [[ "${doctor_fix:-0}" -eq 1 ]]; then
        doctor_fix_runtime
    fi

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
    printf '  %-16s %s\n' 'seedstore' "$(doctor_command_path seedstore)"
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
