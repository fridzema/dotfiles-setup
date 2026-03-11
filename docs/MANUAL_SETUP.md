# Manual Mac Setup Guide

Everything the automated chezmoi setup does, broken out into copy-pasteable steps. Use this if you want to understand what's happening or prefer doing it yourself.

Run sections in order. Later steps depend on earlier ones (shell config needs Homebrew, etc.).

---

## 1. Prerequisites

### Xcode command line tools

```bash
xcode-select --install
```

### Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

After installation, add Homebrew to your PATH for the current session:

```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

---

## 2. Software installation

### Core CLI tools

```bash
brew install git gh mas mackup
```

### Development tools and package managers

```bash
brew install composer bun nvm yarn
```

### GUI applications

```bash
brew install --cask warp arc google-chrome zed setapp github spotify herd upscayl slack betterdisplay imageoptim ray tinkerwell
```

### Microsoft office

```bash
brew install --cask microsoft-office
```

### QuickLook plugins

```bash
brew install --cask qlmarkdown quicklook-json
```

---

## 3. Shell configuration

Create/replace `~/.zshrc` with:

```bash
cat > ~/.zshrc << 'EOF'
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
EOF
```

Reload your shell:

```bash
source ~/.zshrc
```

---

## 4. Git configuration

Replace `YOUR_NAME`, `YOUR_EMAIL` with your actual values.

```bash
# User
git config --global user.name "YOUR_NAME"
git config --global user.email "YOUR_EMAIL"
git config --global user.signingkey "$HOME/.ssh/id_ed25519.pub"

# Core
git config --global core.editor "zed --wait"
git config --global core.commentchar ";"
git config --global core.ignorecase false
git config --global core.excludesfile "$HOME/.gitignore_global"

# Branching & push
git config --global init.defaultBranch main
git config --global branch.autosetuprebase always
git config --global push.autosetupremote true
git config --global push.default simple

# Pull & rebase
git config --global pull.rebase true
git config --global pull.autostash true
git config --global rebase.autosquash true
git config --global rebase.autostash true

# Fetch
git config --global fetch.prune true
git config --global fetch.prunetags true

# Diff & merge tool (Zed)
git config --global diff.tool zed
git config --global difftool.zed.cmd 'zed --diff "$LOCAL" "$REMOTE"'
git config --global merge.tool zed
git config --global mergetool.zed.cmd 'zed --merge "$LOCAL" "$REMOTE" "$BASE" "$MERGED"'

# SSH commit signing
git config --global gpg.format ssh
git config --global commit.gpgsign true
git config --global tag.gpgsign true
git config --global tag.sort "-taggerdate:iso"
```

### Global gitignore

```bash
cat > ~/.gitignore_global << 'EOF'
.DS_Store
.idea/
.vscode/
*.swp
*.swo
*~
EOF
```

---

## 5. SSH setup

### Generate key

```bash
ssh-keygen -t ed25519 -C "YOUR_EMAIL" -f ~/.ssh/id_ed25519
```

You'll be prompted for a passphrase. Use a strong one.

### Add to keychain

```bash
eval "$(ssh-agent -s)"
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

### SSH config

```bash
mkdir -p ~/.ssh && cat > ~/.ssh/config << 'EOF'
Host github.com
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_ed25519
EOF
chmod 600 ~/.ssh/config
```

### Add to GitHub

Copy your public key to clipboard:

```bash
pbcopy < ~/.ssh/id_ed25519.pub
```

Open <https://github.com/settings/ssh/new> and paste your public key.

---

## 6. macOS system preferences

Close System Settings before running these commands, otherwise your changes may get overwritten.

### System

