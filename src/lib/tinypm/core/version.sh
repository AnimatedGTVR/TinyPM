#!/usr/bin/env bash
# shellcheck disable=SC2154

print_version_report() {
    local native_pm="none" native_status="missing"
    local flatpak_status="missing" snap_status="missing"
    local os_name kernel_name arch_name flavor_key

    native_pm="$(detect_native_pm 2>/dev/null || echo none)"
    [[ "$native_pm" == "none" ]] || native_status="$(native_pm_label "$native_pm")"
    backend_has_cmd flatpak && flatpak_status="available"
    backend_has_cmd snap && snap_status="available"

    os_name="$(backend_os_name)"
    kernel_name="$(backend_run uname -r 2>/dev/null || echo unknown)"
    arch_name="$(backend_run uname -m 2>/dev/null || echo unknown)"
    flavor_key="$(tinypm_active_flavor)"

    if [[ -r "$(tinypm_logo_file)" && -t 1 ]]; then
        printf '%s' "$c_cyan"
        cat "$(tinypm_logo_file)"
        printf '%s\n' "$c_reset"
    fi

    ui_heading "$(tinypm_version_label)"
    [[ -n "$tinypm_tagline" ]] && printf '%s%s%s\n' "$c_dim" "$tinypm_tagline" "$c_reset"
    printf '%s\n' '----------------------------------------'
    printf '  %s%-12s%s %s\n' "$c_cyan" 'OS' "$c_reset" "$os_name"
    printf '  %s%-12s%s %s (%s)\n' "$c_cyan" 'Kernel' "$c_reset" "$kernel_name" "$arch_name"
    printf '  %s%-12s%s %s\n' "$c_cyan" 'Native' "$c_reset" "$native_status"
    printf '  %s%-12s%s flatpak=%s snap=%s\n' "$c_cyan" 'Optional' "$c_reset" "$flatpak_status" "$snap_status"
    printf '  %s%-12s%s %s\n' "$c_cyan" 'Flavor' "$c_reset" "$flavor_key"
    printf '  %s%-12s%s %s\n' "$c_cyan" 'Tracked' "$c_reset" "$(tracked_package_count 2>/dev/null || echo 0)"
    printf '  %s%-12s%s %s\n' "$c_cyan" 'Catalog' "$c_reset" "$(catalog_count 2>/dev/null || echo 0)"
}
