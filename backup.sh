#!/bin/bash
# Pull the current live config into this repo and commit it. Run after any tweak.
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for d in ghostty zellij yazi zsh nvim bat lazygit btop; do
  [[ -d "$HOME/.config/$d" ]] && rsync -a --delete --exclude '.DS_Store' --exclude '*.bak*' "$HOME/.config/$d/" "$R/config/$d/"
done
cp "$HOME/.config/starship.toml" "$R/config/starship.toml"
cp "$HOME/.zshrc" "$R/home/.zshrc"; cp "$HOME/.antigen.zsh" "$R/home/.antigen.zsh"
cp "$HOME"/Pictures/ghostty/* "$R/pictures/ghostty/" 2>/dev/null || true
cd "$R" && git add -A && git commit -qm "backup $(date '+%Y-%m-%d %H:%M')" && echo "committed" || echo "nothing changed"
[[ -n "$(git remote 2>/dev/null)" ]] && git push -q && echo "pushed" || true
