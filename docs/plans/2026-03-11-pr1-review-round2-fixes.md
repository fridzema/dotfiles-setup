# PR #1 Review Round 2 Fixes

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 5 verified issues from second code review before merge.

**Architecture:** All changes are on the `feature/chezmoi-migration` branch (worktree at `.worktrees/chezmoi-migration`). Pure corrections — no new features. Each task is one logical fix with its own commit.

**Tech Stack:** chezmoi, Go templates, Bash, GitHub Actions YAML

---

### Task 1: Fix Template Data Paths (Critical)

All templates use `.data.name`, `.data.email`, etc. but chezmoi exposes `[data]` section values at the template root as `.name`, `.email`. Verified locally: `chezmoi apply` fails with `map has no entry for key "data"`.

Also fix `.chezmoi.toml.tmpl` which uses `promptStringOnce . "data.name"` — should be `promptStringOnce . "name"`.

**Files:**
- Modify: `.chezmoi.toml.tmpl`
- Modify: `dot_gitconfig.tmpl`
- Modify: `.chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl`
- Modify: `.chezmoiscripts/run_onchange_20-macos-system.sh.tmpl`

**Step 1: Fix `.chezmoi.toml.tmpl` — remove `data.` prefix from promptStringOnce keys**

Old:
```
{{- $name := promptStringOnce . "data.name" "Full name" -}}
{{- $email := promptStringOnce . "data.email" "Email address" -}}
{{- $hostname := promptStringOnce . "data.hostname" "Computer hostname" -}}
{{- $locale := promptStringOnce . "data.locale" "Locale" "en_US@currency=EUR" -}}
```

New:
```
{{- $name := promptStringOnce . "name" "Full name" -}}
{{- $email := promptStringOnce . "email" "Email address" -}}
{{- $hostname := promptStringOnce . "hostname" "Computer hostname" -}}
{{- $locale := promptStringOnce . "locale" "Locale" "en_US@currency=EUR" -}}
```

**Step 2: Fix `dot_gitconfig.tmpl` — change `.data.X` to `.X`**

Old:
```
	name = "{{ .data.name }}"
	email = "{{ .data.email }}"
```

New:
```
	name = "{{ .name }}"
	email = "{{ .email }}"
```

**Step 3: Fix `.chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl` — change `.data.email` to `.email`**

Old:
```bash
ssh-keygen -t ed25519 -C "{{ .data.email }}" -f "$SSH_KEY"
```

New:
```bash
ssh-keygen -t ed25519 -C "{{ .email }}" -f "$SSH_KEY"
```

**Step 4: Fix `.chezmoiscripts/run_onchange_20-macos-system.sh.tmpl` — change all `.data.X` to `.X`**

5 replacements — change `.data.hostname` to `.hostname` (4 occurrences) and `.data.locale` to `.locale` (1 occurrence):

Old (lines 15-18):
```bash
sudo scutil --set ComputerName "{{ .data.hostname }}"
sudo scutil --set HostName "{{ .data.hostname }}"
sudo scutil --set LocalHostName "{{ .data.hostname }}"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "{{ .data.hostname }}"
```

New:
```bash
sudo scutil --set ComputerName "{{ .hostname }}"
sudo scutil --set HostName "{{ .hostname }}"
sudo scutil --set LocalHostName "{{ .hostname }}"
sudo defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "{{ .hostname }}"
```

Old (line 67):
```bash
defaults write NSGlobalDomain AppleLocale -string "{{ .data.locale }}"
```

New:
```bash
defaults write NSGlobalDomain AppleLocale -string "{{ .locale }}"
```

**Step 5: Update `.github/test-chezmoi-data.toml` — move values out of `[data]` section**

Since `promptStringOnce` now uses flat keys (`"name"` not `"data.name"`), the test config must match. Values under `[data]` in chezmoi config map to `.name` (not `.data.name`), so the test file is actually correct as-is for `chezmoi apply --config=`. No change needed here.

**Step 6: Verify locally**

```bash
cd /tmp && rm -rf chezmoi-verify && mkdir chezmoi-verify
cp -r /path/to/worktree/{.chezmoi.toml.tmpl,dot_gitconfig.tmpl,.chezmoiscripts,helpers,dot_zshrc,private_dot_ssh,brewfiles,.chezmoiignore} chezmoi-verify/ 2>/dev/null || true
HOME=/tmp/chezmoi-verify-home chezmoi apply --source=/tmp/chezmoi-verify --config=.github/test-chezmoi-data.toml --no-tty --dry-run 2>&1 | head -20
```

