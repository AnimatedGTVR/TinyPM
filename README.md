<p align="center">
  <img src="assets/atiny-logo.png" alt="ATiny Logo" width="500"/>
</p>

<h1 align="center">ATiny</h1>

<p align="center">
  A beginner-friendly Linux package wrapper for Windows users.<br>
  Part of the Abora ecosystem. Licensed under GPLv3.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue.svg"/>
  <img src="https://img.shields.io/badge/license-GPLv3-blue.svg"/>
  <img src="https://img.shields.io/badge/platform-Linux-success.svg"/>
</p>

---

# What is ATiny?

ATiny is a simple command wrapper that unifies Linux package management.

Instead of remembering:

- `apt`
- `dnf`
- `pacman`
- `zypper`
- `flatpak`
- `snap`

You use short, consistent commands everywhere.

ATiny automatically detects your system and chooses the correct backend.

It is designed for:

- 🟢 Windows users moving to Linux
- 🟢 Beginners who want simple commands
- 🟢 Advanced users who still want full control

---

# Philosophy

Linux package managers are powerful — but confusing.

Search results often include:

- Libraries
- Shared files
- Development packages
- Tools
- Multiple versions
- Soundfonts
- Helper packages

ATiny filters that noise by default.

You see clear, human-friendly results first.

If you want raw output, add:


-p


ATiny works for beginners and pros.

---

# Installation

Clone the repository:


git clone https://github.com/YOURNAME/ATiny.git

cd ATiny


Make installer executable:


chmod +x install.sh


Run installer:


./install.sh


Restart your terminal, then test:


helptiny
atiny --version


---

# Commands

## Install


ainstall <name>


Automatically tries:

1. System package manager
2. Flatpak
3. Snap

Example:


ainstall musescore


---

## Remove


term <name>


Removes whatever is installed.

Flatpak only:


fterm <name>


Snap only:


sterm <name>


---

## Search

Human-friendly mode (default):


search <query>


Shows:

- Top picks
- Recommended install command
- Filters confusing helper packages

Pro mode:


search -p <query>


Shows full raw output from system, flatpak, and snap.

---

## Update Everything


supdate


Pro mode:


supdate -p


---

## List Installed Apps

Simple:


list


Pro:


list -p


---

## Run an Application


run <name>


or


start <name>


ATiny will try:

1. Flatpak
2. Snap
3. Native binary
4. Desktop launcher

---

## Help


helptiny
mantiny <command>


---

# Supported Systems

ATiny automatically supports:

- Debian / Ubuntu / Kubuntu (apt)
- Fedora (dnf)
- Arch Linux (pacman)
- openSUSE (zypper)

If Flatpak or Snap are installed, ATiny integrates with them automatically.

---

# License

ATiny is licensed under the **GNU General Public License v3.0 (GPL-3.0-only)**.

You are free to:

- Use
- Modify
- Distribute

Any distributed modifications must remain GPLv3.

See the `LICENSE` file for full text.

---

# Roadmap

Planned improvements:

- Better version detection during install
- Automatic smart version preference (e.g., musescore4 > musescore3)
- Optional minimal UI wrapper
- Abora integration layer
- Better Windows-style error messages

---

# Contributing

Pull requests are welcome.

Please keep changes:

- Beginner-safe by default
- Cross-distro compatible
- Clean and readable
- GNU-aligned

---

# Vision

ATiny is not a replacement for your system package manager.

It is a translator.

A bridge.

A tiny layer that makes Linux simpler — without removing its power.

---

ATiny v1.0.0
