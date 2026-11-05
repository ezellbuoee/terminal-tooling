# Terminal Setup Guide

Ghostty + Zellij + yazi workstation, set up 4–5 November 2026.
Everything here is installed with Homebrew unless noted. Config lives under `~/.config`.

---

## 1. The big picture

```
┌─ Ghostty (terminal app, wallpaper, fonts, cmd+keys) ───────────────────────────┐
│ ┌─ Zellij session "home" (panes, tabs, floating windows, Alt+keys) ──────────┐ │
│ │ ┌─ files ─┐ ┌─ work ────────────────────────────┐ ┌─ shell ──────────────┐ │ │
│ │ │  yazi   │ │  zsh  (starship prompt)           │ │  zsh                 │ │ │
│ │ │ sidebar │ │                                   │ │                      │ │ │
│ │ └─────────┘ └───────────────────────────────────┘ └──────────────────────┘ │ │
│ │  ⌥Space menu │ home │ NORMAL │ tabs   ⌥f quick ⌥c close …   cpu mem disk 🕒 │ │
│ └────────────────────────────────────────────────────────────────────────────┘ │
└────────────────────────────────────────────────────────────────────────────────┘
```

* **Ghostty** draws the window: wallpaper, transparency, font, and the cmd+ shortcuts.
* **Zellij** runs inside Ghostty and manages panes, tabs and floating windows. Every Ghostty window attaches to the same session `home`, so closing a window never loses work.
* **yazi** is the file sidebar on the left. **zsh** with the **starship** prompt runs in the other panes.
* The bottom bar is the **zjstatus** plugin.

---

## 2. Installed tools

| Tool | Version | What it does | How installed |
|---|---|---|---|
| Ghostty | 1.4.0 | Terminal emulator | `brew install --cask ghostty` |
| JetBrainsMono Nerd Font | – | Font with icons | `brew install --cask font-jetbrains-mono-nerd-font` |
| Zellij | 0.45.1 | Terminal multiplexer: panes, tabs, floating panes, sessions | `brew install zellij` |
| zjstatus | 0.25.0 | Zellij status-bar plugin (bottom bar) | wasm file in `~/.config/zellij/plugins/` |
| yazi | 26.9.1 | Terminal file manager (sidebar) | `brew install yazi` |
| starship | 1.27.0 | Prompt (the coloured powerline) | `brew install starship` |
| Neovim + LazyVim | 0.12.6 | Editor; LazyVim config in `~/.config/nvim` | `brew install neovim` |
| lazygit | – | Git UI | `brew install lazygit` |
| lazydocker | 0.25.2 | Docker UI | `brew install lazydocker` |
| k9s | – | Kubernetes UI | `brew install k9s` (also in `~/.rd/bin`) |
| btop | 1.4.8 | System monitor | `brew install btop` |
| fzf | 0.74.5 | Fuzzy picker (menu, project picker, ctrl+r history) | `brew install fzf` |
| zoxide | 0.10.0 | Smarter `cd` that remembers folders | `brew install zoxide` |
| eza | – | Modern `ls` with icons and git status | `brew install eza` |
| bat | 0.26.1 | `cat` with syntax highlighting | `brew install bat` |
| ripgrep, fd, jq, poppler | – | Search, find, JSON, PDF preview for yazi | `brew install ripgrep fd jq poppler` |

Reinstall everything at once:

```sh
brew install zellij yazi starship neovim lazygit lazydocker k9s btop fzf zoxide eza bat ripgrep fd jq poppler
brew install --cask ghostty font-jetbrains-mono-nerd-font
```

---

## 3. Keys

### Ghostty (cmd = ⌘)

| Key | Action |
|---|---|
| cmd+n | New window (attaches to the same Zellij session) |
| cmd+t / cmd+w | New / close Ghostty tab |
| cmd+shift+, | Reload Ghostty config |
| cmd+c | Copy the selection made on the command line (see §5) |
| cmd+v | Paste (replaces a command-line selection) |
| cmd+z / cmd+shift+z | Undo / redo on the command line |
| shift+drag | Native text selection anywhere (auto-copied) |

### Zellij (⌥ = option/alt)

| Key | Action |
|---|---|
| **⌥Space** or F1 | The menu (projects, git, docker, k8s, monitor, sessions, tabs, help) |
| ⌥f | Quick floating shell in the current folder |
| ⌥c | Close the focused pane (also closes the quick shell) |
| ⌥m | Hide / show all floating panes |
| ⌥←↑↓→ or ⌥h j k l | Move focus between panes |
| ⌥n | New pane |
| ⌥1 … ⌥5 | Jump to tab 1–5 |
| ⌥w | Close tab |
| Esc or q | Close a floating tool (lazygit, btop, …) |
| Ctrl+p then r / d / x | Split right / down, close pane (Zellij pane mode) |
| Ctrl+s | Scroll mode (PageUp/Down, `/` search, Esc to leave) |

The bottom bar shows the most important ones.

