# Mac Setup Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a modular set of bash scripts that fully configure a fresh M-series Mac running macOS Tahoe 26.2.

**Architecture:** A main `setup.sh` orchestrator calls individual scripts in sequence. Each script is idempotent and independently runnable. A `Brewfile` declares all brew-managed software.

**Tech Stack:** Bash, Homebrew, macOS `defaults` CLI

---

### Task 1: Create the Brewfile

**Files:**
- Create: `Brewfile`

**Step 1: Write the Brewfile**

```ruby
# Taps
tap "homebrew/bundle"

# Formulae (CLI tools)
brew "git"
brew "gh"
brew "composer"
brew "bun"
brew "nvm"
brew "yarn"
brew "mas"

# Casks (GUI apps)
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
cask "microsoft-office"

# QuickLook plugins
cask "qlmarkdown"
cask "quicklook-json"
```

**Step 2: Verify syntax**

Run: `brew bundle check --file=Brewfile 2>&1 | head -5`
Expected: Either "satisfied" or a list of missing items (both are valid — confirms parsing works)

**Step 3: Commit**

```bash
git add Brewfile
git commit -m "Add Brewfile with all formulae and casks"
```

---

### Task 2: Create scripts/install-brew.sh

**Files:**
- Create: `scripts/install-brew.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> Installing Xcode Command Line Tools..."
if ! xcode-select -p &>/dev/null; then
    xcode-select --install
    echo "    Waiting for Xcode CLI Tools installation..."
    echo "    Please complete the installation dialog, then press Enter."
    read -r
else
    echo "    Xcode CLI Tools already installed."
fi

# Accept Xcode license
sudo xcodebuild -license accept 2>/dev/null || true

echo "==> Installing Homebrew..."
if ! command -v brew &>/dev/null; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session (Apple Silicon path)
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    echo "    Homebrew already installed."
fi

echo "==> Updating Homebrew..."
brew update

echo "==> Installing packages from Brewfile..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
brew bundle --file="${SCRIPT_DIR}/../Brewfile" --no-lock

echo "==> Brew installation complete."
```

**Step 2: Make executable**

Run: `chmod +x scripts/install-brew.sh`

**Step 3: Commit**

```bash
git add scripts/install-brew.sh
git commit -m "Add brew installer with Xcode CLI tools and Brewfile bundle"
```

---

### Task 3: Create scripts/install-manual.sh

**Files:**
- Create: `scripts/install-manual.sh`

**Step 1: Write the script**

```bash
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
```

**Step 2: Make executable**

Run: `chmod +x scripts/install-manual.sh`

**Step 3: Commit**

```bash
git add scripts/install-manual.sh
git commit -m "Add manual install script for FortiClient and Apple Container"
```

---

### Task 4: Create scripts/configure-git.sh

**Files:**
- Create: `scripts/configure-git.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring Git & SSH..."

# --- Git config ---
read -rp "Enter your full name for git: " GIT_NAME
read -rp "Enter your email for git: " GIT_EMAIL

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
git config --global init.defaultBranch main
git config --global pull.rebase true

echo "    Git configured for: $GIT_NAME <$GIT_EMAIL>"

# --- SSH key ---
SSH_KEY="${HOME}/.ssh/id_ed25519"

if [ -f "$SSH_KEY" ]; then
    echo "    SSH key already exists at $SSH_KEY"
else
    echo "    Generating Ed25519 SSH key..."
    ssh-keygen -t ed25519 -C "$GIT_EMAIL" -f "$SSH_KEY"
fi

# Start ssh-agent and add key
eval "$(ssh-agent -s)"

# Create SSH config if it doesn't exist
SSH_CONFIG="${HOME}/.ssh/config"
if [ ! -f "$SSH_CONFIG" ] || ! grep -q "IdentityFile.*id_ed25519" "$SSH_CONFIG"; then
    cat >> "$SSH_CONFIG" <<EOF

Host github.com
    AddKeysToAgent yes
    UseKeychain yes
    IdentityFile ~/.ssh/id_ed25519
EOF
    echo "    SSH config updated."
fi

ssh-add --apple-use-keychain "$SSH_KEY" 2>/dev/null || ssh-add "$SSH_KEY"

# Copy public key to clipboard
pbcopy < "${SSH_KEY}.pub"
echo "    Public key copied to clipboard."

echo "    Opening GitHub SSH settings..."
open "https://github.com/settings/ssh/new"

echo "==> Git & SSH configuration complete."
echo "    ACTION REQUIRED: Paste your SSH key in the GitHub browser window."
```

**Step 2: Make executable**

Run: `chmod +x scripts/configure-git.sh`

**Step 3: Commit**

```bash
git add scripts/configure-git.sh
git commit -m "Add git config and SSH key generation script"
```

---

### Task 5: Create scripts/configure-macos.sh

