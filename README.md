# Dotfiles

Everything I need to set up a new Mac. One command, done.

[![CI](https://github.com/fridzema/dotfiles-setup/actions/workflows/ci.yml/badge.svg)](https://github.com/fridzema/dotfiles-setup/actions/workflows/ci.yml)
![macOS](https://img.shields.io/badge/macOS-14%2B-blue)
![chezmoi](https://img.shields.io/badge/managed%20with-chezmoi-blue)

---

## Features

- Curl a script on a fresh Mac and walk away
- Works on both Apple Silicon and Intel
- Brewfiles split by category (core, dev, apps, office, quicklook)
- 100+ macOS defaults applied via `defaults write` scripts
- Ed25519 SSH key generated and added to macOS Keychain
- Scripts re-run only when their content changes (chezmoi hash detection)
- ShellCheck, chezmoi verify, and Brewfile linting on every push
- App settings backed up with Mackup + iCloud

---

## Quick start

On a fresh machine:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/fridzema/dotfiles-setup/main/bin/setup.sh)"
```

Or clone and run manually:

```bash
git clone https://github.com/fridzema/dotfiles-setup.git
cd dotfiles-setup
./bin/setup.sh
```

This installs Xcode CLI Tools, Homebrew, and chezmoi. Then `chezmoi init --apply` takes over:

1. Asks for your name, email, hostname, and locale
2. Generates an SSH key and adds it to the macOS Keychain
3. Deploys dotfiles (~/.gitconfig, ~/.zshrc, ~/.ssh/config)
4. Installs Homebrew packages from categorized Brewfiles
5. Applies macOS system defaults
6. Prints a summary of what's done and what still needs manual action

---

## What gets installed

<details>
<summary>CLI tools</summary>

| Package | Description |
|---------|-------------|
| git | Version control |
| gh | GitHub CLI |
| mas | Mac App Store CLI |
| mackup | App settings sync via iCloud |

</details>

<details>
<summary>Development</summary>

| Package | Description |
|---------|-------------|
| composer | PHP package manager |
| bun | JavaScript runtime and bundler |
| nvm | Node.js version manager |
| yarn | JavaScript package manager |

</details>

<details>
<summary>Applications (Homebrew Cask)</summary>

| App | Description |
|-----|-------------|
| Warp | GPU-accelerated terminal |
| Arc | Web browser |
| Google Chrome | Web browser |
| Zed | Code editor |
| GitHub Desktop | Git GUI |
| Slack | Team communication |
| Spotify | Music streaming |
| Setapp | App subscription service |
| Herd | PHP runtime manager |
| Ray | Debug tool |
| Tinkerwell | Laravel REPL |
| Upscayl | AI image upscaler |
| BetterDisplay | Display management |
| ImageOptim | Image optimization |

</details>

<details>
<summary>Office</summary>

| Package | Description |
|---------|-------------|
| Microsoft Office | Word, Excel, PowerPoint, Outlook |

</details>

<details>
<summary>QuickLook plugins</summary>

| Plugin | Description |
|--------|-------------|
| qlmarkdown | Markdown preview |
| quicklook-json | JSON preview |

</details>

---

## What gets configured

macOS defaults are split into separate scripts. Each re-runs when its content changes.

<details>
<summary>System (hostname, appearance, locale, security)</summary>

- Sets computer name via `scutil` and NetBIOS
- Enables dark mode with graphite accent color
- Disables startup sound
- Shows IP/hostname/OS on the login window
- Expands save and print panels by default
- Saves to disk (not iCloud) by default
- Sets metric units (Centimeters) and Celsius
- Configures locale, languages (English + Dutch), and clock format
- Requires password immediately after sleep/screen saver

</details>

<details>
<summary>Dock (layout, size, animations)</summary>

- Sets icon size to 36px
- Minimizes windows into their app icon
- Wipes default app icons for a clean Dock
- Hides recent applications
- Disables Dashboard and auto-rearrange Spaces
- Sets Mission Control animation speed to 0.1s
- Disables launch animation

</details>

<details>
<summary>Finder (file visibility, views, behavior)</summary>

- Shows hidden files and all file extensions
- Enables status bar and path bar
- Defaults to list view and searches current folder
- Opens new windows at Desktop
- Sorts folders before files
- Disables extension-change warnings
- Prevents .DS_Store on network and USB drives
- Unhides ~/Library

</details>

<details>
<summary>Input (keyboard, trackpad, Bluetooth)</summary>

- Maximum key repeat rate (1) with fast initial delay (10)
- Disables press-and-hold in favor of key repeat
- Disables natural scrolling
- Turns off auto-capitalization, smart dashes, smart quotes, auto-correct, and period substitution
- Enables full keyboard access (Tab through all controls)
- Improves Bluetooth audio quality (Apple Bitpool Min: 40)

</details>

<details>
<summary>Safari (privacy, developer tools)</summary>

- Stops sending search queries to Apple
- Suppresses search suggestions
- Shows full URL in the address bar
- Sets home page to `about:blank`
- Enables Develop menu and Web Inspector
- Warns about fraudulent websites
- Auto-updates extensions

</details>

<details>
<summary>Apps (App Store, TextEdit, Photos, Terminal, Activity Monitor)</summary>

- App Store: daily update check, auto-download, auto-install critical and app updates
- TextEdit: plain text mode, UTF-8 encoding
- Photos: no auto-open when devices are plugged in
- Time Machine: no prompt for new backup disks
- Terminal: UTF-8 only
- Activity Monitor: shows all processes sorted by CPU usage

</details>

---

## Dotfiles

| File | Deployed to | Description |
|------|-------------|-------------|
| `dot_gitconfig.tmpl` | `~/.gitconfig` | Git user, SSH commit signing, Zed as editor/diff/merge tool, rebase-on-pull, auto-prune |
| `dot_zshrc` | `~/.zshrc` | Homebrew PATH (arm64/x86), Composer, Bun, NVM, Yarn |
| `dot_gitignore_global` | `~/.gitignore_global` | Ignores .DS_Store, .idea/, .vscode/, swap files |
| `private_dot_ssh/config.tmpl` | `~/.ssh/config` | GitHub SSH with Keychain agent forwarding |

---

## Project structure

```
.
├── bin/
│   └── setup.sh                          # Bootstrap: Xcode CLI Tools, Homebrew, chezmoi
├── brewfiles/
│   ├── Brewfile.core                     # git, gh, mas, mackup
│   ├── Brewfile.dev                      # composer, bun, nvm, yarn
│   ├── Brewfile.apps                     # warp, arc, zed, slack, spotify, ...
│   ├── Brewfile.office                   # microsoft-office
│   └── Brewfile.quicklook               # qlmarkdown, quicklook-json
├── .chezmoiscripts/
│   ├── run_once_01-generate-ssh-key.sh.tmpl
│   ├── run_once_02-configure-nvm.sh
│   ├── run_onchange_10-install-packages.sh.tmpl
│   ├── run_onchange_20-macos-system.sh.tmpl
│   ├── run_onchange_21-macos-dock.sh.tmpl
│   ├── run_onchange_22-macos-finder.sh.tmpl
│   ├── run_onchange_23-macos-input.sh.tmpl
│   ├── run_onchange_24-macos-safari.sh.tmpl
│   ├── run_onchange_25-macos-apps.sh.tmpl
│   └── run_after_99-summary.sh.tmpl
├── helpers/
│   └── macos-defaults.sh                 # Shared library: set_default, require_sudo, restart_app
├── .chezmoi.toml.tmpl                    # Prompts for name, email, hostname, locale
├── dot_gitconfig.tmpl
├── dot_zshrc
├── dot_gitignore_global
├── private_dot_ssh/
│   └── config.tmpl
└── .github/
    ├── workflows/ci.yml                  # ShellCheck + chezmoi verify + Brewfile lint
    └── test-chezmoi-data.toml            # CI test fixture
```

---

## How it works

```
bin/setup.sh
  │
  ├─ Install Xcode CLI Tools (if missing)
  ├─ Install Homebrew (Apple Silicon or Intel)
  ├─ Install chezmoi
  └─ chezmoi init --apply
       │
       ├─ Prompt for name, email, hostname, locale
       ├─ run_once_01  → Generate Ed25519 SSH key, add to Keychain, copy pub to clipboard
       ├─ run_once_02  → Create ~/.nvm directory
       ├─ run_onchange_10 → brew update && brew bundle (core → dev → apps → office → quicklook)
       ├─ run_onchange_20-25 → Apply macOS defaults (system, dock, finder, input, safari, apps)
       ├─ Deploy templates → ~/.gitconfig, ~/.zshrc, ~/.ssh/config, ~/.gitignore_global
       └─ run_after_99 → Print summary (installed count, missing apps, next steps)
```

---

## Updating

After editing any file in this repo:

```bash
chezmoi apply
```

Or pull and apply in one step:

```bash
chezmoi update
```

If you changed a Brewfile or macOS defaults script, chezmoi detects the content change and re-runs it automatically (`run_onchange_` prefix).

---

## App settings sync

Warp, Zed, and other app configs are synced via [Mackup](https://github.com/lra/mackup) and iCloud. After setup:

```bash
mackup restore
```

---

## Manual steps

The summary script tells you what's left:

- Add your SSH public key to [github.com/settings/keys](https://github.com/settings/keys) (it's already in your clipboard)
- Install Setapp apps: Bartender, Paste, CleanShot, HazeOver, DevUtils, Requestly, AlDente Pro
- Download FortiClient VPN from [fortinet.com](https://www.fortinet.com/support/product-downloads#vpn)
- Restart -- some macOS defaults only take effect after a reboot

---

## CI

Every push and PR runs three checks on macOS 14:

| Job | What it does |
|-----|--------------|
| shellcheck | Lints all shell scripts (pure and templated) |
| chezmoi-verify | Dry-run `chezmoi apply` with test data to validate templates |
| brewfile-lint | Runs `brew bundle list` on each Brewfile to verify package references |

---

## License

[MIT](LICENSE)
