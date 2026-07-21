#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="$repo_root/src"
tmp_root="$(mktemp -d)"
cleanup() {
    rm -rf "$tmp_root"
}
trap cleanup EXIT

printf '[e2e] syntax checks...\n'
bash -n \
    "$repo_root/build.sh" \
    "$repo_root/install.sh" \
    "$repo_root/scripts/"*.sh \
    "$source_root/bin/"* \
    "$source_root/lib/tinypm/core/"*.sh \
    "$source_root/lib/tinypm/providers/"*.sh

printf '[e2e] focused resolver tests...\n'
"$repo_root/tests/resolver.sh" >/dev/null

printf '[e2e] local command smoke...\n'
NO_COLOR=1 "$source_root/bin/tinypm" help >/dev/null
NO_COLOR=1 "$source_root/bin/tinypm" doctor >/dev/null
NO_COLOR=1 "$source_root/bin/tinypm" check __tinypm_missing_package__ >/dev/null
NO_COLOR=1 "$source_root/bin/grab" --version >/dev/null
NO_COLOR=1 "$source_root/bin/grab-add-repo" help >/dev/null
NO_COLOR=1 "$source_root/bin/grab-de" help >/dev/null
NO_COLOR=1 "$source_root/bin/tinypm" bundle list >/dev/null
NO_COLOR=1 "$source_root/bin/tinypm" history 10 >/dev/null
NO_COLOR=1 "$source_root/bin/tinypm" pinned >/dev/null
NO_COLOR=1 "$source_root/bin/tinypm" version >/dev/null
NO_COLOR=1 "$source_root/bin/syspm" help >/dev/null

version_output="$tmp_root/version"
TINYPM_FLAVOR=abora NO_COLOR=1 "$source_root/bin/tinypm" version >"$version_output"
grep -q 'Abora TinyPM V4 v4.0.0' "$version_output"
if grep -Eq 'Forge|Parcel' "$version_output"; then
    printf 'legacy engine name leaked into version output\n' >&2
    exit 1
fi

color_output="$tmp_root/color"
plain_output="$tmp_root/plain"
NO_COLOR='' FORCE_COLOR=1 "$source_root/bin/tinypm" help >"$color_output"
NO_COLOR=1 FORCE_COLOR=1 "$source_root/bin/tinypm" help >"$plain_output"
grep -Fq $'\033[' "$color_output"
if grep -Fq $'\033[' "$plain_output"; then
    printf 'NO_COLOR output contains ANSI escapes\n' >&2
    exit 1
fi

printf '[e2e] build smoke...\n'
"$repo_root/build.sh" >/dev/null
test -x "$repo_root/build/tinypm-v4/bin/tinypm"
test -x "$repo_root/build/tinypm-v4/bin/grab"
test -f "$repo_root/build/tinypm-v4.tar.gz"
test -f "$repo_root/build/tinypm-v4/share/tinypm/completions/tinypm.bash"
test -f "$repo_root/build/tinypm-v4/share/tinypm/completions/_tinypm"
test -f "$repo_root/build/tinypm-v4/share/tinypm/completions/tinypm.fish"
NO_COLOR=1 "$repo_root/build/tinypm-v4/bin/tinypm" help >/dev/null
NO_COLOR=1 "$repo_root/build/tinypm-v4/bin/grab" --dry-run --apk curl >/dev/null
NO_COLOR=1 "$repo_root/build/tinypm-v4/bin/grab" explain --apk gcc++ | grep -F 'Resolved      g++' >/dev/null

build_home="$tmp_root/build-home"
HOME="$build_home" XDG_CONFIG_HOME="$build_home/.config" \
    XDG_DATA_HOME="$build_home/.local/share" TINYPM_PREFIX="$build_home/.tinypm" \
    "$repo_root/build/tinypm-v4/scripts/install.sh" --native apk -y >/dev/null
NO_COLOR=1 HOME="$build_home" XDG_CONFIG_HOME="$build_home/.config" \
    "$build_home/.local/bin/tinypm" help >/dev/null
