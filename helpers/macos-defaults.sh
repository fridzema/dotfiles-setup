#!/usr/bin/env bash
# Shared helper functions for macOS defaults scripts.
# Sourced by run_onchange_ macOS scripts — not executed directly.

set_default() {
  local domain="$1" key="$2" type="$3" value="$4"
  defaults write "$domain" "$key" "-$type" "$value"
}

set_global_default() {
  local key="$1" type="$2" value="$3"
  set_default NSGlobalDomain "$key" "$type" "$value"
}

require_sudo() {
  if ! sudo -v; then
    echo "ERROR: sudo authentication required. Aborting." >&2
    exit 1
  fi
}

restart_app() {
  local app="$1"
  killall "$app" &>/dev/null || true
}

close_system_settings() {
  osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
}
