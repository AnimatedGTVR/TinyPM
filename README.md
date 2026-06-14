<p align="center">
  <img src="assets/TinyLogo.png" alt="TinyPM V4 Logo" width="500"/>
</p>

<h1 align="center">TinyPM V4</h1>

<p align="center">
  Powered by <strong>Forge</strong>.<br>
  A beginner-friendly Linux package wrapper for the Abora ecosystem, built on a NixOS base.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-4.0.0-blue.svg" alt="v4.0.0"/>
  <img src="https://img.shields.io/badge/engine-Forge-1f6feb.svg" alt="Forge"/>
  <img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="GPLv3"/>
  <img src="https://img.shields.io/badge/platform-Linux-success.svg" alt="Linux"/>
</p>

---

## TinyPM V4

TinyPM V4 is the complete overhaul of TinyPM.

The system name is `TinyPM V4`.
The core engine name is `Forge`.

Forge gives TinyPM one unified install flow across:

- native package managers
- Flatpak
- Snap

For Abora, the native path is Nix because Abora uses NixOS as its base.

The main command is:

```bash
grab firefox vlc gimp
```

You can also inspect the engine directly:

```bash
Forge --version
```

If your system has more than one valid source available and you do not pass a flag, Forge asks which backend you want to use.

Examples:

```bash
grab firefox
grab -f org.mozilla.firefox
grab -flat org.mozilla.firefox
grab -flatpak org.mozilla.firefox
grab -s firefox
grab -n firefox
```

---

## Adding extra sources

`grab-add-repo` is the Forge answer to `add-apt-repository`. It registers an
extra source with your native backend, then `grab update` and `grab <package>`
work as usual:

```bash
grab-add-repo ppa:hepp3n/cosmic-epoch
grab update
grab cosmic-session
```

You can also call it through the main CLI:

```bash
tinypm add-repo ppa:hepp3n/cosmic-epoch
```

Each backend has its own idea of an "extra source", so `grab-add-repo` routes
the spec to the right call:

| Backend  | What `grab-add-repo` does |
| -------- | ------------------------- |
| `apt`    | `add-apt-repository -y <spec>` (installs `software-properties-common` if needed) |
| `dnf`    | `dnf config-manager --add-repo <url>`, or `dnf copr enable` for `copr:owner/project` |
| `zypper` | `zypper addrepo --refresh <url> [name]` |
| `pacman` | appends `[name]` / `Server` to `/etc/pacman.conf` (use `name=url`) |
| `apk`    | appends the URL to `/etc/apk/repositories` |
| `xbps`   | writes the repository into `/etc/xbps.d/10-tinypm.conf` |
| `brew`   | `brew tap <owner/repo>` |
| `nix`    | `nix-channel --add <url> [name]` then `nix-channel --update` |

### Abora / Nix

Abora is NixOS-based, so `grab-add-repo` registers a **Nix channel** there.
PPAs are Ubuntu-only and cannot translate, so pass a channel URL (with an
optional name) instead:

```bash
grab-add-repo https://nixos.org/channels/nixos-unstable unstable
grab cosmic-session
```

---

## Installing a desktop environment

`grab-de` installs a whole desktop environment with the right packages,
display manager, and session for your backend:

```bash
grab-de cosmic        # also: gnome, plasma, xfce
```

Or through the main CLI:

```bash
tinypm de cosmic
```

It maps a logical name to each backend's reality:

| DE       | pacman | apt | dnf | nix (declarative) |
| -------- | ------ | --- | --- | ----------------- |
| `cosmic` | `cosmic` group | `cosmic-session` | `@cosmic-desktop` | `services.desktopManager.cosmic.enable` |
| `gnome`  | `gnome gdm` | `gnome-core gdm3` | `@gnome-desktop` | `services.desktopManager.gnome.enable` |
| `plasma` | `plasma sddm` | `kde-plasma-desktop sddm` | `@kde-desktop` | `services.desktopManager.plasma6.enable` |
| `xfce`   | `xfce4 lightdm` | `xfce4 lightdm` | `@xfce-desktop` | `services.xserver.desktopManager.xfce.enable` |

