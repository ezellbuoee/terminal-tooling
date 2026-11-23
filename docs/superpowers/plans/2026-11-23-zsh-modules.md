# zsh modules installer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace "copy the author's .zshrc" with a one-line hook plus opt-in/opt-out modules under `~/.config/terminal-tooling/`, and let users skip any module or config folder.

**Architecture:** A zsh loader (`zsh/init.zsh`) sources numbered modules unless `local.zsh` disables them. `install.sh` gains `--skip/--only`, installs the loader + modules, creates `local.zsh` once, and appends a single marked line to `~/.zshrc`. Tests are plain bash scripts that run the installer against a throwaway `$HOME`.

**Tech Stack:** bash 3.2 (macOS default) for installer/tests, zsh 5.9 for modules, rsync.

**Spec:** `docs/superpowers/specs/2026-11-23-zsh-modules-design.md`

## Global Constraints

- Installer must run under macOS `/bin/bash` 3.2 (no associative arrays, no `readarray`).
- The only edit to a user's `~/.zshrc` is appending the managed block below, exactly once:
  ```
  # terminal-tooling (managed line; remove to opt out entirely)
  [[ -f ~/.config/terminal-tooling/init.zsh ]] && source ~/.config/terminal-tooling/init.zsh
  ```
- `~/.config/terminal-tooling/local.zsh` is never overwritten once it exists.
- Unit names: `shell` (the hook + loader), zsh modules `omz tools ghostty fzf keys mouse yazi starship`,
  folders `ghostty-config zellij yazi-config nvim lazygit btop starship-config wallpapers`.
- `home/.zshrc`, `home/.antigen.zsh`, `config/zsh/` are deleted from the repo.
- `VERSION` becomes `2.0.0`.

## Review Focus

1. `~/.zshrc` that already has the managed line (re-run / 1.x upgrade) must not get a second copy → test in Task 2.
2. No `~/.zshrc` at all → one is created holding only the block → test in Task 2.
3. `--skip nvim` must leave `~/.config/nvim` byte-identical and create no backup of it → test in Task 2.
4. A module whose tool is missing (`starship` not on PATH) must not print errors at shell start → test in Task 1.
5. `--only` and `--skip` given together, or an unknown name → installer exits 2 with a usage message, changes nothing → test in Task 2.

---

### Task 1: Loader and modules

**Files:**
- Create: `zsh/init.zsh`, `zsh/local.zsh.example`, `zsh/modules/{10-omz,20-tools,30-ghostty,40-fzf,50-keys,60-mouse,70-yazi,90-starship}.zsh`
- Move: `config/zsh/mouse.zsh` → `zsh/modules/60-mouse.zsh` (`git mv`)
- Delete: `home/.zshrc`, `home/.antigen.zsh`
- Test: `tests/test_loader.sh`

**Interfaces:**
- Produces: `zsh/init.zsh` sourced from any `.zshrc`. Reads `TT_DIR` (default `${0:A:h}`), sources `$TT_DIR/local.zsh` if present, then every `$TT_DIR/modules/NN-name.zsh` whose `name` is not in array `TT_DISABLE` and, when `TT_ONLY` is non-empty, is in `TT_ONLY`. After modules, calls `tt_after` if that function is defined. Exports `TT_LOADED` as the space-separated list of names sourced (used by tests).

