#!/usr/bin/env bash
# shellcheck disable=SC2154

seed_root="${XDG_DATA_HOME:-$HOME/.local/share}/tinypm/seed"
seed_packages_dir="$seed_root/packages"
seed_bin_dir="$seed_root/bin"
seed_recipe_file="$script_dir/share/seed.tsv"
seed_catalog_file="$(tinypm_catalog_file)"

seed_recipe_entries() {
    [[ -r "$seed_recipe_file" ]] || return 1
    cat "$seed_recipe_file"
}

seed_has_recipes() {
    [[ -r "$seed_recipe_file" ]] && [[ -s "$seed_recipe_file" ]]
}

seed_catalog_entries() {
    [[ -r "$seed_catalog_file" ]] || return 1
    cat "$seed_catalog_file"
}

seed_catalog_available() {
    [[ -r "$seed_catalog_file" ]] && [[ -s "$seed_catalog_file" ]]
}

seed_ensure_dirs() {
    mkdir -p "$seed_packages_dir" "$seed_bin_dir"
}

seed_package_row() {
    local package="$1"

    seed_recipe_entries | awk -F '\t' -v pkg="$package" '$1 == pkg { print; found=1; exit } END { exit(found ? 0 : 1) }'
}

seed_catalog_row() {
    local package="$1"

    seed_catalog_entries | awk -F '\t' -v pkg="$(printf '%s' "$package" | tr '[:upper:]' '[:lower:]')" '
        BEGIN { best=99 }
        function rank(source) {
            if (source == "seed") return 1
            if (source == "flatpak") return 2
            if (source == "snap") return 3
            if (source == "apt") return 4
            return 9
        }
        {
            name=tolower($1)
            source=tolower($3)
            target=tolower($4)
            if (name == pkg || target == pkg) {
                if (rank(source) < best) {
                    row=$0
                    best=rank(source)
                    found=1
                }
            }
        }
        END {
            if (found) print row
            else exit 1
        }'
}

package_in_seed() {
    [[ -x "$seed_bin_dir/$1" ]]
}

seed_download_cmd() {
    if has_cmd curl; then
        printf '%s\n' curl
    elif has_cmd wget; then
        printf '%s\n' wget
    else
        return 1
    fi
}

seed_arch_supported() {
    local url="$1"
    local arch

    arch="$(backend_run uname -m 2>/dev/null || uname -m)"

    case "$url" in
        *amd64*|*x86_64*)
            [[ "$arch" == "x86_64" || "$arch" == "amd64" ]] || return 1
            ;;
        *arm64*|*aarch64*)
            [[ "$arch" == "aarch64" || "$arch" == "arm64" ]] || return 1
            ;;
    esac

    return 0
}

seed_download_to() {
    local url="$1"
    local destination="$2"
    local downloader

    downloader="$(seed_download_cmd)" || die "seed requires curl or wget"

    case "$downloader" in
        curl) backend_run curl -L --fail --output "$destination" "$url" ;;
        wget) backend_run wget -O "$destination" "$url" ;;
    esac
}

seed_install_recipe() {
    local package="$1"
    local row name package_type url exec_name _description package_dir file_path wrapper_path

    row="$(seed_package_row "$package")" || return 1
    IFS=$'\t' read -r name package_type url exec_name _description <<EOI
$row
EOI

    seed_ensure_dirs
    package_dir="$seed_packages_dir/$name"
    file_path="$package_dir/$exec_name"
    wrapper_path="$seed_bin_dir/$name"

    mkdir -p "$package_dir"

    case "$package_type" in
        binary)
            seed_arch_supported "$url" || die "seed package $name is not available for this architecture"
            run_with_spinner "Downloading $name with Seed" seed_download_to "$url" "$file_path"
            [[ -f "$file_path" ]] || die "seed download did not produce $file_path"
            chmod +x "$file_path"
            ;;
        *)
            die "unsupported seed package type: $package_type"
            ;;
    esac

    cat >"$wrapper_path" <<EOW
#!/usr/bin/env bash
exec "$file_path" "\$@"
EOW
    chmod +x "$wrapper_path"
}

seed_install_from_catalog() {
    local query="$1"
    local row name _category source package _description

    row="$(seed_catalog_row "$query")" || die "seed package not found: $query"
    IFS=$'\t' read -r name _category source package _description <<EOR
$row
EOR

    case "$source" in
        seed) seed_install_recipe "$package" ;;
        flatpak) install_flatpak "$package" ;;
        snap) snap_install "$package" ;;
        apt) apt_install "$package" "$(detect_native_pm 2>/dev/null || echo apt)" ;;
        *) die "unsupported seed catalog source: $source" ;;
    esac
}

seed_install() {
    local package="$1"

    if seed_has_recipes && seed_package_row "$package" >/dev/null 2>&1; then
        seed_install_recipe "$package"
        return
    fi

    if seed_catalog_available; then
        seed_install_from_catalog "$package"
        return
    fi

    die "seed package not found: $package"
}

seed_search() {
    local query="${1:-}"

    if seed_catalog_available; then
        printf "%-22s %-14s %-8s %-32s %s\n" "NAME" "CATEGORY" "SOURCE" "PACKAGE" "DESCRIPTION"
        if [[ -z "$query" ]]; then
            seed_catalog_entries | awk -F '\t' '{ printf "%-22s %-14s %-8s %-32s %s\n", $1, $2, $3, $4, $5 }'
            return
        fi

        seed_catalog_entries | awk -F '\t' -v q="$query" '
            BEGIN { q=tolower(q) }
            {
                line=tolower($0)
                if (index(line, q) > 0) {
                    printf "%-22s %-14s %-8s %-32s %s\n", $1, $2, $3, $4, $5
                }
            }'
        return
    fi

    printf "%-20s %-10s %-18s %s\n" "PACKAGE" "TYPE" "COMMAND" "DESCRIPTION"
    if [[ -z "$query" ]]; then
        seed_recipe_entries | awk -F '\t' '{ printf "%-20s %-10s %-18s %s\n", $1, $2, $4, $5 }'
        return
    fi

    seed_recipe_entries | awk -F '\t' -v q="$query" '
        BEGIN { q=tolower(q) }
        {
            line=tolower($0)
            if (index(line, q) > 0) {
                printf "%-20s %-10s %-18s %s\n", $1, $2, $4, $5
            }
        }'
}

seed_remove() {
    local package="$1"

    [[ -d "$seed_packages_dir/$package" || -x "$seed_bin_dir/$package" ]] || die "seed package is not installed: $package"
    rm -rf "${seed_packages_dir:?}/$package"
    rm -f "$seed_bin_dir/$package"
}

seed_list() {
    printf "%-20s %-18s %s\n" "PACKAGE" "COMMAND" "LOCATION"
    [[ -d "$seed_bin_dir" ]] || return 0

    find "$seed_bin_dir" -maxdepth 1 -type f -perm -u+x | sort | while IFS= read -r path; do
        package="$(basename "$path")"
        printf "%-20s %-18s %s\n" "$package" "$package" "$path"
    done
}

seed_run() {
    [[ -x "$seed_bin_dir/$1" ]] || die "seed package is not installed: $1"
    backend_exec "$seed_bin_dir/$1"
}

seed_update() {
    local package

    [[ -d "$seed_packages_dir" ]] || {
        echo "No Seed packages are currently installed."
        return
    }

    while IFS= read -r package; do
        [[ -n "$package" ]] || continue
        seed_install_recipe "$package"
    done <<EOU
$(find "$seed_packages_dir" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort)
EOU
}
