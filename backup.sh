#!/bin/bash
# Pull the current live config into this repo and commit it. Run after any tweak.
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for d in ghostty zellij yazi nvim bat lazygit btop; do
  [[ -d "$HOME/.config/$d" ]] && rsync -a --delete --exclude '.DS_Store' --exclude '*.bak*' --exclude '/z/' "$HOME/.config/$d/" "$R/config/$d/"
done
cp "$HOME/.config/starship.toml" "$R/config/starship.toml"
[[ -d "$HOME/.config/terminal-tooling/modules" ]] && rsync -a --delete "$HOME/.config/terminal-tooling/modules/" "$R/zsh/modules/"
cp "$HOME"/Pictures/ghostty/* "$R/pictures/ghostty/" 2>/dev/null || true
cd "$R" && git add -A && git commit -qm "backup $(date '+%Y-%m-%d %H:%M')" && echo "committed" || echo "nothing changed"
[[ -n "$(git remote 2>/dev/null)" ]] && git push -q && echo "pushed" || true