On imperative distros it installs the packages and enables the display manager.

### Abora / Nix

On NixOS a desktop environment is **declarative** — installing it with
`nix-env` would give you a broken half-session. So on Nix, `grab-de` prints the
exact `configuration.nix` lines plus the rebuild command instead of installing:

```bash
grab-de cosmic
# -> add to /etc/nixos/configuration.nix:
#      services.desktopManager.cosmic.enable = true;
#      services.displayManager.cosmic-greeter.enable = true;
# -> then: sudo nixos-rebuild switch && reboot
```

---

## Abora / ANIX (declarative installs)

Abora manages its system declaratively through **ANIX** (`/etc/nixos/anix.nix`,
applied with `anix apply`). When the `anix` tool is present, TinyPM stops doing
imperative `nix-env` installs and instead edits the ANIX config, so `grab`
changes are declarative and survive system rebuilds:

```bash
grab firefox       # -> anix package add firefox   ; anix apply
grab remove htop   # -> anix package remove htop   ; anix apply
grab-de gnome      # -> anix set desktop gnome      ; anix apply
```

This only activates when `anix` is installed. On plain NixOS (no ANIX) or any
other distro, behavior is unchanged.

Environment overrides:

- `TINYPM_NO_ANIX=1` — ignore ANIX and use `nix-env` directly
- `TINYPM_ANIX_APPLY=0` — update `anix.nix` but skip the rebuild (run `anix apply` yourself)

Desktops ANIX doesn't model (e.g. `cosmic`) fall back to the printed
`configuration.nix` instructions.

---

## What's New in V4

- **Forge engine** — replaces Parcel; `Parcel` still works as a backward-compat alias
- **Multi-package install** — `grab firefox vlc gimp` installs all three in one command
- **`pin` / `unpin`** — lock a package so it is skipped during updates
- **`bundle`** — install all catalog entries in a category: `tinypm bundle Gaming`
- **`sync`** — install from a package manifest file, or generate one from tracked packages
- **`history`** — view the full install/remove event log
- **97-entry curated catalog** — expanded with Gaming, Editor, Utility, and more categories
- **`lib/providers/native.sh`** — the native PM provider is now correctly named
- **Forge doctor** — updated with Forge symlink check and catalog entry count

---

## Features

- Primary install command: `grab [packages...]`
- Engine command: `Forge --version`
- Compat alias: `Parcel --version`
- Main CLI: `tinypm`
- Native-only wrapper: `syspm`
- Flatpak, Snap, and native package support
- Automatic backend detection
- Interactive backend choice when multiple sources are available
- Multi-package install and remove
- Managed package tracking
- Pin/unpin packages to control update behavior
- Bundle install by catalog category
- Sync packages from a manifest file
- Install/remove history log
- 97-entry curated discover catalog
- `tinypm doctor --fix`
- `tinypm export-state` and `tinypm import-state`

---

## Installation

Clone the repository:

```bash
git clone https://github.com/AnimatedGTVR/TinyPM.git
cd TinyPM
```

Install TinyPM V4:

```bash
chmod +x install.sh
./install.sh
```

Use the Abora flavor:

```bash
TINYPM_FLAVOR=abora ./install.sh
```

The installer will:

- install TinyPM into `~/.tinypm`
- link commands into `~/.local/bin`
- expose `tinypm`, `tiny`, `grab`, `syspm`, `version`, `Forge`, and `Parcel`
- detect your native package manager automatically
- prefer `nix` automatically on NixOS-based systems like Abora

