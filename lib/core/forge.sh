#!/usr/bin/env bash
# shellcheck disable=SC2154

forge_usage() {
    cat <<'EOF2'
Forge — TinyPM V4 core engine

Usage:
  Forge env
  Forge resolve [-f|-s|-n] <package>
  Forge check <package>
  Forge plan [-f|-s|-n] <package> [<package>...]
  Forge --version
  Forge help

Commands:
  env       Show Forge environment, config, and backend status
  resolve   Show which provider would be selected (without installing)
  check     Probe all backends for a package and check the catalog
  plan      Dry-run — show what Forge would do without doing it

All standard tinypm commands also pass through:
  Forge install <package>    same as: tinypm install <package>
  Forge search <query>       same as: tinypm search <query>
EOF2
}

forge_env() {
    local native_pm="none"
    local flavor catalog_path catalog_count_val

    flavor="$(tinypm_active_flavor)"
    catalog_path="$(tinypm_catalog_file)"
    catalog_count_val="$(catalog_count 2>/dev/null || echo 0)"

    if detect_native_pm >/dev/null 2>&1; then
        native_pm="$(detect_native_pm)"
    fi

    printf 'Forge Environment\n'
    printf '%s\n' '------------------------------------------------------------'
    printf '  %-18s %s\n' 'engine'       "$tinypm_engine_name v$tinypm_version"
    printf '  %-18s %s\n' 'system'       "$tinypm_system_name"
    printf '  %-18s %s\n' 'flavor'       "$flavor"
    printf '  %-18s %s\n' 'config'       "${tinypm_config_file:-unset}"
    printf '  %-18s %s\n' 'state_db'     "$(active_state_db)"
    printf '  %-18s %s\n' 'catalog'      "$catalog_path"
    printf '  %-18s %s entries\n' 'catalog_size' "$catalog_count_val"
    printf '  %-18s %s\n' 'backend_mode' "$([[ "${use_host_backend:-0}" -eq 1 ]] && echo host || echo local)"
    printf '  %-18s %s\n' 'native_pm'    "$native_pm"
    local _flatpak_status="missing" _snap_status="missing"
    backend_has_cmd flatpak && _flatpak_status="available" || true
    backend_has_cmd snap    && _snap_status="available"    || true
    printf '  %-18s %s\n' 'flatpak'      "$_flatpak_status"
    printf '  %-18s %s\n' 'snap'         "$_snap_status"
    printf '  %-18s %s\n' 'auth'         "$(backend_auth_mode)"
    printf '  %-18s %s\n' 'script_dir'   "$script_dir"
}

forge_resolve() {
    local package="${1:-}"
    local provider_flag="${2:-auto}"

    [[ -n "$package" ]] || die "resolve requires a package name"

    local native_pm="" options=() priority=1

    if detect_native_pm >/dev/null 2>&1; then
        native_pm="$(detect_native_pm)"
        options+=("native:$(native_pm_label "$native_pm")")
    fi
    backend_has_cmd flatpak && options+=("flatpak:Flatpak")
    backend_has_cmd snap    && options+=("snap:Snap")

    printf 'Forge resolve: %s\n' "$package"
    printf '%s\n' '------------------------------------------------------------'

    if [[ "${#options[@]}" -eq 0 ]]; then
        printf '  No package providers are available on this system.\n'
        return 1
    fi

    printf '  Auto-selection priority:\n'
    for opt in "${options[@]}"; do
        local key="${opt%%:*}"
        local label="${opt#*:}"
        if [[ "$priority" -eq 1 ]]; then
            printf '    %d. %-14s  <- would be selected\n' "$priority" "$label"
        else
            printf '    %d. %s\n' "$priority" "$label"
        fi
        priority=$((priority + 1))
    done

    if [[ "$provider_flag" != "auto" ]]; then
        printf '\n  Requested provider: %s\n' "$provider_flag"
    fi

    printf '\n  Force a specific backend:\n'
    if [[ -n "$native_pm" ]]; then
        printf '    grab -n %-16s# %s\n' "$package " "$(native_pm_label "$native_pm")"
    fi
    if backend_has_cmd flatpak; then
        printf '    grab -f %-16s# Flatpak\n' "$package "
    fi
    if backend_has_cmd snap; then
        printf '    grab -s %-16s# Snap\n' "$package "
    fi
}