```bash
# Set computer name (replace MY_HOSTNAME)
sudo scutil --set ComputerName "MY_HOSTNAME"
sudo scutil --set HostName "MY_HOSTNAME"
sudo scutil --set LocalHostName "MY_HOSTNAME"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "MY_HOSTNAME"

# Disable startup sound
sudo nvram StartupMute=%01

# Show host info on login window clock
sudo defaults write /Library/Preferences/com.apple.loginwindow AdminHostInfo HostName

# Dark mode
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"

# Graphite accent & highlight color
defaults write NSGlobalDomain AppleAccentColor -string "-1"
defaults write NSGlobalDomain AppleHighlightColor -string "0.847059 0.847059 0.862745 Graphite"

# Sidebar icon size: medium
defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 2

# Fast window resize animation
defaults write NSGlobalDomain NSWindowResizeTime -float 0.001

# Expand save panel by default
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Expand print panel by default
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# Save to disk (not iCloud) by default
defaults write NSGlobalDomain NSDocumentSaveNewDocumentsToCloud -bool false

# Quit printer app when done
defaults write com.apple.print.PrintingPrefs "Quit When Finished" -bool true

# Disable "Are you sure you want to open this application?" dialog
defaults write com.apple.LaunchServices LSQuarantine -bool false

# Metric units and Celsius
defaults write NSGlobalDomain AppleMeasurementUnits -string "Centimeters"
defaults write NSGlobalDomain AppleMetricUnits -bool true
defaults write NSGlobalDomain AppleTemperatureUnit -string "Celsius"

# Menu bar clock format
defaults write com.apple.menuextra.clock IsAnalog -bool false
defaults write com.apple.menuextra.clock DateFormat -string "EEE MMM d h:mm a"

# Language and locale (adjust locale to your preference)
defaults write NSGlobalDomain AppleLanguages -array "en" "nl"
defaults write NSGlobalDomain AppleLocale -string "en_NL"

# Require password immediately after sleep
defaults write com.apple.screensaver askForPassword -int 1
defaults write com.apple.screensaver askForPasswordDelay -int 0
```

### Dock

```bash
# Icon size: 36px
defaults write com.apple.dock tilesize -int 36

# Minimize into app icon
defaults write com.apple.dock minimize-to-application -bool true

# Wipe all default app icons from the Dock
defaults write com.apple.dock persistent-apps -array

# Don't show recent apps
defaults write com.apple.dock show-recents -bool false

# Disable Dashboard
defaults write com.apple.dashboard mcx-disabled -bool true
defaults write com.apple.dock dashboard-in-overlay -bool true

# Don't auto-rearrange Spaces based on recent use
defaults write com.apple.dock mru-spaces -bool false

# Fast Mission Control animation
defaults write com.apple.dock expose-animation-duration -float 0.1

# No launch animation
defaults write com.apple.dock launchanim -bool false

# Highlight hover effect for stack grid view
defaults write com.apple.dock mouse-over-hilite-stack -bool true

# Restart Dock to apply
killall Dock
```

### Finder

```bash
# Show hidden files
defaults write com.apple.finder AppleShowAllFiles -bool true

# Show all file extensions
defaults write NSGlobalDomain AppleShowAllExtensions -bool true

# Show status bar and path bar
defaults write com.apple.finder ShowStatusBar -bool true
defaults write com.apple.finder ShowPathbar -bool true

# Search current folder by default
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# List view by default
defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"

# Default location: Desktop
defaults write com.apple.finder NewWindowTarget -string "PfDe"
defaults write com.apple.finder NewWindowTargetPath -string "file://${HOME}/Desktop/"

# Folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# Enable spring loading for directories
defaults write NSGlobalDomain com.apple.springing.enabled -bool true

# No warning when changing file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Prefer tabs: always
defaults write NSGlobalDomain AppleWindowTabbingMode -string "always"

# Don't write .DS_Store on network or USB volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# Expand File Info panes
defaults write com.apple.finder FXInfoPanesExpanded -dict \
  General -bool true \
  OpenWith -bool true \
  Privileges -bool true

# Show ~/Library folder
chflags nohidden ~/Library 2>/dev/null || true
xattr -d com.apple.FinderInfo ~/Library 2>/dev/null || true

# Restart Finder to apply
killall Finder
```

