# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/), targeting macOS (Apple Silicon and Intel).

## Quick Start

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

The bootstrap script installs Xcode CLI Tools, Homebrew, and chezmoi, then runs `chezmoi init --apply` which:

1. Prompts for your name, email, hostname, and locale
2. Deploys dotfiles (~/.gitconfig, ~/.zshrc, ~/.ssh/config)
3. Generates an SSH key and adds it to the macOS Keychain
4. Installs Homebrew packages from categorized Brewfiles
5. Applies macOS system defaults
6. Prints a summary of what's installed and what still needs manual action

## Updating

After editing any file in this repo:

```bash
chezmoi apply
```

Or pull and apply in one step:

```bash
chezmoi update
```

## Structure

| Path | Purpose |
|---|---|
| `.chezmoi.toml.tmpl` | Machine-specific config (name, email, hostname, locale) |
| `dot_gitconfig.tmpl` | Git configuration template |
| `dot_zshrc` | Shell configuration |
| `private_dot_ssh/` | SSH config (deployed with 0700 permissions) |
| `brewfiles/` | Split Brewfiles by category (core, dev, apps, office, quicklook) |
| `.chezmoiscripts/` | Lifecycle scripts (SSH key gen, package install, macOS defaults) |
| `helpers/` | Shared shell library for macOS defaults scripts |
| `bin/setup.sh` | Bootstrap script for fresh machines |

## macOS Defaults

System preferences are split into categorized scripts that re-run when their content changes:

- **system** — hostname, locale, dark mode, UI/UX, screen lock
- **dock** — icon size, layout, Mission Control
- **finder** — hidden files, extensions, list view, ~/Library
- **input** — keyboard repeat, disable autocorrect/smart quotes
- **safari** — privacy, developer tools, home page
- **apps** — App Store updates, TextEdit, Activity Monitor, Photos, Terminal

## App Settings

App-specific settings (Warp, Zed, etc.) are managed by [mackup](https://github.com/lra/mackup) via iCloud sync. After setup, run:

```bash
mackup restore
```

## Manual Steps

The post-apply summary reports which apps still need manual installation:

- **FortiClient VPN** — download from [fortinet.com](https://www.fortinet.com/support/product-downloads#vpn)
- **Setapp apps** — Bartender, Paste, CleanShot, HazeOver, DevUtils, Requestly, AlDente Pro
- **GitHub SSH key** — public key is copied to clipboard during setup
