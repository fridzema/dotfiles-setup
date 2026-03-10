# Mac Setup Design

Fresh Mac setup for M-series running macOS Tahoe 26.2. Modular bash scripts orchestrated by a single `setup.sh`.

## Project Structure

```
mac-setup/
├── setup.sh                  # Main orchestrator
├── Brewfile                  # All brew formulae and casks
├── scripts/
│   ├── install-brew.sh       # Install Homebrew
│   ├── install-manual.sh     # Parallel downloads for non-brew apps
│   ├── configure-git.sh      # SSH key gen + git config
│   ├── configure-macos.sh    # macOS defaults tweaks
│   └── configure-shell.sh    # Minimal .zshrc setup
└── README.md
```

## Software Installation

### Via Brewfile

**Formulae (CLI):**
- git, gh
- composer
- bun
- nvm
- yarn
- mas (Mac App Store CLI)

**Casks (GUI):**
- warp (terminal)
- arc, google-chrome (browsers)
- zed (IDE)
- setapp
- github (GitHub Desktop)
- spotify
- herd (Laravel dev environment)
- upscayl (image upscaler)
- slack
- betterdisplay
- imageoptim
- ray (Laravel debug)
- tinkerwell (PHP tinker GUI)
- qlmarkdown, quicklook-json (QuickLook plugins)
- microsoft-office (Word, Excel, PowerPoint, Outlook, OneNote, Teams)

### Manual Downloads

- **FortiClient VPN** - not in brew; script opens download page in browser
- **Apple Container** - clone github.com/apple/container + build with Swift
- **Xcode CLI Tools** - `xcode-select --install`

## macOS Defaults

### General UI/UX
- Set computer name to "Fridzema-Mac"
- Enable dark mode
- Set accent color to Graphite
- Disable boot sound (`sudo nvram StartupMute=%01`)
- Set sidebar icon size to medium
- Expand save panel by default
- Expand print panel by default
- Save to disk (not iCloud) by default
- Disable "Are you sure you want to open this application?" dialog
- Increase window resize speed
- Use metric units + Celsius
- Menu bar clock format: "EEE MMM d h:mm a"

### Input
- KeyRepeat=1, InitialKeyRepeat=10
- Disable press-and-hold for keys (favor key repeat)
- Disable "natural" scrolling
- Disable autocorrect
- Disable smart quotes
- Disable smart dashes
- Disable automatic capitalization
- Disable automatic period substitution
- Disable dictionary lookup
- Full keyboard access for all controls
- Bluetooth audio quality boost (bitpool min 40)

### Screen
- Require password immediately after sleep or screen saver

### Finder
- Show hidden files always
- Show all filename extensions
- Show status bar
- Show path bar
- Search current folder by default
- List view by default
- Set default location for new windows to Desktop
- Keep folders on top when sorting by name
- Enable spring loading for directories
- Disable warning when changing file extension
- Prefer tabs (always)
- Avoid .DS_Store on network/USB volumes
- Expand "General", "Open with", "Sharing & Permissions" info panes
- Show ~/Library folder

### Dock
- Icon size 36px
- Minimize windows into app icon
- Wipe all default app icons
- Don't show recent apps
- Disable Dashboard
- Don't show Dashboard as a Space
- Don't automatically rearrange Spaces by recent use
- Speed up Mission Control animations
- Don't animate opening apps from Dock

### Safari
- Don't send search queries to Apple
- Show full URL in address bar
- Home page set to `about:blank`
- Enable Develop menu + Web Inspector

### App Store
- Enable automatic update check
- Check for updates daily
- Download updates in background
- Install system data files & security updates
- Auto-update apps

### TextEdit
- Plain text mode for new documents
- Open and save as UTF-8

### Other
- Prevent Photos auto-opening on device plug-in
- Prevent Time Machine prompting for new drives
- UTF-8 only in Terminal.app
- Activity Monitor: show all processes, sort by CPU

## Git & SSH Setup
- Prompt for name and email
- Generate Ed25519 SSH key
- Add to ssh-agent
- Copy public key to clipboard
- Open GitHub SSH settings page

## Shell Configuration
- Minimal .zshrc (Warp handles prompt/completions)
- PATH exports for brew, composer, bun, nvm

## Execution Order
1. Xcode CLI Tools (install + accept license)
2. Homebrew (install, add to PATH)
3. Brewfile (`brew bundle`)
4. Manual downloads (FortiClient browser page, Apple Container clone+build)
5. Git & SSH (prompt name/email, generate key, copy to clipboard)
6. macOS defaults (apply all tweaks)
7. Minimal .zshrc (PATH exports)
8. Restart Dock/Finder (apply visual changes)
9. Print summary (successes + manual action items)

Each script is idempotent and can be re-run independently. Main script tracks completed steps.
