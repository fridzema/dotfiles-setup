# PR #1 Review Fixes Design

## Overview

Fix 8 verified issues found during code review of PR #1 (Migrate to chezmoi-based dotfiles management). All fixes are corrections to existing code — no new features.

## Findings and Fixes

### 1a. CI chezmoi-verify grep bug (High)

`grep 'name'` in ci.yml also matches `hostname`, producing 5 lines instead of 4. Chezmoi receives corrupted prompt answers (`email = "Test-Mac"`, `hostname = "test@example.com"`).

**Fix:** Replace grep/printf pipeline with `chezmoi init --config-path=.github/test-chezmoi-data.toml`.

### 1b. CI brewfile-lint always fails on CI (High)

`brew bundle check` exits non-zero when packages aren't installed. Clean CI runners have nothing installed.

**Fix:** Replace `brew bundle check` with `brew bundle list` (parses syntax, doesn't check install state).

### 1c. CI shellcheck after zshrc rename

Once `dot_zshrc.tmpl` is renamed to `dot_zshrc` (fix 6), move it from the templated-script loop to the pure-script shellcheck line.

### 2a. Wrong repo in chezmoi init (High)

`chezmoi init --apply fridzema` resolves to `fridzema/dotfiles` by convention. Repo is `fridzema/dotfiles-setup`.

**Fix:** Use `chezmoi init --apply fridzema/dotfiles-setup`.

### 2b. Local clone ignored (High)

`bin/setup.sh` always fetches from GitHub even when run from a local clone.

**Fix:** Detect if running from a chezmoi source directory (presence of `.chezmoi.toml.tmpl`) and use `--source` flag.

### 3. README wrong repo URLs (High)

README references `fridzema/dotfiles` in curl and clone commands.

**Fix:** Update to `fridzema/dotfiles-setup`.

### 4. Helper changes not detected (Medium)

The 6 macOS `run_onchange_` scripts source `helpers/macos-defaults.sh` at runtime, but chezmoi only tracks rendered script content. Editing the helper won't trigger re-execution.

**Fix:** Add `{{ include "helpers/macos-defaults.sh" | sha256sum }}` hash comment to each script.

### 5. Unquoted gitconfig template values (Medium)

`name = {{ .data.name }}` in `dot_gitconfig.tmpl` could break with special characters.

**Fix:** Quote: `name = "{{ .data.name }}"`.

### 6. dot_zshrc.tmpl needlessly templated (Low)

Contains zero `{{ }}` directives. The `.tmpl` suffix causes unnecessary template processing.

**Fix:** Rename to `dot_zshrc`.

### 7. Missing .vscode/ in global gitignore (Low)

Repo's `.gitignore` has `.vscode/` but `dot_gitignore_global` does not.

**Fix:** Add `.vscode/` entry.

### 8. SSH keygen interactive prompt undocumented (Low)

`ssh-keygen` without `-N` prompts for passphrase. This is intentionally secure behavior.

**Fix:** Add comment documenting the intentional interactive prompt.

## Files Changed

| File | Fixes |
|---|---|
| `.github/workflows/ci.yml` | 1a, 1b, 1c |
| `bin/setup.sh` | 2a, 2b |
| `README.md` | 3 |
| `.chezmoiscripts/run_onchange_20-macos-system.sh.tmpl` | 4 |
| `.chezmoiscripts/run_onchange_21-macos-dock.sh.tmpl` | 4 |
| `.chezmoiscripts/run_onchange_22-macos-finder.sh.tmpl` | 4 |
| `.chezmoiscripts/run_onchange_23-macos-input.sh.tmpl` | 4 |
| `.chezmoiscripts/run_onchange_24-macos-safari.sh.tmpl` | 4 |
| `.chezmoiscripts/run_onchange_25-macos-apps.sh.tmpl` | 4 |
| `dot_gitconfig.tmpl` | 5 |
| `dot_zshrc.tmpl` -> `dot_zshrc` | 6 |
| `dot_gitignore_global` | 7 |
| `.chezmoiscripts/run_once_01-generate-ssh-key.sh.tmpl` | 8 |
