#!/usr/bin/env bash
set -euo pipefail

script_path="${BASH_SOURCE[0]}"
while [[ -L "$script_path" ]]; do
    script_parent="$(cd -P "$(dirname "$script_path")" && pwd)"
    script_target="$(readlink "$script_path")"
    [[ "$script_target" == /* ]] && script_path="$script_target" || script_path="$script_parent/$script_target"
done
repo_root="$(cd "$(dirname "$script_path")/.." && pwd)"
source_root="$repo_root/src"
build_root="$repo_root/build"
artifact_name="tinypm-v4"

usage() {
    cat <<'EOF'
Build TinyPM V4 into a self-contained runtime.

Usage:
  ./scripts/build.sh
  ./scripts/build.sh --output <directory>
  ./scripts/build.sh --clean

Commands are written to build/tinypm-v4/bin/.
EOF
}

clean_only=0
while [[ $# -gt 0 ]]; do
    case "$1" in
        --output)
            shift
            [[ $# -gt 0 ]] || { printf 'build: --output needs a directory\n' >&2; exit 2; }
            build_root="$1"
            shift
            ;;
        --clean) clean_only=1; shift ;;
        -h|--help) usage; exit 0 ;;
        *) printf 'build: unknown option: %s\n' "$1" >&2; usage >&2; exit 2 ;;
    esac
done

mkdir -p "$build_root"
build_root="$(cd "$build_root" && pwd -P)"
case "$build_root" in
    /|"$HOME"|"$repo_root")
        printf 'build: refusing unsafe output directory: %s\n' "$build_root" >&2
        exit 2
        ;;
esac

stage="$build_root/$artifact_name"
archive="$build_root/$artifact_name.tar.gz"

if [[ "$clean_only" -eq 1 ]]; then
    rm -rf "$stage"
    rm -f "$archive" "$build_root/SHA256SUMS"
    printf '[ok] Removed TinyPM build artifacts from %s\n' "$build_root"
    exit 0
fi

printf '==> Checking shell syntax\n'
bash -n \
    "$repo_root/scripts/"*.sh \
    "$repo_root/tests/"*.sh \
    "$source_root/bin/"* \
    "$source_root/lib/tinypm/core/"*.sh \
    "$source_root/lib/tinypm/providers/"*.sh

temp_root="$(mktemp -d "${TMPDIR:-/tmp}/tinypm-build.XXXXXX")"
trap 'rm -rf "$temp_root"' EXIT
temp_stage="$temp_root/$artifact_name"
mkdir -p "$temp_stage/bin" "$temp_stage/lib/tinypm" "$temp_stage/share/tinypm" "$temp_stage/scripts"

printf '==> Staging runtime\n'
cp "$source_root/bin/tinypm" "$source_root/bin/syspm" "$temp_stage/bin/"
cp -R "$source_root/lib/tinypm/." "$temp_stage/lib/tinypm/"
cp "$source_root/share/tinypm/catalog.tsv" "$source_root/share/tinypm/aliases.tsv" \
    "$source_root/share/tinypm/logo.txt" "$temp_stage/share/tinypm/"
cp -R "$source_root/share/tinypm/flavors" "$temp_stage/share/tinypm/"
cp -R "$source_root/share/tinypm/completions" "$temp_stage/share/tinypm/"
cp "$repo_root/scripts/install.sh" "$repo_root/scripts/uninstall.sh" "$temp_stage/scripts/"
cp "$repo_root/LICENSE" "$repo_root/README.md" "$temp_stage/"

chmod +x "$temp_stage/bin/tinypm" "$temp_stage/bin/syspm" "$temp_stage/scripts/"*.sh
for command in tiny grab grab-add-repo grab-de; do
    ln -s tinypm "$temp_stage/bin/$command"
done

cat >"$temp_stage/BUILD-INFO" <<EOF
name=TinyPM V4
version=4.0.0
built_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

rm -rf "$stage"
mv "$temp_stage" "$stage"

printf '==> Verifying runnable build\n'
NO_COLOR=1 "$stage/bin/tinypm" help >/dev/null
NO_COLOR=1 "$stage/bin/grab" --version >/dev/null
NO_COLOR=1 "$stage/bin/grab-add-repo" help >/dev/null
NO_COLOR=1 "$stage/bin/tinypm" selftest >/dev/null

printf '==> Creating release archive\n'
rm -f "$archive"
if command -v tar >/dev/null 2>&1; then
    tar -C "$build_root" -czf "$archive" "$artifact_name"
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$build_root" && sha256sum "$(basename "$archive")" >SHA256SUMS)
    fi
else
    rm -f "$build_root/SHA256SUMS"
    printf '[warn] tar is unavailable; the runnable folder is complete but no archive was created.\n' >&2
fi

printf '[ok] Build ready: %s\n' "$stage"
printf '[ok] Commands:    %s/bin\n' "$stage"
printf '[ok] Try:         %s/bin/grab --dry-run curl\n' "$stage"
