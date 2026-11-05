# Terminal workstation

Ghostty + Zellij + yazi + starship, themed Catppuccin Mocha, with a Nerd Font, a
click-to-move command line, and a menu-driven layout. This repo holds every file
needed to rebuild it on a fresh Mac in one command.

## Table of contents
1. [Restore on a fresh Mac](#1-restore-on-a-fresh-mac)
2. [Keep the backup current](#2-keep-the-backup-current)
3. [What gets installed](#3-what-gets-installed)
4. [Repository layout](#4-repository-layout)
5. [Daily keys](#5-daily-keys)
6. [How the pieces fit](#6-how-the-pieces-fit)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Restore on a fresh Mac

```bash
# 1. get the repo (GitHub, iCloud copy, USB stick — wherever you keep it)
git clone <your-remote> ~/dotfiles-terminal

# 2. run the installer
~/dotfiles-terminal/install.sh
```

The installer, in order:

| step | what happens | time |
|---|---|---|
| Homebrew | installed if missing | 1–2 min |
| `brew bundle` | Ghostty, the Nerd Font and every CLI tool from `Brewfile` | 2–4 min |
| shell extras | oh-my-zsh, zsh-syntax-highlighting, zsh-autosuggestions if missing | 10 s |
| configs | copies `config/*` to `~/.config`, `.zshrc` and `.antigen.zsh` to `~` | 1 s |
| paths | rewrites `/Users/eolasehinde` to the current home if the user name differs | 1 s |
| yazi | installs the Mocha flavour and plugins (`ya pkg install`) | 5 s |

Anything it replaces is first copied to `~/.config-backup-<timestamp>/`.
It is safe to re-run at any time.

**Config-only restore** (tools already installed, you just want the files back):

```bash
SKIP_BREW=1 ~/dotfiles-terminal/install.sh      # takes about a second
```

Afterwards open Ghostty. It starts straight into Zellij with the sidebar layout.

### First-time checks
- macOS may ask to allow Ghostty in *System Settings → Privacy & Security* the first time.
- If icons look broken, open a new Ghostty window once so it picks up the freshly installed font.
- Project picker folders live in `~/.config/zellij/project-roots` (one folder per line).

## 2. Keep the backup current

```bash
~/dotfiles-terminal/backup.sh
```

Copies the live config into the repo, commits, and pushes if a remote is set.
Run it after any tweak. To add a remote once:

```bash
cd ~/dotfiles-terminal
gh repo create dotfiles-terminal --private --source=. --push     # with GitHub CLI
# or
git remote add origin git@github.com:<you>/dotfiles-terminal.git && git push -u origin main
```

## 3. What gets installed

| tool | role | how it is used here |
|---|---|---|
| **Ghostty** | terminal app | font, transparency + blur, background image, cmd+c/v/z/k routing |
| **Zellij** | panes, tabs, sessions | `home` session with files / work / shell panes, Alt-key bindings, zjstatus bar |
| **yazi** | file manager | the sidebar; Enter opens, `o` menu: LazyVim, macOS app, Enter Path (current/floating), Finder |
| **starship** | prompt | single-line Mocha powerline: OS, path, git; right side: status, duration, k8s/docker, runtime, time |
| **neovim** + LazyVim | editor | opened floating from the sidebar (`e`) |
| **fzf**, **fd**, **ripgrep** | fuzzy finding | Ctrl-R history, Ctrl-T files, Alt-C directories, the Alt+Space menu |
| **zoxide** | smart cd | `z <part of a path>` |
| **eza**, **bat** | ls / cat replacements | `ls`, `ll`, `lt`, `cat` aliases, Mocha colours |
| **glow** | Markdown viewer | the in-terminal guide (Alt+Space → guide) |
| **lazygit**, **lazydocker**, **k9s**, **btop**, **stern** | floating tools | menu entries git / docker / k8s / monitor |
| **JetBrainsMono Nerd Font** | font | icons in prompt, sidebar, status bar |

## 4. Repository layout

```
Brewfile                 tools + font + Ghostty for `brew bundle`
install.sh               restore everything (idempotent)
backup.sh                sync live config back here and commit
config/
  ghostty/config         terminal settings and cmd-key routing
  zellij/
    config.kdl           keybinds (Alt keys, F12 = cmd+k), options
    layouts/dev.kdl      startup layout + zjstatus bar
    layouts/dev-tab.kdl  layout for tabs opened by the project picker
    bin/zj-start         Ghostty entry point: PATH, ulimit, session naming
    bin/zj-menu          Alt+Space menu
    bin/zj-open          sidebar actions (vim / app / cd / cd-float / finder / smart)
    bin/zj-project       project picker
    bin/files-pane       starts yazi in the sidebar
    plugins/zjstatus.wasm
    GUIDE.md, HELP.txt   in-terminal manual and key list
    project-roots        folders scanned by the project picker
  yazi/                  yazi.toml, keymap.toml, init.lua, theme.toml, plugins, flavour
  zsh/mouse.zsh          click-to-move, double-click select, cmd+c/v/z in the command line
  starship.toml          prompt
  nvim/                  LazyVim config
  bat/ lazygit/ btop/    tool configs
home/.zshrc, .antigen.zsh
pictures/ghostty/        background images
```

## 5. Daily keys

| key | action |
|---|---|
| Alt+Space / F1 | menu: project, git, docker, k8s, monitor, session, tab, rename, close, help, guide |
| Alt+f / Alt+c / Alt+m | floating quick shell / close focused pane / hide-show floating panes |
| Alt+arrows | move between panes |
| Alt+1…5, Alt+w | go to tab, close tab |
| cmd+k | clear the focused pane, even while a log follows |
| cmd+c / cmd+v / cmd+z | copy, paste, undo in the command line |
| click / double / triple | move cursor / select word / select line (while the line has text) |
| drag (empty line) or Shift+drag | select output; copied to the clipboard on release |
| Ctrl-R / Ctrl-T / Alt-C | fuzzy history / files / directories |
| Ctrl-Space | accept the grey autosuggestion |
| sidebar: Enter, `o`, `e`, `O`, `b`, `B`, `r`, `h` | open, open-with menu, LazyVim, macOS app, cd here, cd in floating shell, Finder, back |

## 6. How the pieces fit

```
Ghostty  ──command──▶  zj-start  ──▶  zellij attach -c home   (layout dev.kdl)
   │                                      ├── files   = yazi  (files-pane)
   │ cmd+c/z/k become private              ├── work    = zsh  (starship, mouse.zsh)
   │ key sequences so Zellij               ├── shell   = zsh
   │ passes them through                   └── zjstatus bar (hints, git, cpu, mem, time)
   └── Shift+drag selection is Ghostty's own
```

- Zellij sits between Ghostty and the programs, so any shortcut that normally belongs
  to the terminal (clear, copy, undo) is routed explicitly: Ghostty sends a sequence,
  Zellij or zsh acts on it.
- `zj-start` exports Homebrew into PATH for the Zellij server (Ghostty starts with a bare
  PATH), disables session resurrection, and gives a second window its own session.
- yazi actions call `zj-open`, which knows whether it runs in the sidebar or standalone.

## 7. Troubleshooting

| symptom | fix |
|---|---|
| icons missing / boxes | `ghostty +show-face --string=""` must name the Nerd Font; open a new window; never paste icons from chat into configs, edit with nvim |
| `command not found` in a pane | `zj-start` must be the Ghostty `command`; it sets PATH for the server |
| window opens empty or broken | `zellij kill-session home` then open a new window (sessions are never resurrected) |
| status bar missing icons/colours | layout changes need a new session (see above) |
| Ghostty config edits not applied | cmd+shift+, reloads; font changes need a new window |
| guide / help not readable | they use glow / less; `q` closes |