test -L "$build_home/.local/share/bash-completion/completions/grab"
test -L "$build_home/.local/share/zsh/site-functions/_tinypm"
test -L "$build_home/.config/fish/completions/grab.fish"

# Bash completion offers commands and exact provider flags without invoking a
# package manager or network search.
completion_output="$tmp_root/completion"
bash -c 'source "$1"; COMP_WORDS=(grab ex); COMP_CWORD=1; _tinypm_complete; printf "%s\n" "${COMPREPLY[@]}"' \
    bash "$repo_root/build/tinypm-v4/share/tinypm/completions/tinypm.bash" >"$completion_output"
grep -qx 'explain' "$completion_output"

# Uninstall removes the shell metadata as well as the launchers.
HOME="$build_home" XDG_CONFIG_HOME="$build_home/.config" \
    XDG_DATA_HOME="$build_home/.local/share" TINYPM_PREFIX="$build_home/.tinypm" \
    "$repo_root/build/tinypm-v4/scripts/uninstall.sh" >/dev/null
test ! -e "$build_home/.local/share/bash-completion/completions/grab"
test ! -e "$build_home/.local/share/zsh/site-functions/_tinypm"
test ! -e "$build_home/.config/fish/completions/grab.fish"

printf '[e2e] fake Alpine/APK command smoke...\n'
fake_bin="$tmp_root/fake-bin"
apk_log="$tmp_root/apk.log"
repositories_file="$tmp_root/repositories"
native_log="$tmp_root/native.log"
mkdir -p "$fake_bin"
: >"$apk_log"
: >"$repositories_file"
: >"$native_log"

cat >"$fake_bin/apk" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >>"$TINYPM_TEST_APK_LOG"
case "${1:-}" in
    info)
        [[ "${2:-}" != "-e" ]]
        ;;
    *) exit 0 ;;
esac
EOF
cat >"$fake_bin/sudo" <<'EOF'
#!/usr/bin/env bash
exec "$@"
EOF
cp "$fake_bin/sudo" "$fake_bin/pkexec"
chmod +x "$fake_bin/apk" "$fake_bin/sudo" "$fake_bin/pkexec"

cat >"$fake_bin/native-stub" <<'EOF'
#!/usr/bin/env bash
printf '%s %s\n' "$(basename "$0")" "$*" >>"$TINYPM_TEST_NATIVE_LOG"
EOF
chmod +x "$fake_bin/native-stub"
for fake_command in dnf zypper eopkg swupd slackpkg opkg urpmi urpme urpmi.update urpmq guix; do
    ln -s native-stub "$fake_bin/$fake_command"
done
cat >"$fake_bin/pacman" <<'EOF'
#!/usr/bin/env bash
printf 'pacman %s\n' "$*" >>"$TINYPM_TEST_NATIVE_LOG"
if [[ "${1:-}" == "-Q" ]]; then
    [[ "${2:-}" == "installed-package" ]]
    exit
fi
[[ " $* " != *' missing-package '* ]]
EOF
chmod +x "$fake_bin/pacman"

export HOME="$tmp_root/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export XDG_DATA_HOME="$HOME/.local/share"
export TINYPM_PREFIX="$HOME/.tinypm"
export TINYPM_TEST_APK_LOG="$apk_log"
export TINYPM_TEST_NATIVE_LOG="$native_log"
export TINYPM_APK_REPOSITORIES_FILE="$repositories_file"
export TINYPM_NO_SPINNER=1
export PATH="$fake_bin:$PATH"
mkdir -p "$HOME" "$TINYPM_PREFIX/bin/lib/core" "$TINYPM_PREFIX/bin/lib/providers" "$HOME/.local/bin"

# An upgrade must remove the obsolete V3/engine layer from an old install.
touch "$TINYPM_PREFIX/bin/Forge" "$TINYPM_PREFIX/bin/Parcel"
touch "$TINYPM_PREFIX/bin/lib/core/forge.sh" "$TINYPM_PREFIX/bin/lib/providers/apt.sh"
ln -s "$TINYPM_PREFIX/bin/Forge" "$HOME/.local/bin/Forge"
ln -s "$TINYPM_PREFIX/bin/Parcel" "$HOME/.local/bin/Parcel"

