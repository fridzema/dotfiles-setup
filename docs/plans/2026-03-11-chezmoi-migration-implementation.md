# Chezmoi Migration Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Migrate the mac-setup repository from custom shell scripts to a chezmoi-based dotfiles manager, fixing all known bugs and following the approved design.

**Architecture:** Clean-slate rewrite. Repo root is the chezmoi source directory. Bootstrap script handles pre-chezmoi steps (Xcode, Homebrew), then hands off to `chezmoi init --apply`. All dotfiles are Go templates, macOS defaults are split into categorized `run_onchange_` scripts with a shared helper, and Brewfiles are split by category with content-hash-triggered reinstall.

**Tech Stack:** chezmoi, Go templates, Bash, Homebrew, macOS `defaults` CLI

**Reference:** `docs/plans/2026-03-11-chezmoi-migration-design.md`

---

### Task 1: Remove Old Structure

Remove all legacy files that are being replaced. Keep `docs/`, `.github/`, `.gitignore`, and `README.md` (they'll be updated in later tasks).

**Files:**
- Delete: `setup.sh`
- Delete: `scripts/install-brew.sh`
- Delete: `scripts/install-manual.sh`
- Delete: `scripts/configure-git.sh`
- Delete: `scripts/configure-macos.sh`
- Delete: `scripts/configure-shell.sh`
- Delete: `scripts/` (directory)
- Delete: `config/.gitconfig`
- Delete: `config/` (directory)
- Delete: `Brewfile`

**Step 1: Delete legacy files**

```bash
rm setup.sh
rm -r scripts/
rm -r config/
rm Brewfile
```

**Step 2: Commit**

```bash
git add -A
git commit -m "Remove legacy shell scripts and config in preparation for chezmoi migration"
```

---

### Task 2: Create Chezmoi Foundation

Set up the core chezmoi configuration files that define how the repo is processed.

**Files:**
- Create: `.chezmoi.toml.tmpl`
- Create: `.chezmoiignore`
- Create: `.github/test-chezmoi-data.toml`

**Step 1: Create `.chezmoi.toml.tmpl`**

This file prompts the user on first `chezmoi init` and stores values in `~/.config/chezmoi/chezmoi.toml`.

```toml
{{- $name := promptStringOnce . "data.name" "Full name" -}}
{{- $email := promptStringOnce . "data.email" "Email address" -}}
{{- $hostname := promptStringOnce . "data.hostname" "Computer hostname" -}}
{{- $locale := promptStringOnce . "data.locale" "Locale" "en_US@currency=EUR" -}}

[data]
  name = {{ $name | quote }}
  email = {{ $email | quote }}
  hostname = {{ $hostname | quote }}
  locale = {{ $locale | quote }}
```

**Step 2: Create `.chezmoiignore`**

Exclude non-dotfile repo files from being deployed to `$HOME`.

```
bin/
brewfiles/
helpers/
docs/
README.md
LICENSE
.github/
.gitignore
```

**Step 3: Create `.github/test-chezmoi-data.toml`**

Fixture data for deterministic, non-interactive template verification. Used here and in CI.

```toml
[data]
  name = "Test User"
  email = "test@example.com"
  hostname = "Test-Mac"
  locale = "en_US"
```

**Step 4: Verify templates compile with fixture data**

```bash
chezmoi init --source="$(pwd)" \
  --config-path=".github/test-chezmoi-data.toml" \
  --dry-run --verbose
```

Expected: chezmoi renders the source state without errors using the test fixture data.

**Step 5: Commit**

```bash
git add .chezmoi.toml.tmpl .chezmoiignore .github/test-chezmoi-data.toml
git commit -m "Add chezmoi foundation: config template, ignore file, and test fixture data"
```

---

### Task 3: Create Dotfile Templates

Port the existing dotfile configurations into chezmoi-managed templates.

**Files:**
- Create: `dot_gitconfig.tmpl`
- Create: `dot_gitignore_global`
- Create: `dot_zshrc.tmpl`
- Create: `private_dot_ssh/config.tmpl`

**Step 1: Create `dot_gitconfig.tmpl`**

Based on current `config/.gitconfig` with templated user fields. Note: `{{ .data.name }}` etc. reference values from `.chezmoi.toml.tmpl`.

```toml
[user]
	name = {{ .data.name }}
	email = {{ .data.email }}
	signingkey = {{ .chezmoi.homeDir }}/.ssh/id_ed25519.pub

[core]
	editor = zed --wait
	commentchar = ;
	ignorecase = false
	excludesfile = ~/.gitignore_global

[init]
	defaultBranch = main

[branch]
	autosetuprebase = always

[push]
	autosetupremote = true
	default = simple

[pull]
	rebase = true
	autostash = true

[fetch]
	prune = true
	prunetags = true

[rebase]
	autosquash = true
	autostash = true

[diff]
	tool = zed

[difftool "zed"]
	cmd = zed --diff \"$LOCAL\" \"$REMOTE\"

[merge]
	tool = zed

[mergetool "zed"]
	cmd = zed --merge \"$LOCAL\" \"$REMOTE\" \"$BASE\" \"$MERGED\"

[gpg]
	format = ssh

[commit]
	gpgsign = true

[tag]
	gpgsign = true
	sort = -taggerdate:iso
```

**Step 2: Create `dot_gitignore_global`**

```
.DS_Store
.idea/
*.swp
*.swo
*~
```

**Step 3: Create `dot_zshrc.tmpl`**

Detects Homebrew location robustly instead of hard-coding `/opt/homebrew`.

```bash
# Homebrew
if [ -x /opt/homebrew/bin/brew ]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
elif [ -x /usr/local/bin/brew ]; then
  eval "$(/usr/local/bin/brew shellenv)"
fi

# Composer global binaries
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# NVM (uses $HOMEBREW_PREFIX set by brew shellenv — works on both Apple Silicon and Intel)
export NVM_DIR="$HOME/.nvm"
[ -s "$HOMEBREW_PREFIX/opt/nvm/nvm.sh" ] && \. "$HOMEBREW_PREFIX/opt/nvm/nvm.sh"
[ -s "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm" ] && \. "$HOMEBREW_PREFIX/opt/nvm/etc/bash_completion.d/nvm"

# Yarn global binaries
export PATH="$HOME/.yarn/bin:$PATH"
```

**Step 4: Create `private_dot_ssh/` directory and `config.tmpl`**

The `private_` prefix ensures chezmoi creates `~/.ssh` with 0700 permissions. This fixes the high-severity bug where `~/.ssh` didn't exist on a fresh machine.

```
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile {{ .chezmoi.homeDir }}/.ssh/id_ed25519
```

**Step 5: Run shellcheck on the zshrc template**

```bash
shellcheck dot_zshrc.tmpl
```

Expected: PASS (no template directives in this file to interfere).

**Step 6: Commit**

```bash
git add dot_gitconfig.tmpl dot_gitignore_global dot_zshrc.tmpl private_dot_ssh/
git commit -m "Add dotfile templates: gitconfig, gitignore, zshrc, ssh config"
```

---

### Task 4: Create Split Brewfiles

Split the single Brewfile into categorized files.

**Files:**
- Create: `brewfiles/Brewfile.core`
- Create: `brewfiles/Brewfile.dev`
- Create: `brewfiles/Brewfile.apps`
- Create: `brewfiles/Brewfile.office`
- Create: `brewfiles/Brewfile.quicklook`

**Step 1: Create `brewfiles/Brewfile.core`**

```ruby
# Core CLI tools and utilities
brew "git"
brew "gh"
brew "mas"
brew "mackup"
```

**Step 2: Create `brewfiles/Brewfile.dev`**

```ruby
# Development tools and package managers
brew "composer"
brew "bun"
brew "nvm"
brew "yarn"
```

**Step 3: Create `brewfiles/Brewfile.apps`**

```ruby
# GUI applications
cask "warp"
cask "arc"
cask "google-chrome"
cask "zed"
cask "setapp"
cask "github"
cask "spotify"
cask "herd"
cask "upscayl"
cask "slack"
cask "betterdisplay"
cask "imageoptim"
cask "ray"
cask "tinkerwell"
```

**Step 4: Create `brewfiles/Brewfile.office`**

```ruby
# Microsoft Office suite
cask "microsoft-office"
```

**Step 5: Create `brewfiles/Brewfile.quicklook`**

```ruby
# QuickLook plugins
cask "qlmarkdown"
cask "quicklook-json"
```

**Step 6: Validate each Brewfile**

```bash
for f in brewfiles/Brewfile.*; do
  echo "Checking $f..."
  brew bundle check --file="$f" --verbose
done
```

Expected: each reports which packages are installed or missing (no syntax errors).

**Step 7: Commit**

```bash
git add brewfiles/
git commit -m "Add split Brewfiles: core, dev, apps, office, quicklook"
```

---

### Task 5: Create Shared macOS Defaults Helper

Build the shared shell library sourced by all macOS defaults scripts.

**Files:**
- Create: `helpers/macos-defaults.sh`

**Step 1: Create `helpers/macos-defaults.sh`**

```bash
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
  sudo -v
}

restart_app() {
  local app="$1"
  killall "$app" &>/dev/null || true
}

close_system_settings() {
  osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true
}
```

**Step 2: Run shellcheck**

```bash
shellcheck helpers/macos-defaults.sh
```

Expected: PASS.

**Step 3: Commit**

```bash
git add helpers/
git commit -m "Add shared macOS defaults helper library"
```

---

### Task 6: Create run_once_ Lifecycle Scripts

Scripts that run only on first `chezmoi apply`.

**Files:**
- Create: `.chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl`
- Create: `.chezmoiscripts/run_once_02-configure-nvm.sh`

**Step 1: Create `.chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl`**

```bash
#!/usr/bin/env bash
set -euo pipefail

SSH_KEY="{{ .chezmoi.homeDir }}/.ssh/id_ed25519"

if [ -f "$SSH_KEY" ]; then
  echo "SSH key already exists at $SSH_KEY, skipping generation."
  exit 0
fi

echo "==> Generating SSH key..."
ssh-keygen -t ed25519 -C "{{ .data.email }}" -f "$SSH_KEY"

echo "==> Adding SSH key to macOS Keychain..."
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"

echo "==> Copying public key to clipboard..."
pbcopy < "${SSH_KEY}.pub"

echo ""
echo "SSH key generated and added to Keychain."
echo "Public key has been copied to your clipboard."
echo "Add it to GitHub: https://github.com/settings/ssh/new"
```

**Step 2: Create `.chezmoiscripts/run_once_02-configure-nvm.sh`**

```bash
#!/usr/bin/env bash
set -euo pipefail

NVM_DIR="${HOME}/.nvm"

if [ -d "$NVM_DIR" ]; then
  echo "~/.nvm already exists, skipping."
  exit 0
fi

echo "==> Creating ~/.nvm directory..."
mkdir -p "$NVM_DIR"
echo "~/.nvm created. NVM is ready to use."
```

**Step 3: Run shellcheck on both scripts**

```bash
shellcheck .chezmoiscripts/run_once_02-configure-nvm.sh
# For .tmpl file, strip templates first:
sed 's/{{[^}]*}}//g' .chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl | shellcheck -
```

Expected: PASS for both.

**Step 4: Commit**

```bash
git add .chezmoiscripts/run_once_*
git commit -m "Add run_once scripts: SSH key generation and NVM directory setup"
```

---

### Task 7: Create run_onchange_ Package Install Script

Installs Homebrew packages from split Brewfiles, re-runs when any Brewfile changes.

**Files:**
- Create: `.chezmoiscripts/run_onchange_10-install-packages.sh.tmpl`

**Step 1: Create the script**

The sha256sum comments at the top form chezmoi's change-detection trigger. When any Brewfile is edited, its hash changes, the rendered script content changes, and chezmoi re-runs it.

```bash
#!/usr/bin/env bash
set -euo pipefail

# Brewfile content hashes (chezmoi change detection):
# core:      {{ include "brewfiles/Brewfile.core" | sha256sum }}
# dev:       {{ include "brewfiles/Brewfile.dev" | sha256sum }}
# apps:      {{ include "brewfiles/Brewfile.apps" | sha256sum }}
# office:    {{ include "brewfiles/Brewfile.office" | sha256sum }}
# quicklook: {{ include "brewfiles/Brewfile.quicklook" | sha256sum }}

SOURCE_DIR="{{ .chezmoi.sourceDir }}"

echo "==> Updating Homebrew..."
brew update

# Explicit install order: core tools first, then dev, apps, office, quicklook
BREWFILES=(
  "$SOURCE_DIR/brewfiles/Brewfile.core"
  "$SOURCE_DIR/brewfiles/Brewfile.dev"
  "$SOURCE_DIR/brewfiles/Brewfile.apps"
  "$SOURCE_DIR/brewfiles/Brewfile.office"
  "$SOURCE_DIR/brewfiles/Brewfile.quicklook"
)

echo "==> Installing packages from Brewfiles..."
for brewfile in "${BREWFILES[@]}"; do
  echo "    Installing from $(basename "$brewfile")..."
  brew bundle --file="$brewfile" --no-lock
done

echo "==> Package installation complete."
```

**Step 2: Verify template syntax**

```bash
sed 's/{{[^}]*}}//g' .chezmoiscripts/run_onchange_10-install-packages.sh.tmpl | shellcheck -
```

Expected: PASS.

**Step 3: Commit**

```bash
git add .chezmoiscripts/run_onchange_10-install-packages.sh.tmpl
git commit -m "Add run_onchange package install script with Brewfile content hashing"
```

---

### Task 8: Create run_onchange_ macOS Defaults Scripts

Split the monolithic macOS defaults into 6 categorized scripts. Each sources the shared helper and only restarts relevant apps.

**Files:**
- Create: `.chezmoiscripts/run_onchange_20-macos-system.sh.tmpl`
- Create: `.chezmoiscripts/run_onchange_21-macos-dock.sh.tmpl`
- Create: `.chezmoiscripts/run_onchange_22-macos-finder.sh.tmpl`
- Create: `.chezmoiscripts/run_onchange_23-macos-input.sh.tmpl`
- Create: `.chezmoiscripts/run_onchange_24-macos-safari.sh.tmpl`
- Create: `.chezmoiscripts/run_onchange_25-macos-apps.sh.tmpl`

**Step 1: Create `.chezmoiscripts/run_onchange_20-macos-system.sh.tmpl`**

General UI/UX, screen lock, locale, hostname. This is the only script that needs sudo for `scutil` and `nvram`.

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers/macos-defaults.sh
source "{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh"

echo "==> Applying macOS system defaults..."

close_system_settings
require_sudo

# Set computer name
sudo scutil --set ComputerName "{{ .data.hostname }}"
sudo scutil --set HostName "{{ .data.hostname }}"
sudo scutil --set LocalHostName "{{ .data.hostname }}"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "{{ .data.hostname }}"

# Disable the sound effects on boot
sudo nvram StartupMute=%01

# Reveal IP, hostname, OS version when clicking clock in login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Enable dark mode
set_global_default AppleInterfaceStyle string "Dark"

# Graphite accent color
set_global_default AppleAccentColor string "-1"
set_global_default AppleHighlightColor string "0.847059 0.847059 0.862745 Graphite"

# Sidebar icon size: medium
set_global_default NSTableViewDefaultSizeMode int 2

# Fast window resize
set_global_default NSWindowResizeTime float 0.001

# Expand save panel by default
set_global_default NSNavPanelExpandedStateForSaveMode bool true
set_global_default NSNavPanelExpandedStateForSaveMode2 bool true

# Expand print panel by default
set_global_default PMPrintingExpandedStateForPrint bool true
set_global_default PMPrintingExpandedStateForPrint2 bool true

# Save to disk (not iCloud) by default
set_global_default NSDocumentSaveNewDocumentsToCloud bool false

# Quit printer app when done
set_default com.apple.print.PrintingPrefs "Quit When Finished" bool true

# Disable "Are you sure you want to open this application?" dialog
set_default com.apple.LaunchServices LSQuarantine bool false

# Metric units and Celsius
set_global_default AppleMeasurementUnits string "Centimeters"
set_global_default AppleMetricUnits bool true
set_global_default AppleTemperatureUnit string "Celsius"

# Menu bar clock
set_default com.apple.menuextra.clock IsAnalog bool false
set_default com.apple.menuextra.clock DateFormat string "EEE MMM d h:mm a"

# Language and locale
defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
defaults write NSGlobalDomain AppleLocale -string "{{ .data.locale }}"

# Screen: require password immediately after sleep
set_default com.apple.screensaver askForPassword int 1
set_default com.apple.screensaver askForPasswordDelay int 0

restart_app "SystemUIServer"
restart_app "cfprefsd"

echo "==> System defaults applied."
```

**Step 2: Create `.chezmoiscripts/run_onchange_21-macos-dock.sh.tmpl`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers/macos-defaults.sh
source "{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh"

echo "==> Applying Dock defaults..."

close_system_settings

# Icon size: 36px
set_default com.apple.dock tilesize int 36

# Minimize into app icon
set_default com.apple.dock minimize-to-application bool true

# Wipe all default app icons
defaults write com.apple.dock persistent-apps -array

# Don't show recent apps
set_default com.apple.dock show-recents bool false

# Disable Dashboard
set_default com.apple.dashboard mcx-disabled bool true
set_default com.apple.dock dashboard-in-overlay bool true

# Don't auto-rearrange Spaces
set_default com.apple.dock mru-spaces bool false

# Fast Mission Control animation
set_default com.apple.dock expose-animation-duration float 0.1

# No launch animation
set_default com.apple.dock launchanim bool false

# Highlight hover for stack grid view
set_default com.apple.dock mouse-over-hilite-stack bool true

restart_app "Dock"

echo "==> Dock defaults applied."
```

**Step 3: Create `.chezmoiscripts/run_onchange_22-macos-finder.sh.tmpl`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers/macos-defaults.sh
source "{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh"

echo "==> Applying Finder defaults..."

close_system_settings

# Show hidden files
set_default com.apple.finder AppleShowAllFiles bool true

# Show all extensions
set_global_default AppleShowAllExtensions bool true

# Show status bar and path bar
set_default com.apple.finder ShowStatusBar bool true
set_default com.apple.finder ShowPathbar bool true

# Search current folder by default
set_default com.apple.finder FXDefaultSearchScope string "SCcf"

# List view by default
set_default com.apple.finder FXPreferredViewStyle string "Nlsv"

# Default location: Desktop
set_default com.apple.finder NewWindowTarget string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Folders on top when sorting
set_default com.apple.finder _FXSortFoldersFirst bool true

# Spring loading
set_global_default com.apple.springing.enabled bool true

# No warning on extension change
set_default com.apple.finder FXEnableExtensionChangeWarning bool false

# Prefer tabs always
set_global_default AppleWindowTabbingMode string "always"

# No .DS_Store on network/USB
set_default com.apple.desktopservices DSDontWriteNetworkStores bool true
set_default com.apple.desktopservices DSDontWriteUSBStores bool true

# Expand File Info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true

# Show ~/Library
chflags nohidden ~/Library 2>/dev/null || true
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

restart_app "Finder"

echo "==> Finder defaults applied."
```

**Step 4: Create `.chezmoiscripts/run_onchange_23-macos-input.sh.tmpl`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers/macos-defaults.sh
source "{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh"

echo "==> Applying input defaults..."

close_system_settings

# Blazingly fast keyboard repeat
set_global_default KeyRepeat int 1
set_global_default InitialKeyRepeat int 10

# Key repeat over press-and-hold
set_global_default ApplePressAndHoldEnabled bool false

# Disable natural scrolling
set_global_default com.apple.swipescrolldirection bool false

# Disable auto-capitalization
set_global_default NSAutomaticCapitalizationEnabled bool false

# Disable smart dashes
set_global_default NSAutomaticDashSubstitutionEnabled bool false

# Disable auto period substitution
set_global_default NSAutomaticPeriodSubstitutionEnabled bool false

# Disable smart quotes
set_global_default NSAutomaticQuoteSubstitutionEnabled bool false

# Disable auto-correct
set_global_default NSAutomaticSpellingCorrectionEnabled bool false

# Full keyboard access in all controls
set_global_default AppleKeyboardUIMode int 3

# Better Bluetooth audio quality
set_default com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" int 40

echo "==> Input defaults applied."
```

**Step 5: Create `.chezmoiscripts/run_onchange_24-macos-safari.sh.tmpl`**

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers/macos-defaults.sh
source "{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh"

echo "==> Applying Safari defaults..."

close_system_settings

# Don't send search queries to Apple
set_default com.apple.Safari UniversalSearchEnabled bool false
set_default com.apple.Safari SuppressSearchSuggestions bool true

# Show full URL
set_default com.apple.Safari ShowFullURLInSmartSearchField bool true

# Home page: about:blank
set_default com.apple.Safari HomePage string "about:blank"

# Enable Develop menu and Web Inspector
set_default com.apple.Safari IncludeDevelopMenu bool true
set_default com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey bool true
set_default com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled bool true

# Warn about fraudulent websites
set_default com.apple.Safari WarnAboutFraudulentWebsites bool true

# Auto-update extensions
set_default com.apple.Safari InstallExtensionUpdatesAutomatically bool true

restart_app "Safari"

echo "==> Safari defaults applied."
```

**Step 6: Create `.chezmoiscripts/run_onchange_25-macos-apps.sh.tmpl`**

Covers App Store, TextEdit, and other miscellaneous app defaults.

```bash
#!/usr/bin/env bash
set -euo pipefail

# shellcheck source=helpers/macos-defaults.sh
source "{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh"

echo "==> Applying app defaults..."

close_system_settings

# --- App Store ---
set_default com.apple.SoftwareUpdate AutomaticCheckEnabled bool true
set_default com.apple.SoftwareUpdate ScheduleFrequency int 1
set_default com.apple.SoftwareUpdate AutomaticDownload int 1
set_default com.apple.SoftwareUpdate CriticalUpdateInstall int 1
set_default com.apple.commerce AutoUpdate bool true

# --- TextEdit ---
# Plain text mode
set_default com.apple.TextEdit RichText int 0
# UTF-8
set_default com.apple.TextEdit PlainTextEncoding int 4
set_default com.apple.TextEdit PlainTextEncodingForWrite int 4

# --- Photos ---
# Don't open automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# --- Time Machine ---
# Don't offer new disks as backup volume
set_default com.apple.TimeMachine DoNotOfferNewDisksForBackup bool true

# --- Terminal ---
# UTF-8 only
defaults write com.apple.terminal StringEncodings -array 4

# --- Activity Monitor ---
set_default com.apple.ActivityMonitor OpenMainWindow bool true
set_default com.apple.ActivityMonitor IconType int 5
set_default com.apple.ActivityMonitor ShowCategory int 0
set_default com.apple.ActivityMonitor SortColumn string "CPUUsage"
set_default com.apple.ActivityMonitor SortDirection int 0

restart_app "Activity Monitor"

echo "==> App defaults applied."
```

**Step 7: Run shellcheck on all scripts (strip templates first)**

```bash
for f in .chezmoiscripts/run_onchange_2*.sh.tmpl; do
  echo "Checking $f..."
  sed 's/{{[^}]*}}//g' "$f" | shellcheck -
done
```

Expected: PASS for all.

**Step 8: Commit**

```bash
git add .chezmoiscripts/run_onchange_2*
git commit -m "Add categorized macOS defaults scripts: system, dock, finder, input, safari, apps"
```

---

### Task 9: Create Post-Apply Summary Script

Non-blocking verification that checks what's installed and reports what's missing.

**Files:**
- Create: `.chezmoiscripts/run_after_99-summary.sh.tmpl`

**Step 1: Create the summary script**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo ""
echo "============================================"
echo "  chezmoi apply complete"
echo "============================================"
echo ""

# --- Brew stats ---
if command -v brew &>/dev/null; then
  echo "  Homebrew: $(brew list --formula 2>/dev/null | wc -l | tr -d ' ') formulae, $(brew list --cask 2>/dev/null | wc -l | tr -d ' ') casks"
fi

# --- Git ---
if command -v git &>/dev/null; then
  GIT_NAME="$(git config --global user.name 2>/dev/null || echo 'not set')"
  GIT_EMAIL="$(git config --global user.email 2>/dev/null || echo 'not set')"
  echo "  Git:      $GIT_NAME <$GIT_EMAIL>"
fi

# --- SSH key ---
SSH_KEY="{{ .chezmoi.homeDir }}/.ssh/id_ed25519"
if [ -f "$SSH_KEY" ]; then
  echo "  SSH key:  $SSH_KEY"
else
  echo "  SSH key:  NOT FOUND — run 'chezmoi apply' or generate manually"
fi

# --- Verification: manual installs ---
echo ""
MISSING=()

check_app() {
  local name="$1" path="$2"
  if [ ! -d "$path" ]; then
    MISSING+=("$name")
  fi
}

# --- Manual-install app inventory ---
# Update this list when apps are added, removed, or renamed.

# Setapp apps
check_app "Bartender" "/Applications/Bartender 4.app"
check_app "Paste" "/Applications/Paste.app"
check_app "CleanShot X" "/Applications/CleanShot X.app"
check_app "HazeOver" "/Applications/HazeOver.app"
check_app "DevUtils" "/Applications/DevUtils.app"
check_app "Requestly" "/Applications/Requestly.app"
check_app "AlDente Pro" "/Applications/AlDente Pro.app"

# External downloads
check_app "FortiClient VPN" "/Applications/FortiClient.app"

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "  Apps not yet installed:"
  for app in "${MISSING[@]}"; do
    echo "    - $app"
  done
else
  echo "  All expected apps are installed."
fi

# --- Reminders ---
echo ""
echo "  Reminders:"
if [ -f "$SSH_KEY" ]; then
  echo "    - Add SSH key to GitHub if not done: https://github.com/settings/ssh/new"
fi
echo "    - Run 'mackup restore' to restore app settings from iCloud"
echo "    - Sign in to apps (Spotify, Slack, Arc, Chrome, etc.)"
echo "    - Restart Mac to apply all system settings"
echo ""
```

**Step 2: Verify**

```bash
sed 's/{{[^}]*}}//g' .chezmoiscripts/run_after_99-summary.sh.tmpl | shellcheck -
```

Expected: PASS.

**Step 3: Commit**

```bash
git add .chezmoiscripts/run_after_99-summary.sh.tmpl
git commit -m "Add post-apply summary with non-blocking app verification"
```

---

### Task 10: Create Bootstrap Script

The entry point for a fresh machine. Handles everything before chezmoi can take over.

**Files:**
- Create: `bin/setup.sh`

**Step 1: Create `bin/setup.sh`**

```bash
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

chezmoi init --apply fridzema
```

**Step 2: Make executable**

```bash
chmod +x bin/setup.sh
```

**Step 3: Run shellcheck**

```bash
shellcheck bin/setup.sh
```

Expected: PASS.

**Step 4: Commit**

```bash
git add bin/
git commit -m "Add bootstrap script: Xcode CLI tools, Homebrew, chezmoi init"
```

---

### Task 11: Update CI Workflow

Replace the old CI with chezmoi-aware validation.

**Files:**
- Modify: `.github/workflows/ci.yml`

Note: `.github/test-chezmoi-data.toml` was already created in Task 2.

**Step 1: Rewrite `.github/workflows/ci.yml`**

```yaml
name: ci

on:
  pull_request:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  shellcheck:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Install shellcheck
        run: brew install shellcheck
      - name: Lint pure shell scripts
        run: shellcheck bin/setup.sh helpers/macos-defaults.sh .chezmoiscripts/run_once_02-configure-nvm.sh
      - name: Lint templated shell scripts
        run: |
          for f in $(find .chezmoiscripts -name '*.sh.tmpl') dot_zshrc.tmpl; do
            echo "Checking $f..."
            sed 's/{{[^}]*}}//g' "$f" | shellcheck - || exit 1
          done

  chezmoi-verify:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Install chezmoi
        run: brew install chezmoi
      - name: Verify chezmoi source state
        run: |
          chezmoi init --source="$(pwd)" \
            --config-path=".github/test-chezmoi-data.toml" \
            --dry-run --verbose

  brewfile-lint:
    runs-on: macos-14
    steps:
      - uses: actions/checkout@v4
      - name: Validate Brewfiles
        run: |
          for f in brewfiles/Brewfile.*; do
            echo "Checking $f..."
            brew bundle check --file="$f" --verbose
          done
```

**Step 2: Commit**

```bash
git add .github/
git commit -m "Update CI: shellcheck for templates, chezmoi source verification, split Brewfile lint"
```

---

### Task 12: Update README

Replace the old README with chezmoi-oriented documentation.

**Files:**
- Modify: `README.md`

**Step 1: Rewrite `README.md`**

```markdown
# Dotfiles

Personal dotfiles managed with [chezmoi](https://www.chezmoi.io/), targeting macOS (Apple Silicon and Intel).

## Quick Start

On a fresh machine:

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/fridzema/dotfiles/main/bin/setup.sh)"
```

Or clone and run manually:

```bash
git clone https://github.com/fridzema/dotfiles.git
cd dotfiles
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
| `dot_zshrc.tmpl` | Shell configuration template |
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
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "Rewrite README for chezmoi-based workflow"
```

---

### Task 13: Update .gitignore

Update to reflect the new project structure.

**Files:**
- Modify: `.gitignore`

**Step 1: Rewrite `.gitignore`**

```
.DS_Store
*.swp
*.swo
*~
.idea/
.vscode/
```

The old `.setup-completed-steps` entry is no longer needed (chezmoi handles idempotency). Editor debris entries match `dot_gitignore_global` to protect the dotfiles repo itself.

**Step 2: Commit**

```bash
git add .gitignore
git commit -m "Simplify .gitignore for chezmoi-based structure"
```

---

### Task 14: Final Verification

Run all validation checks to confirm the migration is complete and correct.

**Step 1: Run shellcheck on all scripts**

```bash
shellcheck bin/setup.sh helpers/macos-defaults.sh .chezmoiscripts/run_once_02-configure-nvm.sh
for f in $(find .chezmoiscripts -name '*.sh.tmpl') dot_zshrc.tmpl; do
  echo "Checking $f..."
  sed 's/{{[^}]*}}//g' "$f" | shellcheck - || echo "FAIL: $f"
done
```

Expected: all PASS.

**Step 2: Verify chezmoi can process the source state**

```bash
chezmoi init --source="$(pwd)" \
  --config-path=".github/test-chezmoi-data.toml" \
  --dry-run --verbose
```

Expected: chezmoi lists all target files without errors (using fixture data for deterministic validation).

**Step 3: Validate all Brewfiles**

```bash
for f in brewfiles/Brewfile.*; do
  echo "Checking $f..."
  brew bundle check --file="$f" --verbose
done
```

Expected: valid syntax, lists installed/missing packages.

**Step 4: Verify directory structure matches design**

```bash
find . -not -path './.git/*' -not -path './.git' | sort
```

Compare against the structure in the design doc (`docs/plans/2026-03-11-chezmoi-migration-design.md`).

**Step 5: Commit any fixes if needed, then final summary commit**

If everything passes, no additional commit needed. If fixes were required, commit them individually with descriptive messages.
