# Terminal workstation (Ghostty + Zellij + yazi + starship)

Everything needed to rebuild the terminal setup on a fresh Mac.

## Restore (fresh machine)
```bash
git clone <this repo> ~/dotfiles-terminal
~/dotfiles-terminal/install.sh        # Homebrew, tools, font, configs — ~5 min first time
```
Config-only restore (tools already there): `SKIP_BREW=1 ~/dotfiles-terminal/install.sh` — seconds.

## Keep it current
```bash
~/dotfiles-terminal/backup.sh         # copies live config in, commits, pushes if a remote exists
```

## What is inside
| path | what |
|---|---|
| `Brewfile` | all tools + Nerd Font + Ghostty |
| `config/ghostty` | terminal: font, transparency, cmd+keys |
| `config/zellij` | keybinds, layouts, status bar, menu + helper scripts, GUIDE.md, HELP.txt |
| `config/yazi` | sidebar file manager: openers, keys, hints, Mocha flavour |
| `config/zsh/mouse.zsh` | click-to-move cursor, cmd+c/v/z in the command line |
| `config/starship.toml` | prompt |
| `config/nvim` | LazyVim |
| `config/bat`, `lazygit`, `btop` | tool configs |
| `home/.zshrc`, `home/.antigen.zsh` | shell startup |
| `pictures/ghostty` | background images |

Full manual: `config/zellij/GUIDE.md` (or Alt+Space → guide inside the terminal).
