<p align="center">
  <img src="assets/TinyLogo.png" alt="TinyPM Logo" width="500"/>
</p>

<h1 align="center">TinyPM</h1>

<p align="center">
  A tiny terminal-first package manager frontend for Linux.<br>
  Works with native package managers, Flatpak, Snap, and Seed. Licensed under GPLv3.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-2.0.0--alpha--untested.1-blue.svg" alt="Version 2.0.0 alpha untested 1"/>
  <img src="https://img.shields.io/badge/license-GPLv3-blue.svg" alt="GPLv3"/>
  <img src="https://img.shields.io/badge/platform-Linux-success.svg" alt="Linux"/>
</p>

---

## What Is TinyPM?

TinyPM is a small package manager frontend that gives you one command style across multiple Linux package sources.

TinyPM currently supports:

- native package managers through `-n`
- Flatpak through `-f`
- Snap through `-s`
- Seed through `--seed`

TinyPM detects and uses these native package managers:

- `apt`
- `dnf`
- `pacman`
- `xbps`
- `zypper`
- `apk`
- `emerge`

If none of those are available, TinyPM can fall back to Seed.

---

## What Is Seed?

Seed is TinyPM's built-in mini package manager and store.

It serves two roles:

- portable package recipes for direct Seed installs
- a simple storefront over TinyPM's larger built-in catalog

Useful Seed commands:

```bash
seed store
seed search blender
seed install blender
seed install yq
seed about
seed update
```

`seed update` pulls the latest TinyPM repo from GitHub and refreshes the installed runtime.

---

## Features

- Main commands: `tinypm` and `tiny`
- Native shortcut: `syspm`
- Shortcut commands: `ainstall`, `search`, `term`, `start`, `supdate`
- Seed storefront command: `seed`
- Terminal app launcher: `tinypm-app`
- Interactive installer menu
- Managed package tracking
- Modular internals under `lib/`

---

## Installation

Clone the repository:

```bash
git clone https://github.com/AnimatedGTVR/TinyPM.git
cd TinyPM
```

Run the installer:

```bash
chmod +x install.sh
./install.sh
```

The installer will:

- show the TinyPM logo
- detect your native package manager
- let you choose `apt`, `xbps`, `pacman`, `dnf`, `zypper`, `apk`, `emerge`, or `seed`
- install TinyPM into `~/.tinypm`
- create command links in `~/.local/bin`
- add `syspm` for native package-manager actions

Then test it:

```bash
export PATH="$HOME/.local/bin:$PATH"
hash -r
tinypm help
tinypm doctor
tiny --version
syspm update
seed store
```

---

## Commands

### Main

```bash
tinypm install [-f|-s|-n|--seed] <package>
tinypm search [-f|-s|-n|--seed] <query>
tinypm remove [-f|-s|-n|--seed] <package>
tinypm list [-f|-s|-n|--seed]
tinypm start [-f|-s|--seed] <app>
tinypm update [-f|-s|-n|--seed]
tinypm doctor
tinypm version
```

### Shortcuts

```bash
ainstall [-f|-s|-n|--seed] <package>
search [-f|-s|-n|--seed] <query>
term [-f|-s|-n|--seed] <package>
start [-f|-s|--seed] <app>
supdate [-f|-s|-n|--seed]
tiny --version
syspm update
```

### Seed

```bash
seed store [query]
seed search [query]
seed install <package>
seed remove <package>
seed list
seed run <package>
seed update
seed about
```

Examples:

```bash
seed store
seed search blender
seed install blender
seed install yq
tinypm install -f org.blender.Blender
tinypm install -n htop
syspm update
```

---

## Store Notes

`discover` and `seed store` are curated built-in catalogs.

They are larger than before, but they are still not every package in every Linux repository. For full provider search, use the real backends through TinyPM:

```bash
tinypm search -n <query>
tinypm search -f <query>
tinypm search -s <query>
```

---

## Architecture

TinyPM is modular by design.

- `tinypm`: main entrypoint
- `tiny`: short alias to the same entrypoint
- `syspm`: native package-manager wrapper
- `seed`: Seed storefront and wrapper
- `lib/core/`: parsing, actions, app flow, UI, state, config, doctor output
- `lib/providers/`: backend logic
- `share/`: catalog and ASCII/logo assets

---

## License

TinyPM is licensed under the GNU General Public License v3.0.

See [LICENSE](LICENSE) for the full text.
