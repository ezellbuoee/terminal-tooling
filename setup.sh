#!/bin/bash
# Interactive setup: wallpaper, number of panes, sidebar tool.
#   setup.sh            ask the questions, save the answers, apply them
#   setup.sh --apply    apply the saved answers (defaults if none) to ~/.config
#   setup.sh --defaults save the default answers if no setup.conf exists yet
# Answers live in ~/.config/terminal-tooling/setup.conf and survive every install.
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TT="$HOME/.config/terminal-tooling"; CONF="$TT/setup.conf"
PICS="$HOME/Pictures/ghostty"; [[ -d "$PICS" ]] || PICS="$R/pictures/ghostty"
DEF_BACKGROUND="$HOME/Pictures/ghostty/yujiro-demon-back.jpg"
TT_BACKGROUND="$DEF_BACKGROUND"; TT_PANES=3; TT_SIDEBAR=yazi
SIDEBARS="yazi lazygit btop shell"

read_conf() {
  local k v
  [[ -f "$CONF" ]] || return 0
  while IFS='=' read -r k v || [[ -n "$k" ]]; do
    case "$k" in
      TT_BACKGROUND) TT_BACKGROUND="$v" ;;
      TT_PANES) [[ "$v" == 2 || "$v" == 3 ]] && TT_PANES="$v" ;;
      TT_SIDEBAR) [[ " $SIDEBARS " == *" $v "* ]] && TT_SIDEBAR="$v" ;;
    esac
  done < "$CONF"
}
write_conf() {
  mkdir -p "$TT"
  printf '# terminal-tooling setup answers (change with: terminal-tooling setup)\nTT_BACKGROUND=%s\nTT_PANES=%s\nTT_SIDEBAR=%s\n' \
    "$TT_BACKGROUND" "$TT_PANES" "$TT_SIDEBAR" > "$CONF"
}

# prompt LABEL DEFAULT : prints the answer, or DEFAULT on Enter / end of input
prompt() {
  local a
  printf '%s [%s]: ' "$1" "$2" >&2
  if ! read -r a; then a=""; echo >&2; fi
  [[ -n "$a" ]] && printf '%s' "$a" || printf '%s' "$2"
}

wallpapers() {  # shipped/installed images, sorted by name
  local f
  for f in "$PICS"/*; do
    case "$f" in *.jpg|*.jpeg|*.png) [[ -f "$f" ]] && echo "$f" ;; esac
  done | sort
}

ask_background() {
  local list i=0 f a cur="$TT_BACKGROUND" def
  list="$(wallpapers)"
  echo "Background image"
  for f in $list; do i=$((i+1)); printf '  %d) %s\n' "$i" "$(basename "$f")"; done
  echo "  n) none        o) own image file"
  case "$cur" in none) def=n ;; *) def=o ;; esac
  i=0; for f in $list; do i=$((i+1)); [[ "$f" == "$cur" || "$(basename "$f")" == "$(basename "$cur")" ]] && def=$i; done
  while :; do
    a="$(prompt "  choice" "$def")"
    case "$a" in
      n|none) TT_BACKGROUND=none; return ;;
      o|own)
        a="$(prompt "  path to image" "$([[ "$cur" == none ]] && echo "" || echo "$cur")")"
        a="${a/#\~/$HOME}"
        if [[ -f "$a" ]]; then TT_BACKGROUND="$a"; return; else echo "  $a: not found"; fi ;;
      *)
        i=0; for f in $list; do i=$((i+1)); if [[ "$a" == "$i" ]]; then TT_BACKGROUND="$f"; return; fi; done
        echo "  pick a number, n or o" ;;
    esac
  done
}
ask_panes() {
  local a
  echo "Layout"; echo "  2) sidebar + work"; echo "  3) sidebar + work + shell"
  while :; do
    a="$(prompt "  panes" "$TT_PANES")"
    case "$a" in 2|3) TT_PANES="$a"; return ;; *) echo "  2 or 3" ;; esac
  done
}
ask_sidebar() {
  local a i s
  echo "Sidebar tool"; i=0; for s in $SIDEBARS; do i=$((i+1)); printf '  %d) %s\n' "$i" "$s"; done
  while :; do
    a="$(prompt "  tool" "$TT_SIDEBAR")"
    i=0; for s in $SIDEBARS; do i=$((i+1)); if [[ "$a" == "$i" || "$a" == "$s" ]]; then TT_SIDEBAR="$s"; return; fi; done
    echo "  pick a number or a name"
  done
}

# render_panes : the pane block between the markers, for the current answers
render_panes() {
  local cmd side work
  case "$TT_SIDEBAR" in
    yazi) cmd=" command=\"$HOME/.config/zellij/bin/files-pane\"" ;;
    shell) cmd="" ;;
    *) cmd=" command=\"$TT_SIDEBAR\"" ;;
  esac
  if [[ "$TT_PANES" == 2 ]]; then side="25%"; work="75%"; else side="22%"; work="56%"; fi
  echo '        pane split_direction="vertical" {'
  echo "            pane name=\"files\" size=\"$side\"$cmd borderless=true"
  echo "            pane name=\"work\" size=\"$work\" focus=true"
  [[ "$TT_PANES" == 3 ]] && echo '            pane name="shell" size="22%"'
  echo '        }'
}
apply_zellij() {
  local f blockfile
  blockfile="$(mktemp -t tt-panes.XXXXXX)"; render_panes > "$blockfile"
  for f in "$HOME/.config/zellij/layouts/dev.kdl" "$HOME/.config/zellij/layouts/dev-tab.kdl"; do
    [[ -f "$f" ]] && grep -q 'tt:panes-begin' "$f" || continue
    awk -v blockfile="$blockfile" '
      /tt:panes-begin/ { print; while ((getline line < blockfile) > 0) print line; close(blockfile); skip=1; next }
      /tt:panes-end/   { skip=0 }
      !skip { print }' "$f" > "$f.tt" && mv "$f.tt" "$f"
  done
  rm -f "$blockfile"
}
apply_ghostty() {
  local f="$HOME/.config/ghostty/config" shown
  [[ -f "$f" ]] || return 0
  if [[ "$TT_BACKGROUND" == none ]]; then
    sed -i '' 's|^background-image = |#background-image = |' "$f"
  else
    shown="$TT_BACKGROUND"; [[ "$shown" == "$HOME/"* ]] && shown="~/${shown#$HOME/}"
    if grep -q '^#\{0,1\}background-image = ' "$f"; then
      sed -i '' "s|^#\{0,1\}background-image = .*|background-image = $shown|" "$f"
    else
      printf 'background-image = %s\n' "$shown" >> "$f"
    fi
  fi
}
apply() { apply_zellij; apply_ghostty; }

case "${1:-}" in
  --defaults) [[ -f "$CONF" ]] || write_conf ;;
  --apply) read_conf; [[ -f "$CONF" ]] || write_conf; apply ;;
  "")
    read_conf
    ask_background; ask_panes; ask_sidebar
    write_conf; apply
    echo "Saved to ~/.config/terminal-tooling/setup.conf (background: $TT_BACKGROUND, panes: $TT_PANES, sidebar: $TT_SIDEBAR)."
    echo "Open a new Ghostty window (or restart Zellij) to see the change." ;;
  -h|--help) sed -n '2,6p' "$0"; exit 0 ;;
  *) echo "setup.sh: unknown argument '$1'" >&2; exit 2 ;;
esac
