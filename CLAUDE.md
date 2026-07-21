# TinyPM V4 development guide

TinyPM is a pure-Bash, beginner-friendly package wrapper. V4 has one runtime
and no separate engine layer. The public install-first command is `grab`; the
complete CLI is `tinypm`.

## Verification

```bash
./scripts/build.sh
./scripts/e2e-smoke.sh
```

CI additionally runs ShellCheck and executes the smoke suite in Ubuntu,
Fedora, Arch, Alpine, and openSUSE containers.

## Architecture

- `src/bin/tinypm` sources modules in order and dispatches the parsed action.
- `src/lib/tinypm/core/args.sh` implements multicall behavior.
- `src/lib/tinypm/core/actions.sh` orchestrates providers and state/history.
- `src/lib/tinypm/providers/native.sh` is the native implementation.
- Every external backend call goes through `backend_run`, `backend_exec`, or
  `backend_run_root` so host/Flatpak and authentication behavior stays intact.
- `src/lib/tinypm/core/inspect.sh` implements checks and dry-run plans.
- `scripts/build.sh` stages a validated runtime under `build/tinypm-v4/`.

## Important behavior

- `grab firefox` installs, while reserved command words dispatch normally:
  `grab update`, `grab search firefox`, and `grab remove firefox`.
- Provider values flow as `auto`, `flatpak`, `snap`, `native`, or a specific
  supported native manager. Keep manager lists synchronized across common,
  native, inspect, installer, UI, and tests.
- Adding a repository refreshes metadata with `native_refresh`; it must never
  perform a full package upgrade.
- APK repository additions support optional tags and must remain idempotent.
- Color follows `NO_COLOR` and `FORCE_COLOR`. Non-interactive commands bypass
  the spinner; `TINYPM_NO_SPINNER=1` forces that behavior.
- NixOS desktop environments are declarative. Abora uses ANIX when available.

## Adding a command

Wire its launcher/multicall name in `src/lib/tinypm/core/args.sh`, add its case
in `src/bin/tinypm`, implement orchestration under core, update installer and
doctor launchers if needed, then extend `scripts/e2e-smoke.sh`.

Keep output beginner-friendly, shell code readable, and backend operations
behind the shared helpers.
