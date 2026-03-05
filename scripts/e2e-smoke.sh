#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '[e2e] syntax checks...\n'
bash -n \
  "$repo_root/tinypm" \
  "$repo_root/seed" \
  "$repo_root/syspm.sh" \
  "$repo_root/tinypm-app" \
  "$repo_root/version" \
  "$repo_root/install.sh" \
  "$repo_root/uninstall.sh" \
  "$repo_root/scripts/install.sh" \
  "$repo_root/scripts/uninstall.sh" \
  "$repo_root/lib/core/"*.sh \
  "$repo_root/lib/providers/"*.sh

printf '[e2e] local command smoke...\n'
"$repo_root/tinypm" help >/dev/null
"$repo_root/tinypm" doctor >/dev/null
"$repo_root/seed" help >/dev/null
"$repo_root/seed" search yq | grep -qi 'yq'
"$repo_root/tinypm" search --seed yq | grep -qi 'yq'
"$repo_root/version" >/dev/null
version_output="$(mktemp)"
TINYPM_FLAVOR=abora "$repo_root/version" >"$version_output"
grep -q 'TinyPM.2.0.2.Aedition (abora)' "$version_output"
rm -f "$version_output"
TINYPM_FLAVOR=abora "$repo_root/seed" store blender | grep -q 'Blender'
"$repo_root/syspm.sh" help >/dev/null

printf '[e2e] fresh install smoke...\n'
tmp_root="$(mktemp -d)"
cleanup() {
  rm -rf "$tmp_root"
}
trap cleanup EXIT

export HOME="$tmp_root/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
export TINYPM_PREFIX="$HOME/.tinypm"

mkdir -p "$HOME"

printf '1\n' | "$repo_root/install.sh" >/dev/null

"$HOME/.local/bin/tinypm" help >/dev/null
"$HOME/.local/bin/tiny" --version >/dev/null
"$HOME/.local/bin/seed" help >/dev/null
"$HOME/.local/bin/syspm" help >/dev/null
"$HOME/.local/bin/tinypm" doctor --fix >/dev/null

printf '[e2e] flavored install smoke...\n'
rm -rf "$HOME/.tinypm" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/tinypm"
mkdir -p "$HOME/.local/bin"
printf '1\n' | TINYPM_FLAVOR=abora "$repo_root/install.sh" >/dev/null
installed_version_output="$(mktemp)"
"$HOME/.local/bin/tiny" --version >"$installed_version_output"
grep -q 'TinyPM.2.0.2.Aedition (abora)' "$installed_version_output"
rm -f "$installed_version_output"
"$HOME/.local/bin/seed" store blender | grep -q 'Blender'

printf '[e2e] PASS\n'
