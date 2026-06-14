#!/usr/bin/env bash
# shellcheck disable=SC2154

usage() {
    printf '%s\n' "$tinypm_system_name"
    printf 'Core engine: %s\n' "$tinypm_engine_name"
    [[ -n "$tinypm_tagline" ]] && printf '%s\n' "$tinypm_tagline"
    cat <<EOF2

Usage:
  grab [-f|-flat|-flatpak|-s|-n] <package...>
  grab --dry-run [-f|-flat|-flatpak|-s|-n] <package...>
  grab-add-repo <repo> [name]
  grab-de <desktop>
  tinypm install [-f|-flat|-flatpak|-s|-n|--brew|--nix] <package...>
  tinypm remove  [-f|-flat|-flatpak|-s|-n|--brew|--nix] <package...>
  tinypm update | upgrade [-f|-flat|-flatpak|-s|-n|--brew|--nix]
  tinypm search  [-f|-flat|-flatpak|-s|-n|--brew|--nix] <query>
  tinypm info    <package>
  tinypm check   <package>
  tinypm list    [-f|-flat|-flatpak|-s|-n|--brew|--nix]
  tinypm run | start [-f|-flat|-flatpak|-s] <app>
  tinypm add-repo <repo> [name]
  tinypm de <desktop>
  tinypm managed
  tinypm pin <package>
  tinypm unpin <package>
  tinypm pinned
  tinypm bundle list
  tinypm bundle <category> [-f|-s|-n]
  tinypm sync <manifest-file>
  tinypm sync --generate [output-file]
  tinypm history [N]
  tinypm apps
  tinypm discover [query]
  tinypm export-state [file]
  tinypm import-state <file>
  tinypm selftest
  tinypm doctor [--fix]
  tinypm version
  tiny --version
  $tinypm_engine_name --version
  Forge env | resolve | check | plan | --version
  grab firefox vlc gimp
  syspm update

Quick aliases:
  tinypm i <pkg...>      # install
  tinypm s <query>       # search
  tinypm r <pkg...>      # remove
  tinypm u               # update
  tinypm ls              # list
  tinypm v               # version
  tinypm h [N]           # history
  tinypm p <pkg>         # pin
  tinypm b <category>    # bundle
  tinypm c <pkg>         # check (Forge check)

Flags:
  -f, -flat, -flatpak    use Flatpak
  -s, --snp, --snap      use Snap
  -n, --nat, --native    use detected native manager
  --brew                 force Homebrew backend
  --nix                  force Nix backend
  -d, --dry-run          show plan without installing

Native PM detection supports:
  apt, dnf, pacman, xbps, zypper, apk, emerge, brew, nix

Add a source (like add-apt-repository):
  grab-add-repo ppa:hepp3n/cosmic-epoch     # apt
  grab update
  grab cosmic-session
  grab-add-repo https://nixos.org/channels/nixos-unstable unstable   # Abora/Nix

Install a desktop environment:
  grab-de cosmic        # also: gnome, plasma, xfce
  grab-de gnome
  On Nix/Abora, grab-de prints the configuration.nix lines to add.

Notes:
  If multiple backends are installed, grab asks which source to use.
  add-repo routes to the native backend (PPA on apt, channel on Nix, tap on brew, ...).
  discover is a curated catalog, not every package everywhere.
  syspm routes TinyPM through the native system package manager only.
  grab firefox vlc gimp          # install multiple at once
  grab --dry-run firefox vlc     # dry-run via Forge plan
  tinypm check firefox           # probe all backends + catalog
  tinypm upgrade                 # alias for update
  tinypm bundle Gaming           # install a whole category
  tinypm sync packages.txt       # install from manifest
  tinypm pin firefox             # skip during updates
  Forge env                      # show engine environment
  Forge resolve firefox          # which provider would be used
  Forge plan -f firefox vlc      # dry-run install plan
EOF2
}

run_with_spinner() {
    local message="$1"
    shift

    if [[ $# -gt 0 ]] && declare -F "$1" >/dev/null 2>&1; then
        local func_name="$1"
        shift

        export use_host_backend
        while read -r _ _ exported_func; do
            # shellcheck disable=SC2163
            export -f "$exported_func"
        done < <(declare -F)

        # shellcheck disable=SC2016
        "$spinner" "$message" -- bash -lc 'func_name="$1"; shift; "$func_name" "$@"' bash "$func_name" "$@"
        return
    fi

    "$spinner" "$message" -- "$@"
}
