#!/usr/bin/env bash
set -euo pipefail

NVM_DIR="${HOME}/.nvm"

if [ -d "$NVM_DIR" ]; then
  echo "$NVM_DIR already exists, skipping."
  exit 0
fi

echo "==> Creating $NVM_DIR directory..."
mkdir -p "$NVM_DIR"
echo "$NVM_DIR created. NVM is ready to use."
