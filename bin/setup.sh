#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================"
echo "  Dotfiles Bootstrap"
echo "============================================"
echo ""

# --- 1. Xcode CLI Tools ---
if ! xcode-select -p &>/dev/null; then
  echo "==> Installing Xcode Command Line Tools..."
  xcode-select --install

  echo "    Waiting for installation to complete..."
  # Wait for the installer to start
  sleep 5
  # Poll until the tools are available
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  echo "    Xcode CLI Tools installed."
else
  echo "==> Xcode CLI Tools already installed."
fi

# Accept license (may already be accepted)
sudo xcodebuild -license accept 2>/dev/null || true

# --- 2. Homebrew ---
if ! command -v brew &>/dev/null; then
  echo "==> Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# Add Homebrew to PATH for this session (handle both Apple Silicon and Intel)
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Verify Homebrew is available
if ! command -v brew &>/dev/null; then
  echo "ERROR: Homebrew installation failed or is not in PATH."
  exit 1
fi

echo "==> Homebrew ready."

# --- 3. chezmoi ---
if ! command -v chezmoi &>/dev/null; then
  echo "==> Installing chezmoi..."
  brew install chezmoi
fi

# Verify chezmoi is available
if ! command -v chezmoi &>/dev/null; then
  echo "ERROR: chezmoi installation failed."
  exit 1
fi

echo "==> chezmoi ready."

# --- 4. Initialize and apply ---
echo "==> Running chezmoi init --apply..."
echo "    You will be prompted for configuration values on first run."
echo ""

# Detect if running from a local clone (vs. curl pipe)
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
if [ -f "$SCRIPT_DIR/.chezmoi.toml.tmpl" ]; then
  chezmoi init --apply --source="$SCRIPT_DIR"
else
  chezmoi init --apply fridzema/dotfiles-setup
fi
