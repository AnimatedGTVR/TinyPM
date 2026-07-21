<p align="center">
  <img src="src/share/tinypm/assets/TinyLogo.png" alt="TinyPM V4 Logo" width="500"/>
</p>

<h1 align="center">TinyPM V4</h1>

<p align="center">
  One friendly package command across mainstream Linux families.
</p>

TinyPM is a pure-Bash package-manager wrapper. V4 has one CLI and one runtime:
there is no separate engine process or legacy V3 compatibility layer.

## Quick start

The two obvious scripts in the repository root are the intended entrypoints:

```bash
./build.sh
./install.sh
grab --dry-run curl
```

They are lightweight links to the organized implementations in `scripts/`, so
there is still only one build script and one installer to maintain.

```bash
grab firefox vlc gimp
grab search firefox
grab update
grab remove firefox
```

## Build

TinyPM has no compilation step, but release builds are validated and staged as
self-contained runnable distributions:

```bash
./build.sh
./build/tinypm-v4/bin/tinypm help
./build/tinypm-v4/bin/grab --dry-run curl
```

The build produces:

```text
build/
├── tinypm-v4/
│   ├── bin/            user commands
│   ├── lib/tinypm/     internal runtime
│   ├── share/tinypm/   catalog, flavors, assets
│   └── scripts/        install/uninstall tools
├── tinypm-v4.tar.gz    release archive
└── SHA256SUMS           archive checksum
```

The runnable folder only requires Bash and standard Unix utilities. The
compressed archive and checksum are created when `tar` and `sha256sum` are
available.

Use `./build.sh --clean` to remove generated artifacts, or
`./build.sh --output <directory>` to choose another output directory.

## Install

```bash
./install.sh
export PATH="$HOME/.local/bin:$PATH"
grab firefox
```

The installer places the runtime in `~/.tinypm/bin` and launchers in
`~/.local/bin`. It detects the native package manager automatically. Override
it for a specific system or image:

```bash
./install.sh --native apk -y
TINYPM_FLAVOR=abora ./install.sh --native nix -y
```

Tab completion is installed automatically for Bash, Zsh, and Fish. Open a new
shell after installation, then try `grab ex<Tab>` or `grab --pa<Tab>`.

## Commands

`grab` is install-first but also accepts TinyPM subcommands:

```bash
grab <package...>                  # install
grab -- <package...>               # force literal package names
grab install <package...>          # explicit install
grab --dry-run <package...>        # preview an install
grab search <query>
grab remove <package...>
grab update
grab list
grab info <package>
grab check <package>
grab explain <package>
grab undo                            # preview the last reversal
grab undo --yes                      # perform it
grab doctor
```

Friendly package aliases are translated for the selected distro. For example,
`gcc++` and `g++` resolve to `gcc` on Arch, `g++` on Debian/Alpine, and
`gcc-c++` on Fedora/openSUSE. If two names resolve to the same package in one
batch, TinyPM installs it once and reports the duplicate separately.
Packages that are already installed are detected before the transaction, so
TinyPM does not ask the native manager to reinstall them.

Common command typos are rejected before a provider is called. For example,
`grab udpate` suggests `grab update` instead of trying to install a package
named `udpate`. Use `grab -- udpate` when that package name is intentional.

Interactive installs use a colored Pac-Man chase animation. Redirected output
and CI remain plain and stable.

Use `explain` to inspect resolution without changing the system:

```text
$ grab explain --pacman gcc++
Package resolution
  Requested     gcc++
  Resolved      gcc
  Provider      Pacman
  Description   The GNU Compiler Collection - C and C++ frontends
  Reason        Arch provides GCC and G++ together in the gcc package
  Command       pacman -S --noconfirm gcc
```

Friendly names live in `src/share/tinypm/aliases.tsv`, so mappings can be
reviewed and extended without changing provider execution code.

The full CLI exposes package tracking and higher-level workflows:

```bash
tinypm managed
tinypm pin firefox
tinypm unpin firefox
tinypm history 100
tinypm undo
tinypm bundle list
tinypm bundle Gaming
tinypm sync packages.txt
tinypm sync --generate packages.txt
tinypm discover editor
tinypm apps
tinypm doctor --fix
tinypm selftest
```

Provider flags can appear before or after a package where appropriate:

| Flag | Provider |
| --- | --- |
| `-n`, `--native` | detected native package manager |
| `-f`, `-flatpak` | Flatpak |
| `-s`, `--snap` | Snap |
| `--apk` | Alpine APK |
| `--apt` | APT |
| `--dnf` | DNF |
| `--pacman` | Pacman |
| `--xbps` | XBPS |
| `--zypper` | Zypper |
| `--emerge` | Portage |
| `--eopkg` | Solus eopkg |
| `--swupd` | Clear Linux swupd |
| `--slackpkg` | Slackware slackpkg |
| `--opkg` | OpenWrt opkg |
| `--urpmi` | Mageia URPMI |
| `--guix` | GNU Guix |
| `--brew` | Homebrew |
| `--nix` | Nix |