Then test it:

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
grab firefox vlc
tinypm bundle Gaming
tinypm doctor
tiny --version
Forge --version
syspm update
```

---

## Commands

### Main

```bash
grab [-f|-flat|-flatpak|-s|-n] <package...>
grab-add-repo <repo> [name]
grab-de <desktop>
Forge --version
Parcel --version
tinypm install [-f|-flat|-flatpak|-s|-n|--brew|--nix] <package...>
tinypm add-repo <repo> [name]
tinypm de <desktop>
tinypm search [-f|-flat|-flatpak|-s|-n|--brew|--nix] <query>
tinypm remove [-f|-flat|-flatpak|-s|-n|--brew|--nix] <package...>
tinypm list [-f|-flat|-flatpak|-s|-n|--brew|--nix]
tinypm update [-f|-flat|-flatpak|-s|-n|--brew|--nix]
tinypm info <package>
tinypm managed
tinypm pin <package>
tinypm unpin <package>
tinypm pinned
tinypm bundle list
tinypm bundle <category> [-f|-s|-n]
tinypm sync <manifest-file>
tinypm sync --generate [output-file]
tinypm history [N]
tinypm discover [query]
tinypm doctor [--fix]
tinypm export-state [file]
tinypm import-state <file>
tinypm version
```

Quick forms:

```bash
tinypm i firefox vlc      # install multiple
tinypm s blender          # search
tinypm r htop             # remove
tinypm u                  # update all
tinypm ls                 # list installed
tinypm v                  # version
tinypm h                  # history (last 50)
tinypm p firefox          # pin
tinypm b Gaming           # bundle category
```

### Pin / Unpin

```bash
tinypm pin firefox        # prevent firefox from being upgraded
tinypm unpin firefox      # re-enable upgrades for firefox
tinypm pinned             # show all pinned packages
```

### Bundle

```bash
tinypm bundle list        # list available categories and package counts
tinypm bundle Gaming      # install all Gaming entries from catalog
tinypm bundle Creative -f # install Creative entries via Flatpak only
```

### Sync

```bash
tinypm sync packages.txt          # install from manifest
tinypm sync --generate            # write tinypm-packages.txt from tracked packages
tinypm sync --generate backup.txt # write to a specific file
```

Manifest format:

```
# TinyPM V4 package manifest
# Lines: [provider:]package

flatpak:org.mozilla.firefox
snap:spotify
native:htop
curl
```

### History

```bash
tinypm history       # show last 50 events
tinypm history 100   # show last 100 events
```

### Native only (syspm)

```bash
syspm install <package> [<package>...]
syspm search <query>
syspm remove <package> [<package>...]
syspm list
syspm pin <package>
syspm unpin <package>
syspm pinned
syspm update
syspm version
```

---

## Backend Rules

Forge supports these native package managers:

- `apt`
- `dnf`
- `pacman`
- `xbps`
- `zypper`
- `apk`
- `emerge`
- `brew`
- `nix`

Abora note:

- Abora is NixOS-based, so Forge prefers `nix` as the native backend
- `syspm` on Abora routes through the native Nix path

Flags:

- `-n`, `--native` forces the native package manager
- `-f`, `-flat`, `-flatpak` forces Flatpak
- `-s`, `--snap` forces Snap

---

## Catalog

TinyPM V4 ships with a 97-entry curated catalog covering:

| Category     | Entries |
|--------------|---------|
| Communication | 8      |
| Creative     | 12      |
| Development  | 9       |
| Editor       | 5       |
| Gaming       | 9       |
| Internet     | 8       |
| Media        | 11      |
| Productivity | 6       |
| Security     | 4       |
| System       | 15      |
| Utility      | 10      |

Browse or search:

```bash
tinypm discover            # all entries
tinypm discover gaming     # filter by keyword
tinypm bundle list         # categories with counts
```

---

## Project Shape

TinyPM V4 is intentionally modular.

- `tinypm`: main CLI
- `grab`: install-first entrypoint
- `Forge`: core engine identity/version entrypoint
- `Parcel`: backward-compat alias for Forge (V3 name)
- `syspm`: native-only wrapper
- `version`: version and system report
- `lib/core/`: config, args, actions, state, history, doctor, UI
- `lib/providers/`: native, Flatpak, Snap
- `share/`: logo and curated catalog

---

## License

TinyPM V4 is licensed under the GNU General Public License v3.0.

See [LICENSE](LICENSE) for the full text.
