# Terminal workstation

Ghostty + Zellij + yazi + starship, themed Catppuccin Mocha, with a Nerd Font, a
click-to-move command line, and a menu-driven layout. Clone the repo, run one
script, and you get the whole setup on any Mac.

## Table of contents
1. [Install](#1-install)
2. [Make it yours](#2-make-it-yours)
3. [What gets installed](#3-what-gets-installed)
4. [Repository layout](#4-repository-layout)
5. [Daily keys](#5-daily-keys)
6. [How the pieces fit](#6-how-the-pieces-fit)
7. [Troubleshooting](#7-troubleshooting)

---

## 1. Install

### Requirements
- macOS on Apple Silicon (the installer uses Homebrew at `/opt/homebrew`)
- an internet connection; Homebrew may ask for your password

### Option A: Homebrew

```bash
brew install ezellbuoee/terminal-tooling/terminal-tooling
terminal-tooling install
```

Later updates:

```bash
brew upgrade terminal-tooling && terminal-tooling configs
```

`terminal-tooling configs` copies the configs only and skips `brew bundle`.

### Option B: git clone

Use this if you want to change the configs and keep them in your own fork
(see [Keep your own copy in git](#keep-your-own-copy-in-git)). Needs `git`
(`xcode-select --install` if macOS asks for developer tools).

```bash
git clone https://github.com/ezellbuoee/terminal-tooling.git ~/dotfiles-terminal
~/dotfiles-terminal/install.sh
```

Then open **Ghostty**. It starts straight into Zellij with the sidebar layout.
Press **Alt+Space → guide** for the in-terminal manual.

> **Heads-up:** the installer does not replace your `~/.zshrc`. It appends one
> line to it (creating the file if absent) and leaves the rest alone:
>
> ```
> # terminal-tooling (managed line; remove to opt out entirely)
> [[ -f ~/.config/terminal-tooling/init.zsh ]] && source ~/.config/terminal-tooling/init.zsh
> ```
>
> The shell modules are installed under `~/.config/terminal-tooling/`. It does
> replace the matching folders in `~/.config` (ghostty, zellij, yazi, nvim, lazygit,
> btop, starship.toml) unless you skip them (see [Pick what you want](#pick-what-you-want)).
> Every file it replaces is first copied to `~/.config-backup-<timestamp>/`, so you
> can diff or restore your old setup.

### What the installer does

| step | what happens | time |
|---|---|---|
| Homebrew | installed if missing | 1–2 min |
| `brew bundle` | Ghostty, the Nerd Font and every CLI tool from `Brewfile` | 2–4 min |
| shell extras | oh-my-zsh, zsh-syntax-highlighting, zsh-autosuggestions if missing | 10 s |
| configs | copies `config/*` to `~/.config` | 1 s |
| shell | copies `zsh/` to `~/.config/terminal-tooling/`, appends the managed line to `~/.zshrc`, creates `local.zsh` once | 1 s |
| paths | rewrites the hard-coded home folder in the configs to your `$HOME` | 1 s |
| wallpapers | copies `pictures/ghostty/*` to `~/Pictures/ghostty` | 1 s |
| yazi | installs the Mocha flavour and plugins (`ya pkg install`) | 5 s |

It is safe to re-run at any time.

**Config only** (tools already installed, you just want the files):

```bash
SKIP_BREW=1 ~/dotfiles-terminal/install.sh      # takes about a second
```

### Pick what you want

Both `install.sh` and `terminal-tooling install|configs` take `--skip LIST` or
`--only LIST` (comma-separated):

```bash
~/dotfiles-terminal/install.sh --skip mouse,starship
terminal-tooling configs --only zellij,ghostty-config
```

| unit | what it is |
|---|---|
| `shell` | zsh hook + loader + all modules |
| `omz` `tools` `ghostty` `fzf` `keys` `mouse` `yazi` `starship` | the individual zsh modules (a module name in `--only` implies `shell`) |
| `ghostty-config` `zellij` `yazi-config` `nvim` `lazygit` `btop` `starship-config` `wallpapers` | the `~/.config` folders and wallpapers |

A skipped folder is left untouched (no backup, no copy). Skipped modules are
recorded in `~/.config/terminal-tooling/local.zsh` when the installer creates it;
if that file already exists the installer tells you to edit it instead.

`local.zsh` is created once from `zsh/local.zsh.example` and never overwritten.
Turn modules off there, and use `tt_after` for anything that must run after them:

```zsh
TT_DISABLE=(mouse)             # or TT_ONLY=(omz tools) to load just those
tt_after() { alias ll='ls -l' }
```

To opt out entirely, delete the managed line from `~/.zshrc` and remove
`~/.config/terminal-tooling/`.

### Upgrading from 1.x

Version 2.0.0 no longer copies your personal shell files over yours. If you installed 1.x
you keep the `.zshrc` it copied; it simply gains the managed line. The old
sections in it are now redundant, so you may delete them by hand.

### First-time checks
- macOS may ask to allow Ghostty in *System Settings → Privacy & Security* the first time.
- If icons look broken, open a new Ghostty window once so it picks up the freshly installed font.

### Update a git clone

```bash
cd ~/dotfiles-terminal && git pull && SKIP_BREW=1 ./install.sh
```

Drop `SKIP_BREW=1` if the `Brewfile` changed.

## 2. Make it yours

| want to change | edit |
|---|---|
| folders shown in the project picker | `~/.config/zellij/project-roots`, one folder per line (default `~/Documents/projects`) |
| wallpaper / transparency | `background-image*` and `background-opacity` in `~/.config/ghostty/config`, then cmd+shift+, |
| prompt | `~/.config/starship.toml` |
| shell aliases, PATH | `~/.zshrc` is yours; put overrides in `~/.config/terminal-tooling/local.zsh` (`TT_DISABLE`, `tt_after`) |
| keys | `~/.config/zellij/config.kdl` (Zellij), `~/.config/yazi/keymap.toml` (sidebar) |

### Keep your own copy in git

Fork the repo (or point `origin` at your own remote), then after any tweak run:

```bash
~/dotfiles-terminal/backup.sh
```

It copies the live config back into the repo, commits, and pushes if a remote is set.

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
| **git-delta**, **difftastic** | diffs in lazygit | delta side-by-side is the default pager (`+` widens the diff pane); press `D` on a file or commit for a difftastic structural diff |
| **JetBrainsMono Nerd Font** | font | icons in prompt, sidebar, status bar |

## 4. Repository layout

```
Brewfile                 tools + font + Ghostty for `brew bundle`
install.sh               install everything (idempotent); --skip / --only
bin/terminal-tooling     command exposed by the Homebrew package
VERSION                  release version, used by the Homebrew formula
backup.sh                sync live config and modules back here and commit
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
  starship.toml          prompt
  nvim/                  LazyVim config
  lazygit/ btop/         tool configs
zsh/
  init.zsh               loader, sourced by the managed line in ~/.zshrc
  local.zsh.example      template for ~/.config/terminal-tooling/local.zsh
  modules/               10-omz, 20-tools, 30-ghostty, 40-fzf, 50-keys,
                         60-mouse (click-to-move, cmd+c/v/z), 70-yazi, 90-starship
tests/                   bash tests: test_loader.sh, test_install.sh, test_cli.sh
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
   │ cmd+c/z/k become private              ├── work    = zsh  (starship, mouse module)
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
