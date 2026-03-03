#!/usr/bin/env bash

usage() {
    cat <<'EOF2'
TinyPM v2.0.0-alpha-untested.1: a tiny package manager for native Linux PMs, Flatpak, Snap, and Seed

Usage:
  tinypm install [-f|-s|-n|--seed] <package>
  tinypm search [-f|-s|-n|--seed] <query>
  tinypm remove [-f|-s|-n|--seed] <package>
  tinypm list [-f|-s|-n|--seed]
  tinypm run [-f|-s|--seed] <app>
  tinypm start [-f|-s|--seed] <app>
  tinypm update [-f|-s|-n|--seed]
  tinypm info <package>
  tinypm managed
  tinypm apps
  tinypm discover [query]
  tinypm doctor
  tinypm version
  tinypm app
  tinypm-app
  tiny --version
  syspm update
  seed [store|search|install|remove|list|run|update|about]

Shortcuts:
  ainstall [-f|-s|-n|--seed] <package>
  search   [-f|-s|-n|--seed] <query>
  term     [-f|-s|-n|--seed] <package>
  start    [-f|-s|--seed] <app>
  supdate  [-f|-s|-n|--seed]

Flags:
  -f, --flat, --flatpak  use Flatpak
  -s, --snp, --snap      use Snap
  -n, --nat, --native    use the detected native package manager
  --seed                 use Seed, TinyPM's built-in mini package manager

Native PMs:
  TinyPM can detect apt, dnf, pacman, xbps, zypper, apk, and emerge.

Notes:
  `discover` and `seed store` are curated catalogs, not every package available everywhere.
  If no native package manager is detected, TinyPM can fall back to Seed.
  `syspm` routes TinyPM through the native system package manager.
  `seed update` refreshes TinyPM from GitHub and then refreshes installed Seed packages.
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
            export -f "$exported_func"
        done < <(declare -F)

        "$spinner" "$message" -- bash -lc 'func_name="$1"; shift; "$func_name" "$@"' bash "$func_name" "$@"
        return
    fi

    "$spinner" "$message" -- "$@"
}
