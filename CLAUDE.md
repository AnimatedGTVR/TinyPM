# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

TinyPM V3 (engine name **Parcel**) is a pure-Bash, beginner-friendly wrapper that gives one install flow (`grab <package>`) across native package managers, Flatpak, and Snap. The target audience is Windows users moving to Linux (see [CONTRIBUTING.md](CONTRIBUTING.md)). It ships a "flavor" called `abora`, a NixOS-based distro where the native path is Nix.

There is no compile step — everything is shell scripts sourced at runtime.

## Commands

```bash
# Full test + build verification (this is the project's "build")
./scripts/e2e-smoke.sh        # syntax checks, local command smoke, fresh + flavored install smoke

# What CI runs (.github/workflows/ci-shell.yml) — run these before pushing:
bash -n ./grab ./tinypm ./syspm.sh ./version ./install.sh ./uninstall.sh \
        ./scripts/install.sh ./scripts/uninstall.sh ./lib/core/*.sh ./lib/providers/*.sh
shellcheck -x -e SC1090 -e SC1091 ./grab ./tinypm ./syspm.sh ./version ./install.sh \
        ./uninstall.sh ./scripts/*.sh ./lib/core/*.sh ./lib/providers/*.sh

# Install into a throwaway HOME (never pollutes your real environment)
tmp="$(mktemp -d)"
HOME="$tmp/h" XDG_CONFIG_HOME="$tmp/h/.config" TINYPM_PREFIX="$tmp/h/.tinypm" \
  bash -c 'mkdir -p "$HOME"; ./install.sh --native pacman -y; "$HOME/.local/bin/grab" help'

# Force a flavor
TINYPM_FLAVOR=abora ./install.sh
```

There is no single-test runner; `scripts/e2e-smoke.sh` is the whole suite. A second CI job (`ci-distro-matrix.yml`) runs the same smoke script inside ubuntu/fedora/arch/alpine/opensuse containers.

## Architecture

### One engine, many command names (multicall dispatch)

Every user-facing command resolves to the single [tinypm](tinypm) script. Alternate names (`grab`, `grab-add-repo`, `grab-de`, `tiny`, `search`, `term`, `start`, `supdate`) are **symlinks to `tinypm`** plus standalone entrypoint scripts (`grab`, `grab-add-repo`, `grab-de`) that `export TINYPM_ENTRYPOINT=<name>` then `exec tinypm`.

`tinypm` derives `prog_name="${TINYPM_ENTRYPOINT:-$(basename "$0")}"` and [lib/core/args.sh](lib/core/args.sh) `init_cli_context` maps `prog_name` → an `action` (e.g. `grab`→`install`, `grab-de`→`de`). `dispatch_multicall` covers the symlink-only names. So a command name is wired in **three** places: the entrypoint/symlink, `init_cli_context`, and `dispatch_multicall`.

### Module load order matters

[tinypm](tinypm) sources modules in a fixed order; later modules call functions from earlier ones. Providers (`lib/providers/*.sh`) must load before `lib/core/actions.sh` (which orchestrates them). When adding a provider module, insert it into that `for module in …` list.

### The backend abstraction (read before touching anything that runs a command)

All external commands go through helpers in [lib/core/common.sh](lib/core/common.sh) — never call `apt-get`/`pacman`/`flatpak` directly:

- `backend_run …` — run a command (read-only / unprivileged).
- `backend_run_root …` — run privileged; auto-selects `pkexec` (if graphical) → `sudo` → direct.
- `backend_has_cmd <cmd>` — availability check.

These transparently route through `flatpak-spawn --host` when TinyPM itself runs inside a Flatpak sandbox (`use_host_backend`). Bypassing them breaks the sandbox and the auth-mode logic.

### Native package manager abstraction

`detect_native_pm` picks one of `apt dnf pacman xbps zypper apk emerge brew nix` (preferring Nix on NixOS, honoring a configured override). [lib/providers/apt.sh](lib/providers/apt.sh) is misleadingly named — it handles **all** native PMs via `case "$pm"`, not just apt. Anything that maps a logical concept to a per-PM command (install, repo add, desktop env) follows this same `case "$pm" in apt) … pacman) … nix) …` pattern.