- [ ] **Step 1: Write the failing test** `tests/test_loader.sh` (bash; uses `zsh -f` with `TT_DIR` pointing at the repo's `zsh/` and `HOME` set to a temp dir):

```bash
# 1. default: all eight names in TT_LOADED, in order
# 2. TT_DISABLE=(mouse starship) via a temp local.zsh → both absent from TT_LOADED
# 3. TT_ONLY=(tools) → TT_LOADED == "tools"
# 4. PATH stripped to /usr/bin:/bin (no starship/zoxide/fzf/eza) → stderr empty, exit 0
# 5. tt_after defined in local.zsh setting TT_AFTER_RAN=1 → variable is 1 after load
```
Each case: `out=$(HOME=$tmp zsh -f -c 'TT_DIR=... ; source $TT_DIR/init.zsh; print -r -- $TT_LOADED' 2>$tmp/err)`; assert with `[[ ... ]] || fail "msg"`. Script prints `ok N` per case, exits non-zero on first failure.

- [ ] **Step 2: Run it:** `bash tests/test_loader.sh` → FAIL: `zsh/init.zsh` not found.

- [ ] **Step 3: Create `zsh/init.zsh`** implementing the Interfaces block. Use `${(j: :)…}` for `TT_LOADED`; match names with `${TT_DISABLE[(Ie)$name]}`. Create `zsh/local.zsh.example`:
```zsh
# terminal-tooling: your overrides. Never overwritten by the installer.
# Disable modules by name: omz tools ghostty fzf keys mouse yazi starship
TT_DISABLE=()
# Or load only these (empty = all not disabled):
TT_ONLY=()
# Runs after all modules (aliases that must win, PATH tweaks, ...):
tt_after() { : }
```

- [ ] **Step 4: Create the modules** from the old `home/.zshrc` lines noted; every module starts with a guard and never prints on a missing tool:
  - `10-omz.zsh`: `export ZSH="$HOME/.oh-my-zsh"`; `ZSH_THEME=""`; `plugins=(git zsh-autosuggestions zsh-interactive-cd)`; source `$ZSH/oh-my-zsh.sh` only if it exists; source Homebrew `zsh-autosuggestions.zsh` and `$HOME/zsh-syntax-highlighting/...` if present; `ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f8dda6"`. (helm/docker plugins dropped: personal.)
  - `20-tools.zsh`: `eval "$(/opt/homebrew/bin/brew shellenv)"` if executable; zoxide init, eza aliases `ls ll lt`, `BAT_THEME`, `cat` alias, `EDITOR/VISUAL=nvim`, `vim`/`vi` aliases — each behind `command -v`.
  - `30-ghostty.zsh`: the Ghostty shell-integration block verbatim.
  - `40-fzf.zsh`: `source <(fzf --zsh)` + the four `FZF_*` exports, guarded by `command -v fzf`.
  - `50-keys.zsh`: the seven `bindkey` lines (word jumps, Home/End, Ctrl-Space accept).
  - `60-mouse.zsh`: `git mv config/zsh/mouse.zsh zsh/modules/60-mouse.zsh`, unchanged.
  - `70-yazi.zsh`: the `y()` function and `alias yazi=y`, guarded by `command -v yazi`.
  - `90-starship.zsh`: `eval "$(starship init zsh)"` guarded.
  Then `git rm home/.zshrc home/.antigen.zsh`.

- [ ] **Step 5: Run:** `bash tests/test_loader.sh` → `ok 1` … `ok 5`.

- [ ] **Step 6: Commit** `git add -A zsh tests/test_loader.sh && git commit -m "Split shell setup into opt-out zsh modules"`

---

### Task 2: Installer flags and one-line footprint

**Files:**
- Modify: `install.sh` (whole file)
- Test: `tests/test_install.sh`

**Interfaces:**
- Consumes: `zsh/init.zsh`, `zsh/modules/`, `zsh/local.zsh.example` from Task 1.
- Produces: `install.sh [--skip a,b] [--only a,b] [-h]`; env `SKIP_BREW=1` unchanged. Exit 2 on bad flags. Defines in-script function `want <name>` returning 0 when that unit should be installed.

- [ ] **Step 1: Write the failing test** `tests/test_install.sh`. Every case runs `HOME=$tmp SKIP_BREW=1 bash install.sh …` with a fresh `$tmp`, a stub `rsync`/`ya`/`chmod`-free PATH is NOT needed (rsync exists); stub network: set `PATH` so `curl`/`git clone` are not reached — `install.sh` already skips oh-my-zsh when `~/.oh-my-zsh` exists, so pre-create `$tmp/.oh-my-zsh`, `$tmp/zsh-syntax-highlighting`, `$tmp/.oh-my-zsh/custom/plugins/zsh-autosuggestions`.
```bash
# A. fresh home: ~/.zshrc exists afterwards and equals exactly the managed block (2 lines)
# B. existing ~/.zshrc "alias x=1": afterwards = original + blank line + block; run again → identical (grep -c "terminal-tooling (managed" == 1)
# C. ~/.config/terminal-tooling/{init.zsh,modules/60-mouse.zsh} exist; local.zsh exists and equals the example
# D. pre-seed local.zsh with "TT_DISABLE=(mouse)"; run → unchanged (cmp)
# E. --skip nvim with a pre-existing ~/.config/nvim/mine.lua → file still there, no ~/.config-backup-*/.config/nvim
# F. --skip mouse,starship on a fresh home → local.zsh contains TT_DISABLE=(mouse starship)
# G. --only zellij → ~/.config/zellij exists, ~/.config/yazi does not, ~/.zshrc untouched? NO: zsh hook is unit "zsh"… see note
# H. --skip bogus → exit 2, stderr mentions bogus, $tmp/.zshrc absent
# I. --skip a --only b → exit 2
```
Note for G: the zsh loader itself is unit name `shell` (always needed for any zsh module). `--only zellij` installs only the zellij folder; `.zshrc` is not touched. Add `shell` to the folder-name list in Global Constraints handling: names = `shell omz tools ghostty fzf keys mouse yazi starship ghostty-config zellij yazi-config nvim lazygit btop starship-config wallpapers`. `--skip shell` skips the hook and modules entirely.

- [ ] **Step 2: Run:** `bash tests/test_install.sh` → FAIL at A (no `.zshrc` block; unknown flag).

- [ ] **Step 3: Rewrite `install.sh`:**
  - Parse args: `--skip LIST`, `--only LIST`, `-h/--help`; validate every name against the list above; both flags → exit 2. Put results in space-separated strings `SKIP`/`ONLY`; `want() { [[ -n $ONLY ]] && { [[ " $ONLY " == *" $1 "* ]]; return; }; [[ " $SKIP " != *" $1 "* ]]; }`.
  - Folder map: `ghostty-config→ghostty`, `zellij→zellij`, `yazi-config→yazi`, `nvim`, `lazygit`, `btop`, `starship-config→starship.toml`, `wallpapers→pictures`. Replace the `for d in "$R"/config/*/` loop with an explicit list that checks `want`.
  - Shell unit (`want shell`): `mkdir -p ~/.config/terminal-tooling`; rsync `zsh/init.zsh` and `zsh/modules/` (with `--delete` on `modules/` only); if `local.zsh` missing, copy the example and, when any zsh module name is skipped (or `ONLY` excludes it), rewrite its `TT_DISABLE=()` line to the disabled names; append the managed block to `~/.zshrc` only if `grep -qF 'terminal-tooling (managed' ~/.zshrc` fails (create the file if absent, with no leading blank line).
  - Remove the `home/*` copy loop and the `.zshrc` path-rewrite target; keep path rewrites for zellij/yazi/ghostty.
  - Keep: Homebrew section, shell extras clones, yazi `ya pkg install`, backup helper.
  - Final `say` lists what was skipped, and prints `edit ~/.config/terminal-tooling/local.zsh to change modules`.

- [ ] **Step 4: Run:** `bash tests/test_install.sh` → `ok A` … `ok I`; also `bash tests/test_loader.sh` still passes.

- [ ] **Step 5: Commit** `git add install.sh tests/test_install.sh && git commit -m "Install one managed line and modules instead of replacing .zshrc"`

---

### Task 3: Command wrapper, backup script, version

**Files:**
- Modify: `bin/terminal-tooling`, `backup.sh`, `VERSION`
- Test: `tests/test_cli.sh`

**Interfaces:**
- Consumes: `install.sh` flags from Task 2.
- Produces: `terminal-tooling install|configs [--skip …] [--only …]` passing flags through; `terminal-tooling version` → `terminal-tooling 2.0.0`.

- [ ] **Step 1: Write the failing test** `tests/test_cli.sh`:
```bash
# 1. bin/terminal-tooling version → "terminal-tooling 2.0.0"
# 2. HOME=$tmp bin/terminal-tooling configs --only zellij → $tmp/.config/zellij exists, $tmp/.zshrc absent
# 3. bin/terminal-tooling help → mentions --skip and local.zsh
```
- [ ] **Step 2: Run:** FAIL (version 1.1.0 / flags not passed).
- [ ] **Step 3: Implement:** `install) shift; exec "$R/install.sh" "$@"`, same for `configs` with `SKIP_BREW=1`; help text gains the flags and the module/folder names; `VERSION` → `2.0.0`. `backup.sh`: drop the `.zshrc`/`.antigen.zsh` copies and `zsh` from the folder list; add `rsync -a --delete "$HOME/.config/terminal-tooling/modules/" "$R/zsh/modules/"`.
- [ ] **Step 4: Run:** all three test scripts pass.
- [ ] **Step 5: Commit** `git add bin/terminal-tooling backup.sh VERSION tests/test_cli.sh && git commit -m "Pass skip/only flags through the terminal-tooling command"`

---

### Task 4: README

**Files:**
- Modify: `README.md` sections 1, 2, 4 and the heads-up box.

- [ ] **Step 1: Rewrite the heads-up:** the installer adds one line to `~/.zshrc` (shown verbatim), installs modules under `~/.config/terminal-tooling/`, and replaces the listed `~/.config` folders unless skipped; backups as before.
- [ ] **Step 2: Add "Pick what you want":** the `--skip`/`--only` flags with the full name list, `local.zsh` with a `TT_DISABLE=(mouse)` example and `tt_after`, and "opt out entirely: delete the managed line and the folder".
- [ ] **Step 3: Update** the installer table rows for configs/shell, the "Make it yours" row for aliases/PATH (`~/.zshrc` is yours; overrides go in `local.zsh`), the repo layout (`zsh/` tree, `home/` and `config/zsh` gone, `tests/`), and the 2.0.0 upgrade note for 1.x users (their copied `.zshrc` is kept and just gains the line; they may delete the old sections).
- [ ] **Step 4: Check:** `grep -n "antigen\|home/.zshrc\|config/zsh" README.md` → no output.
- [ ] **Step 5: Commit** `git add README.md && git commit -m "Document module install and per-feature opt-out"`
