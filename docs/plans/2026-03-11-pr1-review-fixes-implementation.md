# PR #1 Review Fixes Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix 8 verified code review issues in the chezmoi migration PR before merge.

**Architecture:** All changes are on the `feature/chezmoi-migration` branch. Pure corrections — no new features. Each task is one logical fix (or group of related fixes) with its own commit.

**Tech Stack:** chezmoi, Go templates, Bash, GitHub Actions YAML

**Reference:** `docs/plans/2026-03-11-pr1-review-fixes-design.md`

---

### Task 1: Fix CI Pipeline (fixes 1a, 1b, 1c)

Three CI jobs are broken. Fix all in one commit since they're in the same file.

**Files:**
- Modify: `.github/workflows/ci.yml`

**Step 1: Fix chezmoi-verify job — replace grep pipeline with --config-path**

In `.github/workflows/ci.yml`, replace the entire `chezmoi-verify` job's "Verify chezmoi source state" step.

Old (broken — `grep 'name'` matches `hostname` too):
```yaml
      - name: Verify chezmoi source state
        run: |
          printf "%s\n" \
            "$(grep 'name' .github/test-chezmoi-data.toml | cut -d'"' -f2)" \
            "$(grep 'email' .github/test-chezmoi-data.toml | cut -d'"' -f2)" \
            "$(grep 'hostname' .github/test-chezmoi-data.toml | cut -d'"' -f2)" \
            "$(grep 'locale' .github/test-chezmoi-data.toml | cut -d'"' -f2)" \
          | chezmoi init --source="$(pwd)" --no-tty --dry-run --verbose
```

New:
```yaml
      - name: Verify chezmoi source state
        run: chezmoi init --source="$(pwd)" --config-path=.github/test-chezmoi-data.toml --no-tty --dry-run --verbose
```

**Step 2: Fix brewfile-lint job — replace `check` with `list`**