"$repo_root/scripts/install.sh" --native apk -y >/dev/null
[[ ! -e "$TINYPM_PREFIX/bin/Forge" && ! -e "$TINYPM_PREFIX/bin/Parcel" ]]
[[ ! -e "$TINYPM_PREFIX/bin/lib/core/forge.sh" && ! -e "$TINYPM_PREFIX/bin/lib/providers/apt.sh" ]]

NO_COLOR=1 "$HOME/.local/bin/tinypm" help >/dev/null
NO_COLOR=1 "$HOME/.local/bin/tiny" --version >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" help >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" explain --apk gcc++ | grep -F 'Resolved      g++' >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab-de" help >/dev/null
NO_COLOR=1 "$HOME/.local/bin/syspm" help >/dev/null
NO_COLOR=1 "$HOME/.local/bin/tinypm" doctor --fix >/dev/null

# grab is install-first, but command words must dispatch as real subcommands.
NO_COLOR=1 "$HOME/.local/bin/grab" search --apk yq >/dev/null
grep -qx 'search yq' "$apk_log"
NO_COLOR=1 "$HOME/.local/bin/grab" update --apk >/dev/null
grep -qx 'update' "$apk_log"
grep -qx 'upgrade' "$apk_log"

# Common command typos must never become accidental package installations.
typo_output="$tmp_root/typo-output"
before_lines="$(wc -l <"$apk_log")"
if NO_COLOR=1 "$HOME/.local/bin/grab" udpate --apk >"$typo_output" 2>&1; then
    printf 'misspelled command returned success\n' >&2
    exit 1
fi
grep -Fq 'Did you mean: grab update --apk' "$typo_output"
after_lines="$(wc -l <"$apk_log")"
[[ "$before_lines" -eq "$after_lines" ]]

# Double-dash deliberately bypasses typo protection for a literal package.
NO_COLOR=1 "$HOME/.local/bin/grab" -- udpate --apk >/dev/null
grep -qx 'add udpate' "$apk_log"

# A dry run must not call apk add; a real grab must.
before_lines="$(wc -l <"$apk_log")"
NO_COLOR=1 "$HOME/.local/bin/grab" --dry-run --apk curl >/dev/null
after_lines="$(wc -l <"$apk_log")"
[[ "$before_lines" -eq "$after_lines" ]]
NO_COLOR=1 "$HOME/.local/bin/grab" --apk curl >/dev/null
grep -qx 'add curl' "$apk_log"

# Less common but supported native families still receive exact commands.
NO_COLOR=1 "$HOME/.local/bin/grab" --eopkg demo >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" --swupd demo >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" --slackpkg demo >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" --opkg demo >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" --urpmi demo >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" --guix demo >/dev/null
grep -qx 'eopkg install -y demo' "$native_log"
grep -qx 'swupd bundle-add demo' "$native_log"
grep -qx 'slackpkg -batch=on -default_answer=y install demo' "$native_log"
grep -qx 'opkg install demo' "$native_log"
grep -qx 'urpmi --auto demo' "$native_log"
grep -qx 'guix install demo' "$native_log"

# Friendly compiler names map per distro and duplicate providers are skipped.
compiler_output="$tmp_root/compiler-output"
NO_COLOR=1 "$HOME/.local/bin/grab" --pacman gcc gcc++ >"$compiler_output" 2>&1
[[ "$(grep -Fxc 'pacman -S --noconfirm gcc' "$native_log")" -eq 1 ]]
grep -Fq '1 installed, 1 duplicate' "$compiler_output"
NO_COLOR=1 "$HOME/.local/bin/grab" --dnf gcc++ >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" --zypper gcc++ >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab" --apk gcc++ >/dev/null
grep -qx 'dnf install -y gcc-c++' "$native_log"
grep -qx 'zypper --non-interactive install gcc-c++' "$native_log"
grep -qx 'add g++' "$apk_log"