**Files:**
- Create: `scripts/configure-macos.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> Applying macOS defaults..."

# Close System Settings to prevent overriding
osascript -e 'tell application "System Settings" to quit' 2>/dev/null || true

# Ask for sudo upfront
sudo -v
# Keep sudo alive
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

###############################################################################
# General UI/UX                                                               #
###############################################################################

echo "    General UI/UX..."

# Set computer name
sudo scutil --set ComputerName "Fridzema-Mac"
sudo scutil --set HostName "Fridzema-Mac"
sudo scutil --set LocalHostName "Fridzema-Mac"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "Fridzema-Mac"

# Enable dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Set accent color to Graphite
defaults write NSGlobalDomain AppleAccentColor -string "-1"
defaults write NSGlobalDomain AppleHighlightColor -string "0.847059 0.847059 0.862745 Graphite"

# Disable the sound effects on boot
sudo nvram StartupMute=%01

# Set sidebar icon size to medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Increase window resize speed for Cocoa applications
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not to iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Automatically quit printer app once print jobs complete
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable the "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Use metric units and Celsius
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"

# Set menu bar clock format
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d h:mm a"

# Set language and locale
defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
defaults write NSGlobalDomain AppleLocale -string "en_US@currency=EUR"

# Reveal IP, hostname, OS version etc. when clicking clock in login window
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

###############################################################################
# Input                                                                       #
###############################################################################

echo "    Input settings..."

# Set blazingly fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Disable press-and-hold for keys in favor of key repeat
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable "natural" scrolling
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Disable automatic capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable automatic period substitution
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Full keyboard access for all controls (e.g. Tab in modal dialogs)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

###############################################################################
# Screen                                                                      #
###############################################################################

echo "    Screen settings..."

# Require password immediately after sleep or screen saver begins
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0

###############################################################################
# Finder                                                                      #
###############################################################################

echo "    Finder settings..."

# Show hidden files by default
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all filename extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar
defaults write com.apple.finder ShowStatusBar -bool true

# Show path bar
defaults write com.apple.finder ShowPathbar -bool true

# When performing a search, search the current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# Use list view in all Finder windows by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Set default location for new Finder windows to Desktop
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Keep folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# Disable the warning when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Prefer tabs always
defaults write NSGlobalDomain AppleWindowTabbingMode -string "always"

# Avoid creating .DS_Store files on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Expand the following File Info panes:
# "General", "Open with", and "Sharing & Permissions"
defaults write com.apple.finder FXInfoPanesExpanded -dict \
    General -bool true \
    OpenWith -bool true \
    Privileges -bool true

# Show the ~/Library folder
chflags nohidden ~/Library 2>/dev/null || true
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

###############################################################################
# Dock                                                                        #
###############################################################################

echo "    Dock settings..."

# Set the icon size of Dock items to 36 pixels
defaults write com.apple.dock tilesize -int 36

# Minimize windows into their application's icon
defaults write com.apple.dock minimize-to-application -bool true

# Wipe all (default) app icons from the Dock
defaults write com.apple.dock persistent-apps -array

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true

# Don't show Dashboard as a Space
defaults write com.apple.dock dashboard-in-overlay -bool true

# Don't automatically rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false

# Speed up Mission Control animations
defaults write com.apple.dock expose-animation-duration -float 0.1

# Don't animate opening applications from the Dock
defaults write com.apple.dock launchanim -bool false

# Enable highlight hover effect for the grid view of a stack
defaults write com.apple.dock mouse-over-hilite-stack -bool true

###############################################################################
# Safari                                                                      #
###############################################################################

echo "    Safari settings..."

# Privacy: don't send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Show the full URL in the address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Set Safari's home page to about:blank
defaults write com.apple.Safari HomePage -string "about:blank"

# Enable the Develop menu and the Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Update extensions automatically
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

###############################################################################
# App Store                                                                   #
###############################################################################

echo "    App Store settings..."

# Enable the automatic update check
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true

# Check for software updates daily, not just once per week
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1

# Download newly available updates in background
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1

# Install System data files & security updates
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1

# Turn on app auto-update
defaults write com.apple.commerce AutoUpdate -bool true

###############################################################################
# TextEdit                                                                    #
###############################################################################

echo "    TextEdit settings..."

# Use plain text mode for new TextEdit documents
defaults write com.apple.TextEdit RichText -int 0

# Open and save files as UTF-8 in TextEdit
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

###############################################################################
# Other apps                                                                  #
###############################################################################

echo "    Other app settings..."

# Prevent Photos from opening automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# Prevent Time Machine from prompting to use new hard drives as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# Only use UTF-8 in Terminal.app
defaults write com.apple.terminal StringEncodings -array 4

# Activity Monitor: show main window, all processes, sort by CPU
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0

###############################################################################
# Restart affected apps                                                       #
###############################################################################

echo "    Restarting affected applications..."

for app in "Activity Monitor" "cfprefsd" "Dock" "Finder" "Safari" "SystemUIServer"; do
    killall "$app" &>/dev/null || true
done

echo "==> macOS defaults applied. Some changes require a logout/restart."
```

