#!/bin/bash
# Restore the whole terminal setup on a fresh Mac.
#   git clone <repo> ~/dotfiles-terminal && ~/dotfiles-terminal/install.sh
# Safe to re-run. Existing files are backed up to ~/.config-backup-<timestamp>/.
# Env: SKIP_BREW=1 skips Homebrew (for a quick config-only restore).
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"; BK="$HOME/.config-backup-$TS"
say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }

if [[ -z "${SKIP_BREW:-}" ]]; then
  if ! command -v brew >/dev/null 2>&1 && [[ ! -x /opt/homebrew/bin/brew ]]; then
    say "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  eval "$(/opt/homebrew/bin/brew shellenv)"
  say "Installing tools + font (brew bundle)"
  brew bundle --file="$R/Brewfile" --no-upgrade
fi
export PATH="/opt/homebrew/bin:$PATH"

say "Shell extras"
[[ -d "$HOME/.oh-my-zsh" ]] || RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
[[ -d "$HOME/zsh-syntax-highlighting" ]] || git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/zsh-syntax-highlighting"
[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] || git clone -q https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
[[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-interactive-cd" ]] || true

backup() { if [[ -e "$1" ]]; then mkdir -p "$BK/$(dirname "${1#$HOME/}")"; cp -a "$1" "$BK/${1#$HOME/}"; fi; }

say "Config files -> ~/.config (previous versions saved in $BK)"
mkdir -p "$HOME/.config"
for d in "$R"/config/*/; do
  n="$(basename "$d")"; backup "$HOME/.config/$n"
  mkdir -p "$HOME/.config/$n"; rsync -a --delete "$d" "$HOME/.config/$n/"
done
backup "$HOME/.config/starship.toml"; cp "$R/config/starship.toml" "$HOME/.config/starship.toml"
chmod +x "$HOME/.config/zellij/bin/"*

say "Home files"
for f in .zshrc .antigen.zsh; do backup "$HOME/$f"; cp "$R/home/$f" "$HOME/$f"; done

# the configs carry absolute paths; rewrite them if this Mac has a different user name
if [[ "$HOME" != "/Users/eolasehinde" ]]; then
  grep -rl "/Users/eolasehinde" "$HOME/.config/zellij" "$HOME/.config/yazi" "$HOME/.config/ghostty" "$HOME/.config/zsh" "$HOME/.zshrc" 2>/dev/null \
    | xargs -I{} sed -i '' "s|/Users/eolasehinde|$HOME|g" {}
fi
mkdir -p "$HOME/Pictures/ghostty"; cp -n "$R"/pictures/ghostty/* "$HOME/Pictures/ghostty/" 2>/dev/null || true
mkdir -p "$HOME/.config/zellij" && touch "$HOME/.config/zellij/project-roots"

say "yazi plugins + flavour"
( cd "$HOME/.config/yazi" && ya pkg install >/dev/null 2>&1 ) || echo "   (ya pkg install skipped — run it later: cd ~/.config/yazi && ya pkg install)"

say "Done. Open Ghostty (it starts straight into Zellij). Alt+Space → guide for the manual."
