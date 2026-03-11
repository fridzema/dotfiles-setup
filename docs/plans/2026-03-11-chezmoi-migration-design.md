# Chezmoi Migration Design

## Overview

Major overhaul of the mac-setup dotfiles repository, migrating from custom shell scripts to chezmoi as the primary dotfiles manager. Clean-slate rewrite — all existing scripts are retired and their logic is refactored into chezmoi conventions.

## Goals

- Use chezmoi as the primary dotfiles manager
- Support macOS primarily (Apple Silicon and Intel)
- Keep the repository modular and maintainable
- Make onboarding a new machine simple and reproducible
- Fix all known bugs in the current setup
- Follow modern best practices for dotfile management

## Decisions

| Decision | Choice | Rationale |
|---|---|---|
| Migration strategy | Clean-slate rewrite | Repo is small (~20 commits, 6 scripts); avoids half-migrated limbo |
| App settings sync | Hybrid: chezmoi + mackup | chezmoi for version-controlled configs, mackup for complex/binary app preferences |
| macOS defaults | Categorized `run_onchange_` scripts + shared helper | Granular re-run control per category, DRY via shared library |
| Brewfile organization | Split by category | `Brewfile.core`, `.dev`, `.apps`, `.office`, `.quicklook` |
| Bootstrap | Minimal `bin/setup.sh` | Handles Xcode + Homebrew + chezmoi, then hands off to `chezmoi init --apply` |
| Manual installs | Non-blocking verification checks | Scripts check if apps exist, report what's missing in summary, never block |
| SSH keys | Generate fresh per machine | `run_once_` script generates, adds to macOS Keychain, copies pubkey to clipboard |
| Other secrets | macOS Keychain retrieval | `security find-generic-password` at apply time, no secrets in repo |
| CI tier | Moderate | Shellcheck, holistic template validation, Brewfile linting |
| Chezmoi source dir | Repo root | Standard layout, non-managed files excluded via `.chezmoiignore` |
| Package installation | `run_onchange_` with content hashing | Brewfile edits trigger re-apply via sha256sum in script comments |
| Apple Container build | Opt-in / manual | Not baseline machine config; gated by template variable or separate script |

## Repository Structure

```
dotfiles/
├── .chezmoi.toml.tmpl                   # Machine config prompts
├── .chezmoiignore                       # Excludes bin/, brewfiles/, helpers/, docs/, etc.
├── .chezmoiexternal.toml                # External deps (if needed)
│
├── bin/                                 # Bootstrap (ignored by chezmoi)
│   └── setup.sh                         # Xcode CLI tools -> Homebrew -> chezmoi -> apply
│
├── .chezmoiscripts/                     # Lifecycle scripts
│   ├── run_once_01-generate-ssh-key.sh.tmpl
│   ├── run_once_02-configure-nvm.sh
│   ├── run_onchange_10-install-packages.sh.tmpl
│   ├── run_onchange_20-macos-system.sh.tmpl
│   ├── run_onchange_21-macos-dock.sh.tmpl
│   ├── run_onchange_22-macos-finder.sh.tmpl
│   ├── run_onchange_23-macos-input.sh.tmpl
│   ├── run_onchange_24-macos-safari.sh.tmpl
│   ├── run_onchange_25-macos-apps.sh.tmpl
│   └── run_after_99-summary.sh.tmpl
│
├── private_dot_ssh/                     # SSH config (0700 permissions)
│   └── config.tmpl
│
├── dot_gitconfig.tmpl                   # Git config with templated user/signing
├── dot_gitignore_global                 # Global gitignore
├── dot_zshrc.tmpl                       # Shell config with templated paths
│
├── brewfiles/                           # Split Brewfiles (ignored by chezmoi)
│   ├── Brewfile.core
│   ├── Brewfile.dev
│   ├── Brewfile.apps
│   ├── Brewfile.office
│   └── Brewfile.quicklook
│
├── helpers/                             # Shared shell library (ignored by chezmoi)
│   └── macos-defaults.sh
│
├── .github/
│   ├── workflows/ci.yml
│   └── test-chezmoi-data.toml           # Dummy data for CI template validation
│
├── docs/plans/
└── README.md
```

## Configuration Data (.chezmoi.toml.tmpl)

Prompts the user on first `chezmoi init`, stores answers in `~/.config/chezmoi/chezmoi.toml`:

- `data.name` — full name (used in gitconfig)
- `data.email` — email address (used in gitconfig, SSH key comment)
- `data.hostname` — computer hostname (used in macos-system defaults)
- `data.locale` — locale string, default `en_US@currency=EUR` (used in macos-system defaults)

Template references use `{{ .data.name }}`, `{{ .data.email }}`, etc.

## Template Details

### dot_gitconfig.tmpl

Current `config/.gitconfig` content with:
- `user.name` = `{{ .data.name }}`
- `user.email` = `{{ .data.email }}`
- `user.signingkey` = `{{ .chezmoi.homeDir }}/.ssh/id_ed25519.pub` (full path, no ~ expansion)
- All other settings (editor, diff, merge, rebase, fetch, push) carried over as-is

### dot_zshrc.tmpl

- Homebrew shellenv: detect brew location via `command -v brew` or check both `/opt/homebrew/bin/brew` and `/usr/local/bin/brew`
- NVM, Bun, Composer, Yarn PATH exports carried over
- NVM sources bash_completion

