# Design: stop replacing the user's .zshrc; install modules instead

Date: 2026-11-23

## Intent and why

The installer copies the author's personal `~/.zshrc` over the user's file. That
ships the author's private aliases and kube cluster helpers to every user (a
leak), destroys the user's own shell setup (backed up, but still gone), and gives
no way to take only part of the setup. The goal is an installer that sets the
tools up *for* the user, merges into what they already have, and lets them pick
features one by one.

## Goals

- The repo contains nothing personal to the author. `home/.zshrc` and
  `home/.antigen.zsh` are removed.
- The installer touches the user's `~/.zshrc` in exactly one place: a single
  marked `source` line, added once, idempotently. Everything else in the file is
  theirs and never rewritten.
- Every feature is a separate module the user can switch off, both at install
  time and later from a file the installer never overwrites.
- The same opt-out applies to the `~/.config/<tool>` folders: a user can keep
  their own nvim, yazi, ghostty, ... config.
- Re-running the installer upgrades modules without touching user choices.

## Non-goals

- Rewriting git history to purge the old `.zshrc` (separate decision).
- Supporting shells other than zsh.
- A TUI/wizard; flags and a plain text file are enough.

## Anti-goals

- Any step that edits the body of the user's `.zshrc`, or replaces any file in
  `$HOME` the user did not opt into.

## Constraints

- macOS, Homebrew at `/opt/homebrew`, installed either from a git clone
  (`install.sh`) or from the Homebrew formula (`terminal-tooling install|configs`).
  Both paths call the same script.
- Existing users of 1.x already have the old copied `.zshrc`; the installer
  must leave that file alone too (it will just gain the source line).

## Approaches considered

1. **One sourced line + modules in `~/.config/terminal-tooling/`** (chosen).
   Clean separation, upgrades never conflict with user edits, personal config
   stays out of the repo by construction.
2. **Marked blocks spliced into `.zshrc`.** Familiar, but brittle merges once
   users edit inside the markers, and upgrades rewrite the user's file.

## The design

### Files shipped in the repo

```
zsh/
  init.zsh          loader: reads local.zsh, sources enabled modules in order
  modules/
    10-omz.zsh      oh-my-zsh bootstrap + plugins, autosuggestions, syntax highlighting
    20-tools.zsh    zoxide, eza/bat aliases, EDITOR/VISUAL=nvim, vim/vi aliases
    30-ghostty.zsh  Ghostty shell integration when running under Ghostty
    40-fzf.zsh      fzf keys + fd defaults + colours
    50-keys.zsh     word jumps, Home/End, Ctrl-Space accept suggestion
    60-mouse.zsh    click-to-move cursor (today's config/zsh/mouse.zsh)
    70-yazi.zsh     y() wrapper that follows yazi's cwd
    90-starship.zsh starship prompt (must stay last)
  local.zsh.example template for the user's overrides
```

`config/zsh/` goes away; the mouse script becomes a module.

### What lands in `$HOME`

- `~/.config/terminal-tooling/init.zsh` and `modules/` — replaced on every
  install (rsync).
- `~/.config/terminal-tooling/local.zsh` — created from the example only if
  missing, never overwritten. Holds `TT_DISABLE=(mouse starship)` and anything
  the user wants after the modules.
- `~/.zshrc` — gains one block, only if absent:

  ```zsh
  # terminal-tooling (managed line; remove to opt out entirely)
  [[ -f ~/.config/terminal-tooling/init.zsh ]] && source ~/.config/terminal-tooling/init.zsh
  ```

  Appended at the end so starship stays last. If no `.zshrc` exists, one is
  created containing just that block.

### Loader behaviour (`init.zsh`)

1. Source `local.zsh` if present (sets `TT_DISABLE`, may set `TT_ONLY`).
2. For each `modules/NN-name.zsh` in order: skip if `name` is in `TT_DISABLE`
   (or not in `TT_ONLY` when that is set); otherwise source it.
3. Each module guards its own prerequisites (`command -v starship` etc.) so a
   missing tool degrades silently instead of erroring at shell start.
4. Source `local.zsh`'s `tt_after` hook if defined, for overrides that need the
   modules loaded first.

### Installer changes (`install.sh`, `bin/terminal-tooling`)

- New flags, usable on `install.sh` and `terminal-tooling install|configs`:
  `--skip a,b,c` and `--only a,b,c`. Names cover both zsh modules and config
  folders: `omz tools ghostty fzf keys mouse yazi starship` and
  `ghostty-config zellij yazi-config nvim lazygit btop starship-config
  wallpapers`.
- Skipped config folders are not touched at all (no backup, no rsync).
- Skipped zsh modules are written into `TT_DISABLE` in a freshly created
  `local.zsh` so the choice survives; an existing `local.zsh` is left alone and
  the user is told to edit it.
- `SKIP_BREW=1` stays. `terminal-tooling configs` keeps its meaning (configs
  only) and gains the same flags.
- The home-folder path rewrite remains for the config folders that carry
  absolute paths.

### Backup script

`backup.sh` no longer syncs `~/.zshrc`; it syncs `~/.config/terminal-tooling/modules`
back into `zsh/modules` and the config folders as before.

### README

The install section documents the one-line footprint, the module list, how to
disable things (`--skip`, `local.zsh`), and how to opt out entirely (delete the
line). The "what the installer does" table is updated.

### Version

Bump `VERSION` to 2.0.0: the footprint in `$HOME` changes.

## Left to the builder

- Exact wording of the managed comment line; keep it greppable.
- Whether `10-omz.zsh` installs oh-my-zsh if missing at shell start (no: the
  installer does that; the module only loads it when present).
- Ordering numbers are a convention, not a contract.
