#!/bin/bash
# Restore the terminal setup on a Mac.
#   git clone <repo> ~/dotfiles-terminal && ~/dotfiles-terminal/install.sh [--skip a,b | --only a,b]
# Safe to re-run. Existing files are backed up to ~/.config-backup-<timestamp>/.
# Your ~/.zshrc is never replaced: one managed line is appended (once).
# Env: SKIP_BREW=1 skips Homebrew (for a quick config-only restore).
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TS="$(date +%Y%m%d-%H%M%S)"; BK="$HOME/.config-backup-$TS"
say() { printf '\033[1;35m==>\033[0m %s\n' "$*"; }

ZSH_MODULES="omz tools ghostty fzf keys mouse yazi starship"
FOLDERS="ghostty-config zellij yazi-config nvim lazygit btop starship-config wallpapers"
ALL_UNITS="shell $ZSH_MODULES $FOLDERS"
SKIP=""; ONLY=""

usage() {
  cat >&2 <<EOT
Usage: install.sh [--skip a,b] [--only a,b] [-h]
  --skip LIST   install everything except these units
  --only LIST   install just these units
Units: $ALL_UNITS
(shell = zsh hook + loader + modules; zsh module names imply shell under --only)
EOT
}

# a unit is wanted unless skipped, or (with --only) unless not listed
want() {
  if [[ -n "$ONLY" ]]; then [[ " $ONLY " == *" $1 "* ]]; return; fi
  [[ " $SKIP " != *" $1 "* ]]
}

parse_list() {  # validate comma list, print space-separated
  local out="" n
  for n in $(printf '%s' "$1" | tr ',' ' '); do
    if [[ " $ALL_UNITS " != *" $n "* ]]; then echo "install.sh: unknown unit '$n'" >&2; usage; exit 2; fi
    out="$out $n"
  done
  printf '%s' "${out# }"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip) [[ $# -ge 2 ]] || { usage; exit 2; }; SKIP="$(parse_list "$2")"; HAVE_SKIP=1; shift 2 ;;
    --only) [[ $# -ge 2 ]] || { usage; exit 2; }; ONLY="$(parse_list "$2")"; HAVE_ONLY=1; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "install.sh: unknown argument '$1'" >&2; usage; exit 2 ;;
  esac
done
if [[ -n "${HAVE_SKIP:-}" && -n "${HAVE_ONLY:-}" ]]; then
  echo "install.sh: --skip and --only cannot be combined" >&2; usage; exit 2
fi
# installing a zsh module needs the loader
if [[ -n "$ONLY" ]]; then
  for m in $ZSH_MODULES; do
    if [[ " $ONLY " == *" $m "* && " $ONLY " != *" shell "* ]]; then ONLY="$ONLY shell"; fi
  done
fi

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
if want shell; then
  [[ -d "$HOME/.oh-my-zsh" ]] || RUNZSH=no CHSH=no KEEP_ZSHRC=yes sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  [[ -d "$HOME/zsh-syntax-highlighting" ]] || git clone -q https://github.com/zsh-users/zsh-syntax-highlighting.git "$HOME/zsh-syntax-highlighting"
  [[ -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] || git clone -q https://github.com/zsh-users/zsh-autosuggestions "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"
fi

backup() { if [[ -e "$1" ]]; then mkdir -p "$BK/$(dirname "${1#$HOME/}")"; cp -a "$1" "$BK/${1#$HOME/}"; fi; }

# install_folder UNIT SRC DEST : directory (rsync --delete) or single file; skipped units are not touched
install_folder() {
  local unit="$1" src="$R/$2" dest="$HOME/.config/$3"
  want "$unit" || return 0
  backup "$dest"
  if [[ -d "$src" ]]; then mkdir -p "$dest"; rsync -a --delete "$src/" "$dest/"; else cp "$src" "$dest"; fi
  INSTALLED="$INSTALLED $unit"
}

# install_shell : loader + modules under ~/.config/terminal-tooling, one managed line in ~/.zshrc
install_shell() {
  local tt="$HOME/.config/terminal-tooling" m disabled="" rc="$HOME/.zshrc"
  mkdir -p "$tt/modules"
  rsync -a "$R/zsh/init.zsh" "$tt/init.zsh"
  rsync -a --delete "$R/zsh/modules/" "$tt/modules/"
  for m in $ZSH_MODULES; do want "$m" || disabled="$disabled $m"; done
  disabled="${disabled# }"
  if [[ ! -e "$tt/local.zsh" ]]; then
    sed "s/^TT_DISABLE=().*/TT_DISABLE=($disabled)/" "$R/zsh/local.zsh.example" > "$tt/local.zsh"
  elif [[ -n "$disabled" ]]; then
    echo "   local.zsh already exists; to disable ($disabled) edit ~/.config/terminal-tooling/local.zsh instead"
  fi
  if [[ ! -f "$rc" ]] || ! grep -qF 'terminal-tooling (managed' "$rc"; then
    [[ -s "$rc" ]] && printf '\n' >> "$rc"
    cat >> "$rc" <<'EOT'
# terminal-tooling (managed line; remove to opt out entirely)
[[ -f ~/.config/terminal-tooling/init.zsh ]] && source ~/.config/terminal-tooling/init.zsh
EOT
  fi
  INSTALLED="$INSTALLED shell"
}

INSTALLED=""
say "Config files -> ~/.config (previous versions saved in $BK)"
mkdir -p "$HOME/.config"
if want shell; then install_shell; fi
install_folder ghostty-config config/ghostty ghostty
install_folder zellij config/zellij zellij
install_folder yazi-config config/yazi yazi
install_folder nvim config/nvim nvim
install_folder lazygit config/lazygit lazygit
install_folder btop config/btop btop
install_folder starship-config config/starship.toml starship.toml
if want zellij; then
  chmod +x "$HOME/.config/zellij/bin/"* 2>/dev/null || true
  touch "$HOME/.config/zellij/project-roots"
fi
if want wallpapers; then
  mkdir -p "$HOME/Pictures/ghostty"; cp -n "$R"/pictures/ghostty/* "$HOME/Pictures/ghostty/" 2>/dev/null || true
  INSTALLED="$INSTALLED wallpapers"
fi

# the configs carry absolute paths; rewrite them if this Mac has a different user name
if [[ "$HOME" != "/Users/eolasehinde" ]]; then
  for u in zellij yazi ghostty; do
    case "$u" in yazi) w=yazi-config ;; ghostty) w=ghostty-config ;; *) w=$u ;; esac
    want "$w" || continue
    { grep -rl "/Users/eolasehinde" "$HOME/.config/$u" 2>/dev/null || true; } | xargs -I{} sed -i '' "s|/Users/eolasehinde|$HOME|g" {}
  done
fi

if want yazi-config; then
  say "yazi plugins + flavour"
  ( cd "$HOME/.config/yazi" && ya pkg install >/dev/null 2>&1 ) || echo "   (ya pkg install skipped — run it later: cd ~/.config/yazi && ya pkg install)"
fi

say "Done. Installed:${INSTALLED:- nothing}"
if [[ -n "$SKIP" ]]; then echo "   Skipped: $SKIP"; fi
echo "   edit ~/.config/terminal-tooling/local.zsh to change modules"