### private_dot_ssh/config.tmpl

- chezmoi creates `~/.ssh` with 0700 permissions automatically via `private_` prefix
- GitHub host config with `IdentityFile {{ .chezmoi.homeDir }}/.ssh/id_ed25519`

### Secrets from Keychain

Scripts retrieve secrets at apply time via:
```bash
security find-generic-password -s "service-name" -a "account" -w 2>/dev/null
```

## Bootstrap Script (bin/setup.sh)

Minimal scope — only installs what's needed to get chezmoi running:

1. **Xcode CLI Tools** — install if missing, poll `xcode-select -p` in a loop until ready (defensive wait logic, not just polling)
2. **Homebrew** — install if missing, handle both Apple Silicon (`/opt/homebrew`) and Intel (`/usr/local`) paths
3. **chezmoi** — `brew install chezmoi` if missing, verify available before continuing
4. **Handoff** — `chezmoi init --apply yourusername`

Uses `#!/usr/bin/env bash` and `set -euo pipefail`. Fully idempotent — safe to re-run.

## Lifecycle Scripts

### run_once_ (first apply only)

**01-generate-ssh-key.sh.tmpl**
- Checks if `~/.ssh/id_ed25519` exists, skips if so
- Generates Ed25519 key with `{{ .data.email }}` as comment
- Adds to macOS Keychain via `ssh-add --apple-use-keychain`
- Copies public key to clipboard, prints instructions
- `~/.ssh` directory already exists (created by chezmoi from `private_dot_ssh/`)

**02-configure-nvm.sh**
- Creates `~/.nvm` directory if missing
- Narrow scope — just the directory creation, nothing else

### run_onchange_ (re-runs when content changes)

**10-install-packages.sh.tmpl**
- Embeds sha256sum of each Brewfile as template comments:
  ```
  # Brewfile.core hash: {{ include "brewfiles/Brewfile.core" | sha256sum }}
  # Brewfile.dev hash:  {{ include "brewfiles/Brewfile.dev" | sha256sum }}
  ```
- Runs `brew bundle --file=<file> --no-lock` for each Brewfile
- Any Brewfile edit changes the hash, triggering re-run

**20-macos-system.sh.tmpl through 25-macos-apps.sh.tmpl**
- Each sources `helpers/macos-defaults.sh` from chezmoi source path (`{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh`)
- Each covers one category of defaults (same groupings as current `configure-macos.sh`)
- Hostname uses `{{ .data.hostname }}`, locale uses `{{ .data.locale }}`
- Only restarts apps relevant to that category

### run_after_ (runs after every apply)

**99-summary.sh.tmpl**
- Non-blocking verification: checks `/Applications/AppName.app` for manual installs
- Reports installed brew formula/cask counts
- Lists any missing manual-install apps (FortiClient, Setapp apps)
- Reminds about `mackup restore`, GitHub SSH key upload, restart

### Shared Helper (helpers/macos-defaults.sh)

- `set_default domain key type value` — wrapper around `defaults write` with error handling
- `require_sudo` — prompt once, maintain with background refresh loop
- `restart_app name` — `killall` with graceful fallback
- Sourced from `{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh`

### Apple Container (opt-in)

Not part of the automatic lifecycle. Either:
- Gated by a `data.build_apple_container` boolean in `.chezmoi.toml.tmpl`
- Or provided as a standalone script in `bin/` for manual execution

## CI Pipeline

Runs on push to main + PRs, on `macos-14`:

### shellcheck
- Lint all `.sh` and `.sh.tmpl` files
- For `.tmpl` files: minimal template-stripping (simple sed, careful not to distort shell syntax)
- Covers `bin/setup.sh`, `.chezmoiscripts/`, `helpers/`

### chezmoi-verify
- Install chezmoi
- Use `.github/test-chezmoi-data.toml` with dummy values for all template variables
- Holistic validation: render the full source state rather than per-template
- Catches template syntax errors, missing variables, broken includes

### brewfile-lint
- Run `brew bundle check --file=<file> --verbose` for each file in `brewfiles/`

### Test data (.github/test-chezmoi-data.toml)

```toml
[data]
  name = "Test User"
  email = "test@example.com"
  hostname = "Test-Mac"
  locale = "en_US"
```

## Bug Fixes

| Issue | Severity | How this design fixes it |
|---|---|---|
| ~/.ssh not created before writing | High | `private_dot_ssh/` creates `~/.ssh` with correct permissions before any script runs |
| Xcode CLI tools doesn't wait | Medium | `bin/setup.sh` polls with defensive wait logic instead of trusting Enter |
| FortiClient marked complete prematurely | Medium | No false completion tracking; `run_after_99-summary.sh.tmpl` checks app existence honestly |
| ~/.nvm never created | Medium | `run_once_02-configure-nvm.sh` creates `~/.nvm` before anything needs it |
| Rerun destroys existing dotfiles | Medium | chezmoi diffs and applies changes rather than overwriting; `chezmoi diff` to review |
| Hard-coded hostname/locale | Low | Parameterized via `.chezmoi.toml.tmpl` prompts as `{{ .data.hostname }}` / `{{ .data.locale }}` |
