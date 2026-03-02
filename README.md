<p align="center">
  <img src="assets/TinyLogo.png" alt="TinyPM Logo" width="500"/>
</p>

<h1 align="center">TinyPM</h1>

<p align="center">
  A tiny terminal-first package manager frontend for Linux.<br>
  Works with Flatpak, Snap, and APT. Licensed under GPLv3.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.7.0-blue.svg" alt="Version 1.7.0"/>
  <img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="GPLv3"/>
  <img src="https://img.shields.io/badge/platform-Linux-success.svg" alt="Linux"/>
</p>

---

## What Is TinyPM?

TinyPM is a small package manager frontend that gives you one command style across multiple Linux package sources.

Instead of jumping between different tools, TinyPM lets you use one interface for:

- Flatpak
- Snap
- APT

It is designed to stay simple:

- beginner-friendly commands
- terminal-first workflow
- modular shell scripts that distro maintainers can remix
- direct access to the real backend when you want it

---

## What TinyPM Does

TinyPM can:

- install packages
- search packages
- remove packages
- list installed packages
- run installed apps
- track packages installed through TinyPM
- show installed desktop apps
- browse a small built-in discover catalog
- report system and backend status with `doctor` and `version`

TinyPM is not a full app store database.

`discover` is a small built-in starter catalog, not every app available from Flatpak, Snap, or APT.

---

## Features

- One main CLI: `tinypm`
- Shortcut commands: `ainstall`, `search`, `term`, `start`, `supdate`
- Terminal app launcher: `tinypm-app`
- Host-aware execution for sandboxed environments
- Managed package tracking
- Modular internals under `lib/` for easy downstream remixes

---

## Installation

Clone the repository:

```bash
git clone https://github.com/AnimatedGTVR/ATiny.git
cd ATiny
```

Make the scripts executable if needed:

```bash
chmod +x atiny tinypm-app version _spinner
```

Add the install directory to your `PATH` or symlink the commands into `~/.local/bin`.

Example:

```bash
mkdir -p ~/.local/bin
ln -sf "$PWD/atiny" ~/.local/bin/tinypm
ln -sf "$PWD/atiny" ~/.local/bin/ainstall
ln -sf "$PWD/atiny" ~/.local/bin/search
ln -sf "$PWD/atiny" ~/.local/bin/term
ln -sf "$PWD/atiny" ~/.local/bin/start
ln -sf "$PWD/atiny" ~/.local/bin/supdate
ln -sf "$PWD/tinypm-app" ~/.local/bin/tinypm-app
```

Then test it:

```bash
tinypm help
tinypm doctor
version
```

---

## Commands

### Install

```bash
tinypm install [-f|-s|-n] <package>
ainstall [-f|-s|-n] <package>
```

Examples:

```bash
ainstall -f org.gimp.GIMP
ainstall -s firefox
ainstall -n vlc
```

### Search

```bash
tinypm search [-f|-s|-n] <query>
search [-f|-s|-n] <query>
```

Examples:

```bash
search -f musescore
search -s firefox
search -n libreoffice
```

### Remove

```bash
tinypm remove [-f|-s|-n] <package>
term [-f|-s|-n] <package>
```

### List Installed Packages

```bash
tinypm list [-f|-s|-n]
```

Examples:

```bash
tinypm list -f
tinypm list -s
tinypm list -n
```

### Run an App

```bash
tinypm start [-f|-s] <app>
tinypm run [-f|-s] <app>
start [-f|-s] <app>
```

Examples:

```bash
start org.gimp.GIMP -f
start firefox -s
start musescore
```

### Update

```bash
tinypm update [-f|-s|-n]
supdate [-f|-s|-n]
```

### TinyPM Package Tracking

```bash
tinypm managed
tinypm info <package>
```

### Desktop Apps and Discover

```bash
tinypm apps
tinypm discover [query]
tinypm app
tinypm-app
```

---

## Flags

- `-f`, `--flat`, `--flatpak`: use Flatpak
- `-s`, `--snp`, `--snap`: use Snap
- `-n`, `--nat`, `--native`: use APT

If you do not pass a backend flag, TinyPM uses its default selection logic.

---

## Terminal App

TinyPM includes a terminal app with a simple home screen for:

- viewing your desktop apps
- browsing the built-in discover catalog
- searching package sources
- installing and removing packages
- running apps
- checking doctor info

Launch it with:

```bash
tinypm-app
```

or:

```bash
tinypm app
```

---

## Architecture

TinyPM is intentionally modular.

- `atiny`: main entrypoint
- `lib/core/`: parsing, app flow, actions, state, UI, doctor output
- `lib/providers/`: backend-specific provider logic
- `share/`: catalog and logo assets

This makes it easier for distro maintainers and downstream forks to keep the same interface while replacing internals.

---

## Supported Backends

TinyPM currently supports:

- Flatpak
- Snap
- APT

The current implementation is aimed at Linux systems where those tools are available.

---

## License

TinyPM is licensed under the **GNU General Public License v3.0**.

See [LICENSE](LICENSE) for the full text.

---

## Project Status

TinyPM is currently a working terminal-first package manager frontend with:

- real Flatpak support
- real Snap support
- real APT support
- managed package tracking
- terminal app flow
- fastfetch-style `version` output

---

## Vision

TinyPM is not trying to replace Flatpak, Snap, or APT.

It is a tiny layer over them:

- one interface
- small scripts
- easy to remix
- easy to understand

TinyPM keeps the real Linux tools underneath, while giving people a simpler way to use them.