**Step 2: Make executable**

Run: `chmod +x scripts/configure-macos.sh`

**Step 3: Commit**

```bash
git add scripts/configure-macos.sh
git commit -m "Add macOS defaults configuration script"
```

---

### Task 6: Create scripts/configure-shell.sh

**Files:**
- Create: `scripts/configure-shell.sh`

**Step 1: Write the script**

```bash
#!/usr/bin/env bash
set -euo pipefail

echo "==> Configuring shell..."

ZSHRC="${HOME}/.zshrc"

# Back up existing .zshrc if present
if [ -f "$ZSHRC" ]; then
    cp "$ZSHRC" "${ZSHRC}.backup.$(date +%Y%m%d%H%M%S)"
    echo "    Backed up existing .zshrc"
fi

cat > "$ZSHRC" <<'ZSHRC_CONTENT'
# Homebrew
eval "$(/opt/homebrew/bin/brew shellenv)"

# Composer global binaries
export PATH="$HOME/.composer/vendor/bin:$PATH"

# Bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# NVM
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# Yarn global binaries
export PATH="$HOME/.yarn/bin:$PATH"
ZSHRC_CONTENT

echo "==> Shell configuration complete."
echo "    Written to $ZSHRC"
```

**Step 2: Make executable**

Run: `chmod +x scripts/configure-shell.sh`

**Step 3: Commit**

```bash
git add scripts/configure-shell.sh
git commit -m "Add minimal shell configuration script"
```

---

### Task 7: Create setup.sh (main orchestrator)

**Files:**
- Create: `setup.sh`

**Step 1: Write the script**

```bash
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
    echo "[1/7] Installing Homebrew and packages..."
    bash "${SCRIPT_DIR}/scripts/install-brew.sh"
    mark_done "brew"
else
    echo "[1/7] Homebrew + packages already installed. Skipping."
fi

# Step 2: Manual downloads
if ! is_done "manual"; then
    echo ""
    echo "[2/7] Installing manual downloads..."
    bash "${SCRIPT_DIR}/scripts/install-manual.sh"
    mark_done "manual"
else
    echo "[2/7] Manual downloads already done. Skipping."
fi

# Step 3: Git & SSH
if ! is_done "git"; then
    echo ""
    echo "[3/7] Configuring Git & SSH..."
    bash "${SCRIPT_DIR}/scripts/configure-git.sh"
    mark_done "git"
else
    echo "[3/7] Git & SSH already configured. Skipping."
fi

# Step 4: macOS defaults
if ! is_done "macos"; then
    echo ""
    echo "[4/7] Applying macOS defaults..."
    bash "${SCRIPT_DIR}/scripts/configure-macos.sh"
    mark_done "macos"
else
    echo "[4/7] macOS defaults already applied. Skipping."
fi

# Step 5: Shell configuration
if ! is_done "shell"; then
    echo ""
    echo "[5/7] Configuring shell..."
    bash "${SCRIPT_DIR}/scripts/configure-shell.sh"
    mark_done "shell"
else
    echo "[5/7] Shell already configured. Skipping."
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
echo "  - Install desired apps from Setapp"
echo "  - Sign in to apps (Spotify, Slack, Arc, Chrome, etc.)"
echo "  - Restart Mac to apply all settings"
echo ""
echo "  To re-run a specific step, delete the line from .setup-completed-steps"
echo "  and run this script again."
echo ""
```

**Step 2: Make executable**

Run: `chmod +x setup.sh`

**Step 3: Commit**

```bash
git add setup.sh .gitignore
git commit -m "Add main setup orchestrator with step tracking"
```

Note: also create `.gitignore` with `.setup-completed-steps` in it.

---

### Task 8: Create .gitignore and README.md

**Files:**
- Create: `.gitignore`
- Create: `README.md`

**Step 1: Write .gitignore**

```
.setup-completed-steps
.DS_Store
```

**Step 2: Write README.md**

```markdown
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
```

**Step 3: Commit**

```bash
git add .gitignore README.md
git commit -m "Add .gitignore and README"
```

---

### Task 9: Final review and test

**Step 1: Verify all files exist and are executable**

Run: `ls -la setup.sh scripts/*.sh Brewfile README.md .gitignore`
Expected: All files present, .sh files have execute permission

**Step 2: Shellcheck all scripts**

Run: `brew install shellcheck && shellcheck setup.sh scripts/*.sh`
Expected: No errors (warnings acceptable)

**Step 3: Verify Brewfile parses**

Run: `brew bundle check --file=Brewfile 2>&1 | head -3`
Expected: Valid output (not a parse error)

**Step 4: Final commit if any fixes were needed**

```bash
git add -A
git commit -m "Fix any shellcheck warnings"
```
