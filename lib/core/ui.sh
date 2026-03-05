#!/usr/bin/env bash
# shellcheck disable=SC2154

usage() {
    cat <<'EOF2'
TinyPM.2.0.2.Aedition (abora): a tiny package manager frontend for Linux package ecosystems

Usage:
  tinypm install [-f|-s|-n|--seed|--brew|--nix] <package>
  tinypm search [-f|-s|-n|--seed|--brew|--nix] <query>
  tinypm remove [-f|-s|-n|--seed|--brew|--nix] <package>
  tinypm list [-f|-s|-n|--seed|--brew|--nix]
  tinypm run [-f|-s|--seed] <app>
  tinypm start [-f|-s|--seed] <app>
  tinypm update [-f|-s|-n|--seed|--brew|--nix]
  tinypm info <package>
  tinypm managed
  tinypm export-state [file]
  tinypm import-state <file>
  tinypm selftest
  tinypm apps
  tinypm discover [query]
  tinypm doctor [--fix]
  tinypm version
  tinypm app
  tinypm-app
  tiny --version
  syspm update
  seed [store|search|install|remove|list|run|update|rollback|about]

Quick aliases:
  tinypm i <pkg>         # install
  tinypm s <query>       # search
  tinypm r <pkg>         # remove
  tinypm u               # update
  tinypm ls              # list
  tinypm v               # version

Shortcuts:
  ainstall [-f|-s|-n|--seed|--brew|--nix] <package>
  search   [-f|-s|-n|--seed|--brew|--nix] <query>
  term     [-f|-s|-n|--seed|--brew|--nix] <package>
  start    [-f|-s|--seed] <app>
  supdate  [-f|-s|-n|--seed|--brew|--nix]

Flags:
  -f, --flat, --flatpak  use Flatpak
  -s, --snp, --snap      use Snap
  -n, --nat, --native    use detected native manager
  --brew                 force Homebrew backend
  --nix                  force Nix backend
  --seed                 use Seed mini package manager

Native PM detection supports:
  apt, dnf, pacman, xbps, zypper, apk, emerge, brew, nix

Notes:
  Use short source picks in terminal app: auto, f, s, n, seed.
  `discover` and `seed store` are curated catalogs, not every package everywhere.
  `syspm` routes TinyPM through the native system package manager only.
  `seed update` creates a backup, updates from GitHub, and refreshes Seed packages.
  Use `seed rollback <backup.tar.gz>` to restore from a backup if needed.
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