`provider` flows through every action as `auto` (detect), `native`/a specific PM, `flatpak`, or `snap`. Empty string is treated as `auto` downstream via `${var:-auto}` — this is intentional and matches how no-flag invocations parse.

### Providers and actions

- `lib/providers/` — `apt.sh` (all native PMs), `flatpak.sh`, `snap.sh`, `repo.sh` (`grab-add-repo`), `de.sh` (`grab-de` desktop environments).
- [lib/core/actions.sh](lib/core/actions.sh) — high-level orchestrators (`install_pkg`, `add_repo`, `install_de`, …) that resolve a provider then dispatch to the right provider function. `tinypm`'s top-level `case "$action"` calls these.

### Flavors

A flavor lives in `flavors/<name>/` (`flavor.conf`, `logo.txt`, `catalog.tsv`) and overrides system/engine names, tagline, logo, and catalog. Selected via `TINYPM_FLAVOR` env or the `tinypm_flavor` config key. `tinypm_flavor_file` resolves a path with fallback to `share/`. The installer bakes the chosen flavor's logo/catalog into the install.

### The spinner contract (a known footgun)

`run_with_spinner "<msg>" <fn-or-cmd> <args…>` in [lib/core/ui.sh](lib/core/ui.sh) runs work behind [_spinner](_spinner). If the first arg is a declared function, it `export -f`s all functions and re-invokes inside `bash -lc` so the function (and `backend_run_root`) survive the subshell. `native_run_with_error <pm> <label> run_with_spinner …` adds `|| die` on failure. The spinner **must** propagate the wrapped command's exit code (it previously masked failures because `$?` resets to 0 after an `if … fi` with no `else` branch) — keep status capture inside an `else` branch.

## Adding a new command/entrypoint (checklist)

Driven by how `grab-add-repo` and `grab-de` were added:

1. Create the entrypoint script at repo root (copy `grab-de`; set `TINYPM_ENTRYPOINT`), `chmod +x`.
2. Wire `prog_name` → action in `init_cli_context` and `dispatch_multicall` ([lib/core/args.sh](lib/core/args.sh)); add an arg-parse `case` for the action.
3. Add the `case "$action"` branch in [tinypm](tinypm) and (if it needs a new module) add it to the module load list before `actions.sh`.
4. Implement the orchestrator (in `actions.sh` or a new `lib/providers/<x>.sh`) using the `case "$pm"` pattern and the `backend_*` helpers.
5. Create the launcher symlinks in **both** `BIN_DIR` and `LOCAL_BIN` in [scripts/install.sh](scripts/install.sh), and in `doctor_fix_runtime` + the doctor report in [lib/core/doctor.sh](lib/core/doctor.sh).
6. Update usage in [lib/core/ui.sh](lib/core/ui.sh), and add the entrypoint to the `bash -n`/shellcheck lists and smoke calls in [scripts/e2e-smoke.sh](scripts/e2e-smoke.sh) (and `.github/workflows/ci-shell.yml`).

Forgetting step 5 is the usual cause of "command not found" after install.

## NixOS / Abora specifics

- A package install on Nix maps to `nix-env`; a **repo** maps to a Nix channel; a **desktop environment** is *declarative* — `grab-de` prints the `configuration.nix` lines + `nixos-rebuild switch` rather than installing, because `nix-env` would only drop binaries without a working session.
- PPAs (`ppa:…`) are apt-only; `grab-add-repo` rejects them on Nix with a hint to pass a channel URL.

## Conventions

- Error out with `die "<msg>"` (prints `Parcel: <msg>` to stderr, exits 1). User-facing strings say "Parcel".
- Scripts run under `set -euo pipefail`; library modules carry `# shellcheck disable=SC2034,SC2154` because variables like `script_dir`, `action`, `provider` are set by the sourcing entrypoint.
- The installer is idempotent and links commands into `~/.local/bin` (prefix overridable via `TINYPM_PREFIX`). `tinypm doctor --fix` re-creates launchers/PATH without a full reinstall.
