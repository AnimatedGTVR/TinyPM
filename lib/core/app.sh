#!/usr/bin/env bash

app_divider() {
    printf '\n============================================================\n'
}

app_pause() {
    local _
    printf '\nPress Enter to go back...'
    IFS= read -r _ || true
}

app_pick_provider() {
    local choice

    printf 'Choose a source [auto/native/flatpak/snap/seed/apt/dnf/pacman/xbps/zypper/apk/emerge] (default: auto): ' >&2
    IFS= read -r choice || return 1
    choice="${choice:-auto}"
    provider_from_flag "$choice" 2>/dev/null || normalize_provider "$choice"
}

app_prompt_value() {
    local label="$1"
    local value

    printf '%s: ' "$label"
    IFS= read -r value || return 1
    [[ -n "$value" ]] || return 1
    printf '%s\n' "$value"
}

terminal_app_ui() {
    local choice provider package native_display

    while true; do
        native_display="$(detect_native_pm 2>/dev/null || echo seed)"
        app_divider
        printf 'TinyPM Terminal App\n'
        printf 'Native source: %s | Installed desktop apps: %s | Managed: %s | Catalog: %s\n' \
            "$(native_pm_label "$native_display")" \
            "$(installed_app_count 2>/dev/null || echo 0)" \
            "$(tracked_package_count 2>/dev/null || echo 0)" \
            "$(catalog_count 2>/dev/null || echo 0)"
        printf 'Discover and Seed Store are curated catalogs. Use syspm update for your native system packages.\n'
        printf "Seed is TinyPM's built-in mini package manager and can refresh TinyPM with seed update.\n"
        printf '\n'
        printf '1. View my desktop apps\n'
        printf '2. Browse discover catalog\n'
        printf '3. Search package sources\n'
        printf '4. View installed packages by source\n'
        printf '5. Install a package by name\n'
        printf '6. Remove a package by name\n'
        printf '7. View TinyPM-managed packages\n'
        printf '8. Show package info\n'
        printf '9. Update packages\n'
        printf '10. Run an app\n'
        printf '11. Show doctor info\n'
        printf '0. Exit\n'
        printf '\nSelect an option: '
        IFS= read -r choice || break

        case "$choice" in
            1)
                app_divider
                printf 'My Desktop Apps\n\n'
                installed_apps
                app_pause
                ;;
            2)
                app_divider
                printf 'Discover Catalog\n'
                printf 'This is a curated starter list, not the full package universe.\n\n'
                discover_apps
                app_pause
                ;;
            3)
                package="$(app_prompt_value "Search query")" || continue
                provider="$(app_pick_provider)" || continue
                app_divider
                printf 'Search Results\n\n'
                search_pkg "$package" "$provider"
                app_pause
                ;;
            4)
                provider="$(app_pick_provider)" || continue
                app_divider
                printf 'Installed Packages\n\n'
                list_pkgs "$provider"
                app_pause
                ;;
            5)
                package="$(app_prompt_value "Package to install")" || continue
                provider="$(app_pick_provider)" || continue
                install_pkg "$package" "$provider"
                app_pause
                ;;
            6)
                package="$(app_prompt_value "Package to remove")" || continue
                provider="$(app_pick_provider)" || continue
                remove_pkg "$package" "$provider"
                app_pause
                ;;
            7)
                app_divider
                printf 'TinyPM-Managed Packages\n\n'
                managed_pkgs
                app_pause
                ;;
            8)
                package="$(app_prompt_value "Package name")" || continue
                app_divider
                printf 'Package Info\n\n'
                info_pkg "$package"
                app_pause
                ;;
            9)
                provider="$(app_pick_provider)" || continue
                update_pkgs "$provider"
                app_pause
                ;;
            10)
                package="$(app_prompt_value "App id, command, or seed package")" || continue
                provider="$(app_pick_provider)" || continue
                run_pkg "$package" "$provider"
                ;;
            11)
                app_divider
                printf 'Doctor\n\n'
                doctor
                app_pause
                ;;
            0)
                break
                ;;
            *)
                printf 'Invalid choice. Pick a number from the menu.\n'
                app_pause
                ;;
        esac
    done
}

app_ui() {
    terminal_app_ui
}