Expected: No `map has no entry for key "data"` errors. Should show diffs or succeed cleanly.

**Step 7: Commit**

```bash
git add .chezmoi.toml.tmpl dot_gitconfig.tmpl .chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl .chezmoiscripts/run_onchange_20-macos-system.sh.tmpl
git commit -m "Fix template data paths: use .name instead of .data.name for chezmoi compatibility"
```

---

### Task 2: Fix CI Pipeline — Both Broken Jobs (Critical)

Two CI jobs are broken:

1. **shellcheck job** (`ci.yml:17`): `dot_zshrc` sources dynamic Homebrew paths on lines 18-19, triggering SC1091. Need to exclude SC1091 for `dot_zshrc`.

2. **chezmoi-verify job** (`ci.yml:32`): Uses `chezmoi init` which hits `promptStringOnce` → EOF in non-interactive CI. Also uses `--config-path` (write path) instead of `--config` (read path). Must use `chezmoi apply --config=` instead, which skips the config template entirely.

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Fix shellcheck job — exclude SC1091 for dot_zshrc**

Old (`ci.yml:17`):
```yaml
        run: shellcheck bin/setup.sh helpers/macos-defaults.sh .chezmoiscripts/run_once_02-configure-nvm.sh dot_zshrc
```

New:
```yaml
        run: |
          shellcheck bin/setup.sh helpers/macos-defaults.sh .chezmoiscripts/run_once_02-configure-nvm.sh
          shellcheck --exclude=SC1091 dot_zshrc
```

**Step 2: Fix chezmoi-verify job — use `chezmoi apply` with `--config`**

Old (`ci.yml:32`):
```yaml
        run: chezmoi init --source="$(pwd)" --config-path=.github/test-chezmoi-data.toml --no-tty --dry-run --verbose
```

New:
```yaml
        run: chezmoi apply --source="$(pwd)" --config=.github/test-chezmoi-data.toml --no-tty --dry-run --verbose
```

**Step 3: Verify YAML parses**

```bash
ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")' 2>/dev/null && echo "YAML OK"
```

**Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "Fix CI: exclude SC1091 for dot_zshrc, use chezmoi apply instead of init for verify"
```

---

### Task 3: Fix README Stale Reference (Important)

README structure table still says `dot_zshrc.tmpl` — was renamed to `dot_zshrc` in a previous commit.

**Files:**
- Modify: `README.md`

**Step 1: Update structure table**

Old (line 50):
```
| `dot_zshrc.tmpl` | Shell configuration template |
```

New:
```
| `dot_zshrc` | Shell configuration |
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "Fix README: update dot_zshrc.tmpl reference to dot_zshrc"
```

---

### Task 4: Add Error Handling to require_sudo (Important)

`require_sudo()` in `helpers/macos-defaults.sh` silently continues if sudo auth fails, causing confusing downstream errors.

**Files:**
- Modify: `helpers/macos-defaults.sh`

**Step 1: Add error check**

Old (lines 15-17):
```bash
require_sudo() {
  sudo -v
}
```

New:
```bash
require_sudo() {
  if ! sudo -v; then
    echo "ERROR: sudo authentication required. Aborting." >&2
    exit 1
  fi
}
```

**Step 2: Commit**

```bash
git add helpers/macos-defaults.sh
git commit -m "Add error handling to require_sudo helper"
```

---

### Task 5: Final Verification

**Step 1: Verify commit history**

```bash
git log --oneline main..HEAD
```

Expected: 4 new commits on top of the existing branch commits.

**Step 2: Verify template paths work**

```bash
grep -r '\.data\.' --include='*.tmpl' . | grep -v '\.git' | grep -v 'chezmoi\.data'
```

Expected: No matches (all `.data.X` references should be gone, except `.chezmoi.data` if any).

**Step 3: Verify shellcheck passes on dot_zshrc**

```bash
shellcheck --exclude=SC1091 dot_zshrc && echo "shellcheck OK"
```

**Step 4: Verify YAML is valid**

```bash
ruby -ryaml -e 'YAML.load_file(".github/workflows/ci.yml")' 2>/dev/null && echo "YAML OK"
```