### The ⌥Space menu

| Entry | What happens |
|---|---|
| project | Fuzzy-pick a project folder → opens as a new tab with sidebar, shell, shell |
| git | lazygit for the current folder (floating) |
| docker | lazydocker (floating) |
| k8s | k9s (floating) |
| monitor | btop (floating) |
| session | Zellij session manager |
| tab / rename / close | Tab management |
| help | The key cheat sheet (`~/.config/zellij/HELP.txt`) |

Project folders come from `~/.config/zellij/project-roots` (one folder per line; git repos, Maven, Go and Node projects up to two levels deep are listed).

### Sidebar (yazi) — same keys in plain `yazi`

| Key | Action |
|---|---|
| ↑↓ / j k | Move |
| Enter | Folder: go in. File: text/code → LazyVim floating, anything else → macOS app |
| h | Back to parent folder |
| **o** | Menu: LazyVim (floating) / macOS app / Enter Path (current) / Enter Path (floating) / Reveal in Finder |
| e | LazyVim (floating), `:q` to close |
| E | LazyVim inside the work pane |
| O | Open in the macOS app |
| b | Enter Path (current): the work pane `cd`s there. In plain yazi: yazi quits and your shell is there |
| B | Enter Path (floating): a floating shell already in that folder |
| r | Reveal in Finder |
| / | Filter, `z` zoxide jump, `.` toggle hidden files |
| ~ | yazi's built-in help |

For a file, "Enter Path" uses the folder that contains it. If the tab has no work pane, one is created next to the sidebar.

---

## 4. Shell goodies (zsh)

| Thing | Where | What |
|---|---|---|
| `ls`, `ll`, `lt` | `.zshrc` | eza with icons / long + git / tree |
| `cat` | `.zshrc` | bat, plain style, no pager |
| `z folder` | zoxide | Jump to a folder you have visited before (`zi` = interactive) |
| `y` (and `yazi`) | `.zshrc` | yazi that `cd`s the shell to the folder it was in when it quit |
| ctrl+r, ctrl+t | fzf | Fuzzy history, fuzzy file insert |
| `EDITOR=nvim` | `.zshrc` | Used by git, yazi, etc. |

---

## 5. Mouse on the command line

`~/.config/zsh/mouse.zsh` (sourced from `.zshrc`) makes the prompt behave like an editor:

| Gesture | Result |
|---|---|
| click | Move the cursor there |
| double click | Select the word |
| triple click | Select the whole line |
| cmd+c | Copy the selection (clipboard) |
| cmd+v, typing, backspace | Replace / remove the selection |
| ctrl+y | Paste the last selection |
| cmd+z / cmd+shift+z | Undo / redo |
| wheel | Scroll the pane |
| shift+drag | Ghostty's own selection, for output above the prompt |

Inside full-screen programs (yazi, nvim, lazygit) the mouse belongs to that program.

---

## 6. Files and where to change things

| File | Purpose |
|---|---|
| `~/.config/ghostty/config` | Font, wallpaper (`background-image`, `background-image-opacity`), opacity, cmd+ keybinds, startup command |
| `~/Pictures/ghostty/` | Wallpapers: `yujiro-demon-back.jpg` (active), `baki-black.jpg`, `baki-faceoff.jpg`, `sakura-night.png` |
| `~/.config/zellij/config.kdl` | Zellij options and ⌥ keybinds (block at the end, "added 2026-11-04") |
| `~/.config/zellij/layouts/dev.kdl` | Startup layout and the bottom bar (zjstatus formats, hint text) |
| `~/.config/zellij/layouts/dev-tab.kdl` | Layout used for new project tabs |
| `~/.config/zellij/bin/zj-start` | What Ghostty runs: raises the open-file limit, attaches to session `home` |
| `~/.config/zellij/bin/zj-menu` | The ⌥Space menu |
| `~/.config/zellij/bin/zj-project` | Project picker |
| `~/.config/zellij/bin/zj-open` | All yazi actions: vim, vim-main, app, cd, cd-float, finder, smart |
| `~/.config/zellij/bin/files-pane` | Starts yazi in the sidebar with a proper PATH and editor |
| `~/.config/zellij/project-roots` | Folders scanned for projects |
| `~/.config/zellij/HELP.txt` | Cheat sheet shown by menu → help |
| `~/.config/zellij/plugins/zjstatus.wasm` | Status-bar plugin |
| `~/.config/yazi/yazi.toml` | Sidebar mode (`ratio = [0,1,0]`), the `o` menu entries and order |
| `~/.config/yazi/keymap.toml` | Sidebar keys (Enter, o, e, E, O, b, B, r) |
| `~/.config/yazi/init.lua` | The key-hint status line at the bottom of the sidebar |
| `~/.config/yazi/plugins/smart-open.yazi` | Enter behaviour (folder → enter, file → smart open) |
| `~/.config/starship.toml` | Prompt |
| `~/.config/lazygit/config.yml`, `~/.config/btop/btop.conf` | Tool themes |
| `~/.config/zsh/mouse.zsh` | Mouse / cmd+c / cmd+z on the command line |
| `~/.zshrc` (end) | zoxide, eza/bat aliases, `y` wrapper, sourcing mouse.zsh |

