#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMPLETED_FILE="${SCRIPT_DIR}/.setup-completed-steps"

# Track completed steps for re-run capability
mark_done() { echo "$1" >> "$COMPLETED_FILE"; }
is_done() { [ -f "$COMPLETED_FILE" ] && grep -qx "$1" "$COMPLETED_FILE"; }

echo ""
echo "============================================"
echo "  Mac Setup - Fridzema-Mac"
echo "  macOS Tahoe 26.2 / Apple Silicon"
echo "============================================"
echo ""

# Step 1: Homebrew + Brewfile
if ! is_done "brew"; then
    echo "[1/5] Installing Homebrew and packages..."
    bash "${SCRIPT_DIR}/scripts/install-brew.sh"
    mark_done "brew"
else
    echo "[1/5] Homebrew + packages already installed. Skipping."
fi

# Step 2: Manual downloads
if ! is_done "manual"; then
    echo ""
    echo "[2/5] Installing manual downloads..."
    bash "${SCRIPT_DIR}/scripts/install-manual.sh"
    mark_done "manual"
else
    echo "[2/5] Manual downloads already done. Skipping."
fi

# Step 3: Git & SSH
if ! is_done "git"; then
    echo ""
    echo "[3/5] Configuring Git & SSH..."
    bash "${SCRIPT_DIR}/scripts/configure-git.sh"
    mark_done "git"
else
    echo "[3/5] Git & SSH already configured. Skipping."
fi

# Step 4: macOS defaults
if ! is_done "macos"; then
    echo ""
    echo "[4/5] Applying macOS defaults..."
    bash "${SCRIPT_DIR}/scripts/configure-macos.sh"
    mark_done "macos"
else
    echo "[4/5] macOS defaults already applied. Skipping."
fi

# Step 5: Shell configuration
if ! is_done "shell"; then
    echo ""
    echo "[5/5] Configuring shell..."
    bash "${SCRIPT_DIR}/scripts/configure-shell.sh"
    mark_done "shell"
else
    echo "[5/5] Shell already configured. Skipping."
fi

# Summary
echo ""
echo "============================================"
echo "  Setup Complete!"
echo "============================================"
echo ""
echo "  Installed via Brew:  $(brew list --formula | wc -l | tr -d ' ') formulae, $(brew list --cask | wc -l | tr -d ' ') casks"
echo "  macOS defaults:      Applied"
echo "  Git:                 $(git config --global user.name) <$(git config --global user.email)>"
echo "  SSH key:             ~/.ssh/id_ed25519"
echo ""
echo "  Manual actions remaining:"
echo "  - Install FortiClient VPN from browser download"
echo "  - Add SSH key to GitHub (should be in clipboard)"
echo "  - Run 'mackup restore' to restore app settings from iCloud"
echo "  - Sign in to apps (Spotify, Slack, Arc, Chrome, etc.)"
echo "  - Restart Mac to apply all settings"
echo ""
echo "  Setapp apps to install:"
echo "  - Bartender"
echo "  - Paste"
echo "  - CleanShot"
echo "  - HazeOver"
echo "  - DevUtils"
echo "  - Requestly"
echo "  - AlDente Pro"
echo ""
echo "  To re-run a specific step, delete the line from .setup-completed-steps"
echo "  and run this script again."
echo ""