## Alpine Linux

Alpine is a first-class V4 backend:

```bash
./install.sh --native apk -y
grab --apk curl bash git
grab search --apk neovim
grab update --apk
grab remove --apk curl
```

Repository URLs can optionally receive an APK tag. Additions are idempotent
and refresh repository metadata without upgrading the system:

```bash
grab-add-repo --apk \
  https://dl-cdn.alpinelinux.org/alpine/edge/community edge

# writes: @edge https://dl-cdn.alpinelinux.org/alpine/edge/community
grab --apk package@edge
```

## Other repositories

`grab-add-repo` maps the source to the detected native backend:

```bash
grab-add-repo ppa:owner/project                            # APT
grab-add-repo --dnf copr:owner/project                    # DNF COPR
grab-add-repo --pacman 'myrepo=https://example/$arch'     # Pacman
grab-add-repo --nix https://nixos.org/channels/nixos-unstable unstable
grab-add-repo --brew owner/tap
```

Supported repository types include APT repositories and PPAs, DNF repos and
COPR, Zypper repos, APK repositories, Pacman servers, XBPS repos, Homebrew taps,
eopkg repositories, URPMI media, opkg feeds, and Nix channels. Declarative or
specialized source systems such as Guix channels, Portage overlays, swupd
mixers, and slackpkg mirrors receive instructions instead of unsafe edits.

## Distribution coverage

TinyPM detects these native managers:

```text
apt      Debian, Ubuntu, Mint, Pop!_OS, Kali, and derivatives
dnf      Fedora, RHEL, CentOS Stream, Rocky, AlmaLinux
pacman   Arch, Manjaro, EndeavourOS, Garuda, CachyOS
zypper   openSUSE and SUSE
apk      Alpine
xbps     Void Linux
emerge   Gentoo
eopkg    Solus
swupd    Clear Linux
slackpkg Slackware
opkg     OpenWrt 24.10 and older, plus embedded Linux
urpmi    Mageia
guix     GNU Guix System
nix      NixOS and Abora
brew     Linuxbrew and macOS
```

Flatpak and Snap remain optional. TinyPM cannot honestly guarantee every
future or private distribution, but unsupported systems now fail clearly
instead of guessing or running the wrong package manager.

TinyPM refreshes opkg metadata without mass-upgrading OpenWrt. OpenWrt warns
that a blanket `opkg upgrade` can soft-brick devices; newer OpenWrt releases
use the APK backend automatically.

## Desktop environments and Abora

`grab-de` installs supported desktop environments on imperative distributions:

```bash
grab-de gnome       # also plasma, xfce, cosmic
```

NixOS desktop environments are declarative, so TinyPM prints the required
`configuration.nix` settings instead of creating an incomplete `nix-env`
profile. On Abora, TinyPM uses ANIX when it is installed:

```bash
grab firefox        # anix package add firefox; anix apply
grab remove firefox # anix package remove firefox; anix apply
grab-de gnome       # anix set desktop gnome; anix apply
```

Set `TINYPM_NO_ANIX=1` to use the normal Nix path or `TINYPM_ANIX_APPLY=0` to
edit the ANIX configuration without applying it immediately.

## Colors and automation

Color is enabled on interactive terminals. The conventional `NO_COLOR`
environment variable disables it; `FORCE_COLOR=1` enables it for redirected
output. Set `TINYPM_NO_SPINNER=1` for clean automation logs.

## Development

```bash
./build.sh
./scripts/e2e-smoke.sh
shellcheck -x -e SC1090 -e SC1091 \
  scripts/*.sh src/bin/* src/lib/tinypm/core/*.sh \
  src/lib/tinypm/providers/*.sh
```

The smoke suite validates source commands, color behavior, the runnable build,
a clean installation, flavor installation, and install/search/update/repository
flows against a fake Alpine APK backend. CI also runs the suite in Ubuntu,
Fedora, Arch, Alpine, and openSUSE containers.

## Project layout

```text
src/bin/                    source command entrypoints
src/lib/tinypm/core/        parsing, actions, state, history, UI
src/lib/tinypm/providers/   native, Flatpak, Snap, repo, DE, ANIX
src/share/tinypm/           catalogs, flavors, and assets
scripts/build.sh            release builder
scripts/install.sh          local installer
scripts/e2e-smoke.sh        cross-backend smoke suite
tests/resolver.sh            focused alias and resolution tests
build/tinypm-v4/bin/        generated commands for testing/use
build.sh, install.sh         discoverable root links to scripts/
```

TinyPM V4 is licensed under the GNU General Public License v3.0. See
[LICENSE](LICENSE).