---

## 7. How things work under the hood

* **Startup**: Ghostty's `command =` runs `zj-start`, which raises `ulimit -n` (GUI apps start with 256 open files, which the Zellij server inherits) and runs `zellij attach -c home`. First window creates the session, later windows attach to it.
* **Floating tools**: the menu runs `zellij run -f … -- /full/path/tool`. Full paths are required because Zellij starts panes with a bare PATH.
* **Yazi actions**: every entry in the `o` menu and every direct key calls `zj-open MODE path`. `smart` decides by MIME type / extension. `cd` types `cd …` into the work pane when run from the sidebar (detected by the pane name `files`), or tells yazi to quit into the folder when run from plain yazi (the `y` wrapper then `cd`s the shell).
* **Bottom bar**: zjstatus runs small shell commands for CPU, memory, disk and git branch every 10–60 s.
* **Mouse on the prompt**: zsh turns on terminal mouse reporting while a line is being edited; Zellij forwards clicks to zsh, and the widget maps the click to a cursor position.
* **cmd+c / cmd+z**: Ghostty would otherwise send these as a kitty-protocol key that Zellij turns into a plain letter, so Ghostty sends a private escape sequence (`ESC _zm:copy ESC \`) that zsh maps to the right widget.
* **`997;2n` text**: a Zellij quirk with colour-scheme queries; suppressed with `explicit_theme_hue "dark"` in the Zellij config.

---

## 8. Common tasks

| I want to… | Do |
|---|---|
| Change the wallpaper | Edit `background-image` in the Ghostty config, then cmd+shift+, |
| Make the wallpaper stronger / weaker | `background-image-opacity` (0.30 now) |
| Add a project folder to the picker | Add the path to `~/.config/zellij/project-roots` |
| Add a tool to the menu | Add a line to `zj-menu` (list + `case` branch) |
| Change the bottom-bar hints | `format_center` in `layouts/dev.kdl`, then restart the session |
| Change the sidebar key hints | `~/.config/yazi/init.lua` |
| Apply new yazi config to an open sidebar | Press q, then Enter in the sidebar |
| Apply new Zellij keybinds | Automatic (Zellij watches its config) |
| Apply a new layout / bottom bar | `zellij kill-session home`, then open a new Ghostty window |
| Apply a new `.zshrc` to an open shell | `exec zsh` |
| Delete leftover Zellij sessions | `zellij list-sessions`, then `zellij delete-session NAME` |

---

## 9. Troubleshooting

| Symptom | Fix |
|---|---|
| Icons look clipped or missing | Font must be `JetBrainsMono Nerd Font` (not the Mono variant) in the Ghostty config; reload and open a new window |
| A menu entry opens nothing | The tool is missing: `brew install <tool>`; the menu says "not installed" |
| Alt keys type letters instead | `macos-option-as-alt = true` must be in the Ghostty config |
| cmd+c types a "c" | Ghostty config needs the `keybind = cmd+c=text:…` line and a reload |
| Sidebar opened in the wrong folder | It uses the pane's folder; use "Enter Path" or open a project tab |
| "Enter Path (current)" did nothing | The tab had no shell pane; the script now creates one beside the sidebar |
| Bottom bar shows old hints | Restart the session (§8) |
| Zellij log says "Too many open files" | Start Ghostty windows through `zj-start` (already the default) |

Zellij log: `/var/folders/*/T/zellij-<uid>/zellij-log/zellij.log`.

## Look & feel (updated 2026-11-05)

- **One colour scheme everywhere:** Catppuccin Mocha in Ghostty, Zellij/zjstatus, starship, fzf, bat and yazi (flavour `catppuccin-mocha`, installed with `ya pkg`).
- **Transparency:** Ghostty `background-opacity = 0.82` + `background-blur = 24`; `background-opacity-cells = true` keeps status bars and yazi transparent too. The old Baki background image is commented out in `~/.config/ghostty/config`; uncomment the three `background-image*` lines to bring it back.
- **Prompt:** two lines. Line 1 = Apple icon · path (`~/.config/zellij`, max 5 folders) · git branch/status, right side = exit status, duration, k8s/docker context, Java/Node/Python version, time. Line 2 = `❯` (green ok, red if the last command failed).
- **Clean start every time:** Zellij `session_serialization false` plus `zj-start` deleting dead sessions, so a window never resurrects a broken layout. `zj-start` also exports Homebrew into PATH for the Zellij server, which fixed the occasional `command not found: yazi` on first open.
- **Second Ghostty window:** gets its own session (`home-2`, `home-3`, ...) instead of mirroring the first window.
- **Menu → help** now opens in `less` (q closes, arrows scroll), same as the guide.
