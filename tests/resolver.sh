#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tinypm="$repo_root/src/bin/tinypm"
grab="$repo_root/src/bin/grab"
alias_file="$repo_root/src/share/tinypm/aliases.tsv"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

fake_bin="$test_root/bin"
mkdir -p "$fake_bin" "$test_root/home"
for command in apt-get dnf pacman zypper apk swupd flatpak snap; do
    printf '#!/usr/bin/env bash\nexit 0\n' >"$fake_bin/$command"
    chmod +x "$fake_bin/$command"
done
cat >"$fake_bin/pacman" <<'EOF'
#!/usr/bin/env bash
if [[ "${1:-}" == "-Si" ]]; then
    printf 'Name            : %s\n' "${2:-unknown}"
    printf 'Description     : GNU Compiler Collection\n'
fi
exit 0
EOF
chmod +x "$fake_bin/pacman"

export HOME="$test_root/home"
export XDG_CONFIG_HOME="$HOME/.config"
export XDG_STATE_HOME="$HOME/.local/state"
export PATH="$fake_bin:$PATH"
export NO_COLOR=1

fail() {
    printf '[resolver] FAIL: %s\n' "$*" >&2
    exit 1
}

assert_contains() {
    local output="$1" expected="$2"
    grep -Fq "$expected" <<<"$output" || fail "expected output to contain: $expected"
}

awk -F '\t' '
    /^#/ || NF == 0 { next }
    NF < 4 { bad=1; print "invalid alias row: " $0 > "/dev/stderr" }
    { key=$1 SUBSEP $2; if (seen[key]++) { bad=1; print "duplicate alias: " $1 ":" $2 > "/dev/stderr" } }
    END { exit bad }
' "$alias_file" || fail 'alias catalog validation failed'

output="$($grab explain --pacman gcc++)"
assert_contains "$output" 'Resolved      gcc'
assert_contains "$output" 'Provider      Pacman'
assert_contains "$output" 'Command       pacman -S --noconfirm gcc'
assert_contains "$output" 'Description   GNU Compiler Collection'
assert_contains "$output" 'Arch provides GCC and G++ together'

output="$($grab explain gcc++ --dnf)"
assert_contains "$output" 'Resolved      gcc-c++'
assert_contains "$output" 'Command       dnf install -y gcc-c++'

output="$($tinypm explain --apk gcc++)"
assert_contains "$output" 'Resolved      g++'
assert_contains "$output" 'Command       apk add g++'

output="$($grab explain --swupd gcc)"
assert_contains "$output" 'Resolved      c-basic'
assert_contains "$output" 'Command       swupd bundle-add c-basic'

output="$($grab explain --apk curl)"
assert_contains "$output" 'Resolved      curl'
assert_contains "$output" 'No alias is needed'

output="$($grab explain --flatpak org.mozilla.firefox)"
assert_contains "$output" 'Command       flatpak install -y org.mozilla.firefox'

"$grab" help | grep -Fq 'explain' || fail 'grab help does not advertise explain'
printf '[resolver] PASS\n'