forge_check() {
    local package="${1:-}"

    [[ -n "$package" ]] || die "check requires a package name"

    local native_pm=""
    if detect_native_pm >/dev/null 2>&1; then
        native_pm="$(detect_native_pm)"
    fi

    printf 'Forge check: %s\n' "$package"
    printf '%s\n' '------------------------------------------------------------'
    printf '  %-14s  %s\n' "BACKEND" "STATUS"
    printf '  %-14s  %s\n' "---------" "------"

    # Native PM
    if [[ -n "$native_pm" ]]; then
        local _nat_st="not installed (backend available)"
        package_in_apt "$package" "$native_pm" 2>/dev/null && _nat_st="installed" || true
        printf '  %-14s  %s\n' "$native_pm" "$_nat_st"
    else
        printf '  %-14s  no native PM detected\n' "native"
    fi

    # Flatpak
    if backend_has_cmd flatpak; then
        local _fp_st="not installed (backend available)"
        package_in_flatpak "$package" 2>/dev/null && _fp_st="installed" || true
        printf '  %-14s  %s\n' "flatpak" "$_fp_st"
    else
        printf '  %-14s  backend not available\n' "flatpak"
    fi

    # Snap
    if backend_has_cmd snap; then
        local _sn_st="not installed (backend available)"
        package_in_snap "$package" 2>/dev/null && _sn_st="installed" || true
        printf '  %-14s  %s\n' "snap" "$_sn_st"
    else
        printf '  %-14s  backend not available\n' "snap"
    fi

    # Curated catalog lookup (by package ID or display name)
    local catalog_hits=0
    while IFS=$'\t' read -r name cat src pkg desc; do
        if [[ "${pkg,,}" == "${package,,}" || "${name,,}" == "${package,,}" ]]; then
            if [[ "$catalog_hits" -eq 0 ]]; then
                printf '\n  Catalog matches:\n'
            fi
            printf '    %-22s %-10s %-8s %s\n' "$name" "$cat" "$src" "$pkg"
            catalog_hits=$((catalog_hits + 1))
        fi
    done < "$(tinypm_catalog_file)"

    if [[ "$catalog_hits" -eq 0 ]]; then
        printf '\n  Not found in curated catalog.\n'
        printf '  Tip: tinypm search %s\n' "$package"
    fi
}

forge_plan() {
    local provider_flag="${1:-auto}"
    shift
    local pkgs=("$@")

    [[ "${#pkgs[@]}" -gt 0 ]] || die "plan requires at least one package name"

    local resolved_provider label native_pm=""

    if detect_native_pm >/dev/null 2>&1; then
        native_pm="$(detect_native_pm)"
    fi

    # Determine which provider would be selected (non-interactively: pick first available)
    case "$provider_flag" in
        flatpak) resolved_provider="flatpak" ; label="Flatpak" ;;
        snap)    resolved_provider="snap"    ; label="Snap" ;;
        native|apt|dnf|pacman|xbps|zypper|apk|emerge|brew|nix)
            resolved_provider="${provider_flag}"
            label="$(native_pm_label "${provider_flag:-native}") (native)"
            ;;
        auto)
            if [[ -n "$native_pm" ]]; then
                resolved_provider="$native_pm"
                label="$(native_pm_label "$native_pm") (native, auto)"
            elif backend_has_cmd flatpak; then
                resolved_provider="flatpak"
                label="Flatpak (auto)"
            elif backend_has_cmd snap; then
                resolved_provider="snap"
                label="Snap (auto)"
            else
                die "no package provider available"
            fi
            ;;
        *) die "unknown provider: $provider_flag" ;;
    esac

    printf 'Forge plan (dry-run)\n'
    printf '%s\n' '------------------------------------------------------------'
    printf '  Provider:  %s\n' "$label"
    printf '  Packages:  %d\n' "${#pkgs[@]}"
    printf '\n'
    local i=0
    for pkg in "${pkgs[@]}"; do
        i=$((i + 1))
        printf '  [%d] %s\n' "$i" "$pkg"
    done
    printf '\n'

    local flag_str=""
    case "$resolved_provider" in
        flatpak) flag_str=" -f" ;;
        snap)    flag_str=" -s" ;;
        native|apt|dnf|pacman|*) [[ "$provider_flag" != "auto" ]] && flag_str=" -n" ;;
    esac
    printf '  To execute: grab%s %s\n' "$flag_str" "${pkgs[*]}"
}
