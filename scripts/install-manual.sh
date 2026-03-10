#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing software not available via Homebrew..."

# --- FortiClient VPN ---
echo "==> Opening FortiClient VPN download page..."
echo "    Please download and install FortiClient VPN manually."
open "https://www.fortinet.com/support/product-downloads#vpn"

# --- Apple Container ---
echo "==> Installing Apple Container..."
CONTAINER_DIR="${HOME}/Developer/apple-container"
if [ ! -d "$CONTAINER_DIR" ]; then
    echo "    Cloning apple/container..."
    mkdir -p "${HOME}/Developer"
    git clone https://github.com/apple/container.git "$CONTAINER_DIR"
else
    echo "    apple/container already cloned, pulling latest..."
    git -C "$CONTAINER_DIR" pull
fi

echo "    Building apple/container (this may take a few minutes)..."
cd "$CONTAINER_DIR"
swift build -c release

# Symlink the binary to /usr/local/bin
BINARY_PATH="$(swift build -c release --show-bin-path)/container"
if [ -f "$BINARY_PATH" ]; then
    sudo mkdir -p /usr/local/bin
    sudo ln -sf "$BINARY_PATH" /usr/local/bin/container
    echo "    Apple Container installed to /usr/local/bin/container"
else
    echo "    WARNING: Could not find built binary at $BINARY_PATH"
fi

echo "==> Manual installations complete."
echo "    ACTION REQUIRED: Install FortiClient VPN from the browser window."