Old (broken — `check` fails when packages aren't installed):
```yaml
      - name: Validate Brewfiles
        run: |
          for f in brewfiles/Brewfile.*; do
            echo "Checking $f..."
            brew bundle check --file="$f" --verbose
          done
```

New:
```yaml
      - name: Validate Brewfiles
        run: |
          for f in brewfiles/Brewfile.*; do
            echo "Checking $f..."
            brew bundle list --file="$f" > /dev/null
          done
```

**Step 3: Fix shellcheck job — move dot_zshrc from templated to pure scripts**

This prepares for Task 5 where `dot_zshrc.tmpl` is renamed to `dot_zshrc`. Update both shellcheck steps now.

Old:
```yaml
      - name: Lint pure shell scripts
        run: shellcheck bin/setup.sh helpers/macos-defaults.sh .chezmoiscripts/run_once_02-configure-nvm.sh
      - name: Lint templated shell scripts
        run: |
          for f in $(find .chezmoiscripts -name '*.sh.tmpl') dot_zshrc.tmpl; do
            echo "Checking $f..."
            sed 's/{{[^}]*}}/TMPL/g' "$f" | shellcheck --exclude=SC1091 - || exit 1
          done
```

New:
```yaml
      - name: Lint pure shell scripts
        run: shellcheck bin/setup.sh helpers/macos-defaults.sh .chezmoiscripts/run_once_02-configure-nvm.sh dot_zshrc
      - name: Lint templated shell scripts
        run: |
          for f in $(find .chezmoiscripts -name '*.sh.tmpl'); do
            echo "Checking $f..."
            sed 's/{{[^}]*}}/TMPL/g' "$f" | shellcheck --exclude=SC1091 - || exit 1
          done
```

**Step 4: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "Fix CI: use --config-path for chezmoi verify, brew bundle list for lint, update shellcheck targets"
```

---

### Task 2: Fix Bootstrap Script and README (fixes 2a, 2b, 3)

The bootstrap script uses the wrong repo name and ignores local clones. The README has wrong URLs.

**Files:**
- Modify: `bin/setup.sh`
- Modify: `README.md`

**Step 1: Fix bin/setup.sh — correct repo name and detect local clone**

Replace the final section of `bin/setup.sh` (the "Initialize and apply" block).

Old:
```bash
# --- 4. Initialize and apply ---
echo "==> Running chezmoi init --apply..."
echo "    You will be prompted for configuration values on first run."
echo ""

chezmoi init --apply fridzema
```

New:
```bash
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
```

**Step 2: Fix README.md — update repo URLs**

Three URL changes:

1. The curl one-liner:

Old:
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/fridzema/dotfiles/main/bin/setup.sh)"
```

New:
```
bash -c "$(curl -fsSL https://raw.githubusercontent.com/fridzema/dotfiles-setup/main/bin/setup.sh)"
```

2. The git clone command:

Old:
```
git clone https://github.com/fridzema/dotfiles.git
cd dotfiles
```

New:
```
git clone https://github.com/fridzema/dotfiles-setup.git
cd dotfiles-setup
```

**Step 3: Commit**

```bash
git add bin/setup.sh README.md
git commit -m "Fix bootstrap: correct repo name, detect local clone, update README URLs"
```

---

### Task 3: Add Helper Content Hash to macOS Scripts (fix 4)

The 6 `run_onchange_` macOS scripts source `helpers/macos-defaults.sh` at runtime. Chezmoi only re-runs them when the rendered script content changes. Without a hash, editing the helper alone won't trigger re-execution.

**Files:**
- Modify: `.chezmoiscripts/run_onchange_20-macos-system.sh.tmpl`
- Modify: `.chezmoiscripts/run_onchange_21-macos-dock.sh.tmpl`
- Modify: `.chezmoiscripts/run_onchange_22-macos-finder.sh.tmpl`
- Modify: `.chezmoiscripts/run_onchange_23-macos-input.sh.tmpl`
- Modify: `.chezmoiscripts/run_onchange_24-macos-safari.sh.tmpl`
- Modify: `.chezmoiscripts/run_onchange_25-macos-apps.sh.tmpl`

**Step 1: Add hash comment to each script**

In each of the 6 files, add the following line immediately after `set -euo pipefail`:

```bash
# helpers/macos-defaults.sh hash: {{ include "helpers/macos-defaults.sh" | sha256sum }}
```

So the top of each file becomes:

```bash
#!/usr/bin/env bash
set -euo pipefail

# helpers/macos-defaults.sh hash: {{ include "helpers/macos-defaults.sh" | sha256sum }}

# shellcheck source=helpers/macos-defaults.sh
source "{{ .chezmoi.sourceDir }}/helpers/macos-defaults.sh"
```

Apply this to all 6 files:
- `run_onchange_20-macos-system.sh.tmpl`
- `run_onchange_21-macos-dock.sh.tmpl`
- `run_onchange_22-macos-finder.sh.tmpl`
- `run_onchange_23-macos-input.sh.tmpl`
- `run_onchange_24-macos-safari.sh.tmpl`
- `run_onchange_25-macos-apps.sh.tmpl`

**Step 2: Commit**

```bash
git add .chezmoiscripts/run_onchange_2*.sh.tmpl
git commit -m "Add helper content hash to macOS defaults scripts for change detection"
```

---

### Task 4: Quote Gitconfig Template Values (fix 5)

**Files:**
- Modify: `dot_gitconfig.tmpl`

**Step 1: Quote the user section values**

In `dot_gitconfig.tmpl`, change the first 3 lines:

Old:
```
[user]
	name = {{ .data.name }}
	email = {{ .data.email }}
	signingkey = {{ .chezmoi.homeDir }}/.ssh/id_ed25519.pub
```

New:
```
[user]
	name = "{{ .data.name }}"
	email = "{{ .data.email }}"
	signingkey = "{{ .chezmoi.homeDir }}/.ssh/id_ed25519.pub"
```

**Step 2: Commit**

```bash
git add dot_gitconfig.tmpl
git commit -m "Quote template values in gitconfig to handle special characters"
```

---

### Task 5: Rename dot_zshrc.tmpl to dot_zshrc (fix 6)

The file contains zero `{{ }}` template directives. The `.tmpl` suffix is unnecessary.

**Files:**
- Rename: `dot_zshrc.tmpl` -> `dot_zshrc`

**Step 1: Rename the file**

```bash
git mv dot_zshrc.tmpl dot_zshrc
```

**Step 2: Commit**

```bash
git commit -m "Rename dot_zshrc.tmpl to dot_zshrc (no template directives)"
```

---

### Task 6: Add .vscode/ to Global Gitignore (fix 7)

**Files:**
- Modify: `dot_gitignore_global`

**Step 1: Add .vscode/ entry**

Current content:
```
.DS_Store
.idea/
*.swp
*.swo
*~
```

New content:
```
.DS_Store
.idea/
.vscode/
*.swp
*.swo
*~
```

**Step 2: Commit**

```bash
git add dot_gitignore_global
git commit -m "Add .vscode/ to global gitignore"
```

---

### Task 7: Document SSH Key Passphrase Prompt (fix 8)

**Files:**
- Modify: `.chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl`

**Step 1: Add comment above ssh-keygen**

In `.chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl`, add a comment before the `ssh-keygen` line:

Old:
```bash
echo "==> Generating SSH key..."
ssh-keygen -t ed25519 -C "{{ .data.email }}" -f "$SSH_KEY"
```

New:
```bash
echo "==> Generating SSH key..."
# Prompts for passphrase interactively (intentional — do not add -N "")
ssh-keygen -t ed25519 -C "{{ .data.email }}" -f "$SSH_KEY"
```

**Step 2: Commit**

```bash
git add .chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl
git commit -m "Document intentional passphrase prompt in SSH key generation"
```

---

### Task 8: Final Verification

**Step 1: Verify all changes look correct**

```bash
git log --oneline main..HEAD
```

Expected: 7 new commits on top of the existing branch commits.

**Step 2: Verify CI file parses correctly**

```bash
python3 -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yml'))" && echo "YAML OK"
```

**Step 3: Verify dot_zshrc rename succeeded**

```bash
ls dot_zshrc && ! ls dot_zshrc.tmpl 2>/dev/null && echo "Rename OK"
```

**Step 4: Verify no template directives in dot_zshrc**

```bash
grep -c '{{' dot_zshrc && echo "FAIL: still has templates" || echo "OK: no templates"
```

**Step 5: Verify helper hash is in all 6 macOS scripts**

```bash
grep -l 'macos-defaults.sh hash' .chezmoiscripts/run_onchange_2*.sh.tmpl | wc -l
```

Expected: `6`