# Already-installed packages are not needlessly sent through a reinstall.
installed_output="$tmp_root/installed-output"
NO_COLOR=1 "$HOME/.local/bin/grab" --pacman installed-package >"$installed_output"
grep -Fq 'already installed' "$installed_output"
grep -Fq '0 installed, 1 already installed' "$installed_output"
if grep -qx 'pacman -S --noconfirm installed-package' "$native_log"; then
    printf 'already-installed package was reinstalled\n' >&2
    exit 1
fi

# Provider failures must reach the caller and must never be recorded as success.
if NO_COLOR=1 "$HOME/.local/bin/grab" --pacman missing-package >/dev/null 2>&1; then
    printf 'failed provider command returned success\n' >&2
    exit 1
fi
if NO_COLOR=1 "$HOME/.local/bin/tinypm" managed | grep -Fq 'missing-package'; then
    printf 'failed package was recorded as managed\n' >&2
    exit 1
fi

# Removal also continues after a failure and reports only real successes.
remove_output="$tmp_root/remove-output"
if NO_COLOR=1 "$HOME/.local/bin/grab" remove --pacman missing-package gcc gcc++ >"$remove_output" 2>&1; then
    printf 'partially failed removal returned success\n' >&2
    exit 1
fi
grep -Fq '1 removed, 1 already covered, 1 failed' "$remove_output"
grep -qx 'pacman -Rns --noconfirm gcc' "$native_log"

# Undo previews the last reversible history item and requires explicit consent.
mkdir -p "$XDG_STATE_HOME/tinypm"
printf '2026-07-18T12:00:00-04:00\tinstall\tundo-package\tpacman\n' \
    >"$XDG_STATE_HOME/tinypm/history.log"
undo_output="$tmp_root/undo-output"
before_lines="$(wc -l <"$native_log")"
NO_COLOR=1 "$HOME/.local/bin/grab" undo >"$undo_output"
grep -Fq 'Will perform  remove undo-package' "$undo_output"
grep -Fq 'No changes made' "$undo_output"
after_lines="$(wc -l <"$native_log")"
[[ "$before_lines" -eq "$after_lines" ]]
NO_COLOR=1 "$HOME/.local/bin/grab" undo --yes >>"$undo_output"
grep -qx 'pacman -Rns --noconfirm undo-package' "$native_log"
grep -Fq 'Undid install of undo-package' "$undo_output"

NO_COLOR=1 "$HOME/.local/bin/grab" update --opkg >/dev/null 2>/dev/null
grep -qx 'opkg update' "$native_log"
if grep -qx 'opkg upgrade' "$native_log"; then
    printf 'unsafe mass opkg upgrade was attempted\n' >&2
    exit 1
fi

# APK repo tags work, duplicate additions are idempotent, and metadata refreshes.
repo_url='https://dl-cdn.alpinelinux.org/alpine/edge/community'
NO_COLOR=1 "$HOME/.local/bin/grab-add-repo" --apk "$repo_url" edge >/dev/null
NO_COLOR=1 "$HOME/.local/bin/grab-add-repo" --apk "$repo_url" edge >/dev/null
grep -Fqx "@edge $repo_url" "$repositories_file"
[[ "$(grep -Fxc "@edge $repo_url" "$repositories_file")" -eq 1 ]]

printf '[e2e] flavored install smoke...\n'
rm -rf "$HOME/.tinypm" "$HOME/.local/bin" "$HOME/.local/share/applications" "$HOME/.config/tinypm"
mkdir -p "$HOME/.local/bin"
TINYPM_FLAVOR=abora "$repo_root/scripts/install.sh" --native apk -y >/dev/null
NO_COLOR=1 "$HOME/.local/bin/tiny" --version >"$version_output"
grep -q 'Abora TinyPM V4 v4.0.0' "$version_output"
if [[ -e "$HOME/.local/bin/Forge" || -e "$HOME/.local/bin/Parcel" ]]; then
    printf 'legacy engine launcher was installed\n' >&2
    exit 1
fi

printf '[e2e] PASS\n'