### Input

```bash
# Fast keyboard repeat rate
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

# Key repeat instead of press-and-hold character picker
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Disable natural scrolling (scroll follows finger by default, this inverts it)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false

# Disable auto-capitalization
defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false

# Disable smart dashes
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false

# Disable auto period substitution ("." on double space)
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# Disable smart quotes
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false

# Disable auto-correct
defaults write NSGlobalDomain NSAutomaticSpellingCorrectionEnabled -bool false

# Full keyboard access in all controls (Tab navigates all UI elements)
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Better Bluetooth audio quality
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40
```

### Safari

```bash
# Don't send search queries to Apple
defaults write com.apple.Safari UniversalSearchEnabled -bool false
defaults write com.apple.Safari SuppressSearchSuggestions -bool true

# Show full URL in address bar
defaults write com.apple.Safari ShowFullURLInSmartSearchField -bool true

# Home page: blank
defaults write com.apple.Safari HomePage -string "about:blank"

# Enable Develop menu and Web Inspector
defaults write com.apple.Safari IncludeDevelopMenu -bool true
defaults write com.apple.Safari WebKitDeveloperExtrasEnabledPreferenceKey -bool true
defaults write com.apple.Safari com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled -bool true

# Warn about fraudulent websites
defaults write com.apple.Safari WarnAboutFraudulentWebsites -bool true

# Auto-update extensions
defaults write com.apple.Safari InstallExtensionUpdatesAutomatically -bool true

# Restart Safari to apply
killall Safari 2>/dev/null || true
```

### Apps

```bash
# --- App Store ---
# Check for updates daily
defaults write com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
defaults write com.apple.SoftwareUpdate AutomaticDownload -int 1
defaults write com.apple.SoftwareUpdate CriticalUpdateInstall -int 1
defaults write com.apple.commerce AutoUpdate -bool true

# --- TextEdit ---
# Plain text mode with UTF-8
defaults write com.apple.TextEdit RichText -int 0
defaults write com.apple.TextEdit PlainTextEncoding -int 4
defaults write com.apple.TextEdit PlainTextEncodingForWrite -int 4

# --- Photos ---
# Don't open automatically when devices are plugged in
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true

# --- Time Machine ---
# Don't offer new disks as backup volume
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true

# --- Terminal ---
# UTF-8 only
defaults write com.apple.terminal StringEncodings -array 4

# --- Activity Monitor ---
# Show main window on launch, CPU usage in Dock icon, all processes, sort by CPU
defaults write com.apple.ActivityMonitor OpenMainWindow -bool true
defaults write com.apple.ActivityMonitor IconType -int 5
defaults write com.apple.ActivityMonitor ShowCategory -int 0
defaults write com.apple.ActivityMonitor SortColumn -string "CPUUsage"
defaults write com.apple.ActivityMonitor SortDirection -int 0
```

### Apply system and UI changes

```bash
killall SystemUIServer 2>/dev/null || true
killall cfprefsd 2>/dev/null || true
```

Some settings won't take effect until you restart.

---

## 7. Additional software

These apps aren't in Homebrew. Install them manually.

### Setapp apps

Setapp itself is installed via Homebrew above. Open it and install these:

- **Bartender** — menu bar management
- **Paste** — clipboard manager
- **CleanShot X** — screenshots & recording
- **HazeOver** — dim background windows
- **DevUtils** — developer utilities
- **Requestly** — HTTP request interception
- **AlDente Pro** — battery charge limiter

### External downloads

- **FortiClient VPN** — download from [fortinet.com](https://www.fortinet.com/support/product-downloads)

---

## 8. Post-setup

- [ ] Add SSH key to GitHub: <https://github.com/settings/ssh/new> (if not done in step 5)
- [ ] Run `mackup restore` to pull app settings from iCloud
- [ ] Sign in to apps (Spotify, Slack, Arc, Chrome, etc.)
- [ ] Restart your Mac so all system settings take effect
