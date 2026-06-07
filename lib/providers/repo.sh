#!/usr/bin/env bash
# shellcheck disable=SC2154
#
# Repository management: the Parcel answer to `add-apt-repository`.
# Each native package manager has its own notion of "extra source", so we
# translate a single `grab-add-repo <spec>` into the right call per backend.

repo_add_apt() {
    local spec="$1"

    if ! backend_has_cmd add-apt-repository; then
        run_with_spinner "Installing software-properties-common" \
            backend_run_root apt-get install -y software-properties-common \
            || die "add-apt-repository is unavailable and could not be installed"
    fi

    native_run_with_error apt "add-repository $spec" \
        run_with_spinner "Adding repository $spec" \
        backend_run_root add-apt-repository -y "$spec"
}

repo_add_dnf() {
    local spec="$1"
    local project

    case "$spec" in
        copr:*)
            project="${spec#copr:}"
            native_run_with_error dnf "copr enable $project" \
                run_with_spinner "Enabling COPR $project" \
                backend_run_root dnf copr enable -y "$project"
            ;;
        *)
            if ! backend_run dnf config-manager --help >/dev/null 2>&1; then
                run_with_spinner "Installing dnf-plugins-core" \
                    backend_run_root dnf install -y dnf-plugins-core \
                    || die "dnf config-manager is unavailable and could not be installed"
            fi
            native_run_with_error dnf "config-manager $spec" \
                run_with_spinner "Adding repository $spec" \
                backend_run_root dnf config-manager --add-repo "$spec"
            ;;
    esac
}

repo_add_zypper() {
    local spec="$1"
    local name="$2"

    if [[ -n "$name" ]]; then
        native_run_with_error zypper "addrepo $spec" \
            run_with_spinner "Adding repository $name" \
            backend_run_root zypper --non-interactive addrepo --refresh "$spec" "$name"
    else
        native_run_with_error zypper "addrepo $spec" \
            run_with_spinner "Adding repository $spec" \
            backend_run_root zypper --non-interactive addrepo --refresh "$spec"
    fi
}

repo_add_apk() {
    local spec="$1"

    # shellcheck disable=SC2016
    backend_run_root sh -c 'printf "%s\n" "$1" >> /etc/apk/repositories' sh "$spec" \
        || die "failed to append repository to /etc/apk/repositories"
    printf 'Appended %s to /etc/apk/repositories\n' "$spec"
}

repo_add_pacman() {
    local spec="$1"
    local name="$2"
    local server

    case "$spec" in
        *=*)
            name="${spec%%=*}"
            server="${spec#*=}"
            ;;
        *)
            server="$spec"
            ;;
    esac

    [[ -n "$name" && -n "$server" ]] \
        || die 'pacman repos need a name and server URL, e.g. grab-add-repo myrepo=https://example.com/$arch'

    # shellcheck disable=SC2016
    backend_run_root sh -c 'printf "\n[%s]\nServer = %s\n" "$1" "$2" >> /etc/pacman.conf' sh "$name" "$server" \
        || die "failed to append repository to /etc/pacman.conf"
    printf 'Appended [%s] repository to /etc/pacman.conf\n' "$name"
}

repo_add_xbps() {
    local spec="$1"

    # shellcheck disable=SC2016
    backend_run_root sh -c 'mkdir -p /etc/xbps.d && printf "repository=%s\n" "$1" >> /etc/xbps.d/10-tinypm.conf' sh "$spec" \
        || die "failed to write /etc/xbps.d/10-tinypm.conf"
    printf 'Registered repository %s in /etc/xbps.d/10-tinypm.conf\n' "$spec"
}

repo_add_brew() {
    local spec="$1"

    native_run_with_error brew "tap $spec" \
        run_with_spinner "Tapping $spec" \
        backend_run brew tap "$spec"
}

# Abora rides on NixOS, so "adding a repo" means registering a Nix channel.
# PPAs are Ubuntu-only and cannot translate, so we fail with a helpful hint.
repo_add_nix() {
    local spec="$1"
    local name="$2"
    local url

    case "$spec" in
        ppa:*)
            die "PPAs are Ubuntu-only and cannot be added on a Nix/Abora system. Pass a channel URL instead, e.g. grab-add-repo https://nixos.org/channels/nixos-unstable unstable"
            ;;
        *=*)
            name="${spec%%=*}"
            url="${spec#*=}"
            ;;
        *)
            url="$spec"
            ;;
    esac

    [[ -n "$url" ]] || die "add-repo requires a channel URL on Nix"
    [[ -n "$name" ]] || name="$(basename "$url")"

    native_run_with_error nix "channel add $url" \
        run_with_spinner "Adding Nix channel $name" \
        backend_run nix-channel --add "$url" "$name"
    native_run_with_error nix "channel update $name" \
        run_with_spinner "Updating Nix channel $name" \
        backend_run nix-channel --update "$name"
    printf 'Nix channel %s added and updated. Install with "grab <package>".\n' "$name"
}

repo_add() {
    local spec="$1"
    local name="$2"
    local pm="$3"

    case "$pm" in
        apt) repo_add_apt "$spec" ;;
        dnf) repo_add_dnf "$spec" ;;
        zypper) repo_add_zypper "$spec" "$name" ;;
        apk) repo_add_apk "$spec" ;;
        pacman) repo_add_pacman "$spec" "$name" ;;
        xbps) repo_add_xbps "$spec" ;;
        brew) repo_add_brew "$spec" ;;
        nix) repo_add_nix "$spec" "$name" ;;
        emerge) die "Portage overlays are managed with eselect-repository or layman; Parcel cannot add '$spec' automatically" ;;
        *) die "add-repo is not supported for $pm" ;;
    esac

    # Nix already refreshes its channel above; everything else needs an update pass.
    [[ "$pm" == "nix" ]] \
        || printf 'Repository added. Run "grab update" to refresh %s package lists.\n' "$(native_pm_label "$pm")"
}
