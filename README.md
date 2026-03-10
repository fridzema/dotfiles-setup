# Mac Setup

Fresh Mac setup scripts for Apple Silicon running macOS Tahoe 26.2.

## Quick Start

```bash
git clone https://github.com/fridzema/mac-setup.git ~/.mac-setup
cd ~/.mac-setup
./setup.sh
```

## What It Does

1. Installs Xcode CLI Tools + Homebrew
2. Installs all apps via Brewfile (see list below)
3. Downloads FortiClient VPN + builds Apple Container
4. Configures Git with Ed25519 SSH key
5. Applies ~60 macOS defaults (dark mode, Finder, Dock, input, Safari, etc.)
6. Sets up minimal .zshrc with PATH exports

## Apps Installed via Brew

**CLI:** git, gh, composer, bun, nvm, yarn, mas

**GUI:** Warp, Arc, Chrome, Zed, Setapp, GitHub Desktop, Spotify, Herd, Upscayl, Slack, BetterDisplay, ImageOptim, Ray, Tinkerwell, Microsoft Office, QLMarkdown, QuickLook JSON

## Running Individual Scripts

Each script can be run independently:

```bash
./scripts/install-brew.sh       # Homebrew + Brewfile
./scripts/install-manual.sh     # FortiClient + Apple Container
./scripts/configure-git.sh      # Git config + SSH key
./scripts/configure-macos.sh    # macOS defaults
./scripts/configure-shell.sh    # .zshrc setup
```

## Re-running

The setup tracks completed steps in `.setup-completed-steps`. Delete a line to re-run that step, or delete the file to run everything again.
