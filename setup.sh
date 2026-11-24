#!/bin/bash
# Interactive setup: wallpaper, number of panes, sidebar tool.
#   setup.sh            ask the questions, save the answers, apply them
#   setup.sh --ask      ask and save only (the installer applies later)
#   setup.sh --apply    apply the saved answers (defaults if none) to ~/.config
#   setup.sh --defaults save the default answers if no setup.conf exists yet
# Answers live in ~/.config/terminal-tooling/setup.conf and survive every install.
# Env: TT_APPLY="zellij ghostty" limits --apply to those parts (the installer sets it).
set -euo pipefail
R="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TT="$HOME/.config/terminal-tooling"; CONF="$TT/setup.conf"
# wallpapers are listed from ~/Pictures/ghostty; before the installer has copied them, from the repo,
# but the saved path always points at ~/Pictures/ghostty (the repo copy may live in a Homebrew Cellar)
WALL_DIR="$HOME/Pictures/ghostty"
PICS="$WALL_DIR"; [[ -d "$PICS" ]] || PICS="$R/pictures/ghostty"
DEF_BACKGROUND="$WALL_DIR/yujiro-demon-back.jpg"
TT_BACKGROUND="$DEF_BACKGROUND"; TT_PANES=3; TT_SIDEBAR=yazi
SIDEBARS="yazi lazygit btop shell"
warn() { echo "setup: $*" >&2; }

read_conf() {
  local k v
  [[ -f "$CONF" ]] || return 0
  while IFS='=' read -r k v || [[ -n "$k" ]]; do
    v="${v%$'\r'}"
    case "$k" in
      TT_BACKGROUND) if [[ -n "$v" ]]; then TT_BACKGROUND="$v"; else warn "ignoring empty TT_BACKGROUND"; fi ;;
      TT_PANES) if [[ "$v" == 2 || "$v" == 3 ]]; then TT_PANES="$v"; else warn "ignoring TT_PANES=$v (2 or 3)"; fi ;;
      TT_SIDEBAR) if [[ " $SIDEBARS " == *" $v "* ]]; then TT_SIDEBAR="$v"; else warn "ignoring TT_SIDEBAR=$v ($SIDEBARS)"; fi ;;
    esac
  done < "$CONF"
  return 0
}
write_conf() {
  mkdir -p "$TT"
  printf '# terminal-tooling setup answers (change with: terminal-tooling setup)\nTT_BACKGROUND=%s\nTT_PANES=%s\nTT_SIDEBAR=%s\n' \
    "$TT_BACKGROUND" "$TT_PANES" "$TT_SIDEBAR" > "$CONF"
}

# prompt LABEL DEFAULT : prints the answer; DEFAULT on Enter. At end of input prints the
# default and sets EOF=1 so callers stop asking instead of looping.
EOF_SEEN=0
prompt() {
  local a=""
  printf '%s [%s]: ' "$1" "$2" >&2
  local eof=0
  if ! read -r a; then eof=1; echo >&2; fi
  [[ -n "$a" ]] && printf '%s' "$a" || printf '%s' "$2"
  return $eof
}

# WALLS[] : shipped/installed images, sorted by name (names may contain spaces)
WALLS=()
wallpaper_files() {
  local f
  for f in "$PICS"/*; do
    case "$f" in
      *.jpg|*.jpeg|*.png|*.JPG|*.JPEG|*.PNG|*.webp|*.gif) [[ -f "$f" ]] && printf '%s\n' "$f" ;;
    esac
  done | sort
}
# wall_path FILE : the path saved for a listed wallpaper (always under ~/Pictures/ghostty)
wall_path() { if [[ "$PICS" == "$WALL_DIR" ]]; then printf '%s' "$1"; else printf '%s/%s' "$WALL_DIR" "$(basename "$1")"; fi; }
list_wallpapers() {
  local f
  WALLS=()
  while IFS= read -r f; do WALLS[${#WALLS[@]}]="$f"; done < <(wallpaper_files)
}

ask_background() {
  local i=0 a def cur="$TT_BACKGROUND" n
  list_wallpapers
  echo "Background image"
  for ((i=0; i<${#WALLS[@]}; i++)); do printf '  %d) %s\n' "$((i+1))" "$(basename "${WALLS[$i]}")"; done
  echo "  n) none        o) own image file"
  def=n
  for ((i=0; i<${#WALLS[@]}; i++)); do [[ "$(wall_path "${WALLS[$i]}")" == "$cur" ]] && def=$((i+1)); done
  [[ "$def" == n && "$cur" != none ]] && def=o
  while :; do
    a="$(prompt "  choice" "$def")" || EOF_SEEN=1
    case "$a" in
      n|none) TT_BACKGROUND=none; return ;;
      o|own)
        a="$(prompt "  path to image" "$([[ "$cur" == none ]] || printf '%s' "$cur")")" || EOF_SEEN=1
        case "$a" in "~/"*) a="$HOME/${a#\~/}" ;; '$HOME/'*) a="$HOME/${a#\$HOME/}" ;; esac
        if [[ -f "$a" ]]; then TT_BACKGROUND="$a"; return; else echo "  $a: not found"; fi ;;
      *)
        n=0
        for ((i=0; i<${#WALLS[@]}; i++)); do if [[ "$a" == "$((i+1))" ]]; then TT_BACKGROUND="$(wall_path "${WALLS[$i]}")"; return; fi; done
        echo "  pick a number, n or o" ;;
    esac
    if (( EOF_SEEN )); then warn "no valid answer before end of input; keeping $TT_BACKGROUND"; return; fi
  done
}
ask_panes() {
  local a
  echo "Layout"; echo "  2) sidebar + work"; echo "  3) sidebar + work + shell"
  while :; do
    a="$(prompt "  panes" "$TT_PANES")" || EOF_SEEN=1
    case "$a" in 2|3) TT_PANES="$a"; return ;; *) echo "  2 or 3" ;; esac
    if (( EOF_SEEN )); then return; fi
  done
}
ask_sidebar() {
  local a i s
  echo "Sidebar tool"; i=0; for s in $SIDEBARS; do i=$((i+1)); printf '  %d) %s\n' "$i" "$s"; done
  while :; do
    a="$(prompt "  tool" "$TT_SIDEBAR")" || EOF_SEEN=1
    i=0; for s in $SIDEBARS; do i=$((i+1)); if [[ "$a" == "$i" || "$a" == "$s" ]]; then TT_SIDEBAR="$s"; return; fi; done
    echo "  pick a number or a name"
    if (( EOF_SEEN )); then return; fi
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
  # btop needs ~80 columns; give it a wider sidebar
  if [[ "$TT_PANES" == 2 ]]; then side="25%"; work="75%"; [[ "$TT_SIDEBAR" == btop ]] && { side="40%"; work="60%"; }
  else side="22%"; work="56%"; [[ "$TT_SIDEBAR" == btop ]] && { side="36%"; work="42%"; }; fi
  echo '        pane split_direction="vertical" {'
  echo "            pane name=\"files\" size=\"$side\"$cmd borderless=true"
  echo "            pane name=\"work\" size=\"$work\" focus=true"
  [[ "$TT_PANES" == 3 ]] && echo '            pane name="shell" size="22%"'
  echo '        }'
}
# replace_file FILE < new content : write in place, keeping symlinks and mode
replace_file() { local t rc=0; t="$(mktemp -t tt-file.XXXXXX)"; cat > "$t" || rc=$?; if [[ $rc == 0 && -s "$t" ]]; then cat "$t" > "$1"; else warn "$1: not rewritten (generation failed)"; fi; rm -f "$t"; }
apply_zellij() {
  local f blockfile nb ne
  blockfile="$(mktemp -t tt-panes.XXXXXX)"; render_panes > "$blockfile"
  for f in "$HOME/.config/zellij/layouts/dev.kdl" "$HOME/.config/zellij/layouts/dev-tab.kdl"; do
    [[ -f "$f" ]] || continue
    nb="$(grep -c 'tt:panes-begin' "$f" || true)"; ne="$(grep -c 'tt:panes-end' "$f" || true)"
    if [[ "$nb" != 1 || "$ne" != 1 ]] || [[ "$(grep -n 'tt:panes-begin' "$f" | cut -d: -f1)" -gt "$(grep -n 'tt:panes-end' "$f" | cut -d: -f1)" ]]; then
      warn "$f: tt:panes markers missing or broken, left unchanged"; continue
    fi
    awk -v blockfile="$blockfile" '
      /tt:panes-begin/ { print; while ((getline line < blockfile) > 0) print line; close(blockfile); skip=1; next }
      /tt:panes-end/   { skip=0 }
      !skip { print }' "$f" > "$blockfile.out" && replace_file "$f" < "$blockfile.out"; rm -f "$blockfile.out"
  done
  rm -f "$blockfile"
}
apply_ghostty() {
  local f="$HOME/.config/ghostty/config" shown bg="$TT_BACKGROUND"
  [[ -f "$f" ]] || return 0
  if [[ "$bg" != none && ! -f "$bg" ]]; then warn "background image $bg not found; background disabled until it exists"; bg=none; fi
  if [[ "$bg" == none ]]; then
    local t; t="$(mktemp -t tt-ghostty.XXXXXX)"
    awk '/^[# ]*background-image *=/ { sub(/^[# ]*/, "#"); } { print }' "$f" > "$t" && replace_file "$f" < "$t"; rm -f "$t"
  else
    shown="$bg"; [[ "$shown" == "$HOME/"* ]] && shown="~/${shown#$HOME/}"
    if grep -q '^[# ]*background-image *=' "$f"; then
      local t; t="$(mktemp -t tt-ghostty.XXXXXX)"
      TT_SHOWN="$shown" awk 'BEGIN { done=0 }
        /^[# ]*background-image *=/ { if (!done) { print "background-image = " ENVIRON["TT_SHOWN"]; done=1 }; next }
        { print }' "$f" > "$t" && replace_file "$f" < "$t"; rm -f "$t"
    else
      printf 'background-image = %s\n' "$shown" >> "$f"
    fi
  fi
}
apply() {
  local parts="${TT_APPLY:-zellij ghostty}"
  [[ " $parts " == *" zellij "* ]] && apply_zellij
  [[ " $parts " == *" ghostty "* ]] && apply_ghostty
  return 0
}
ask_all() {
  read_conf
  ask_background; ask_panes; ask_sidebar
  write_conf
  echo "Saved to ~/.config/terminal-tooling/setup.conf (background: $TT_BACKGROUND, panes: $TT_PANES, sidebar: $TT_SIDEBAR)."
}

case "${1:-}" in
  --defaults) [[ -f "$CONF" ]] || write_conf ;;
  --apply) read_conf; [[ -f "$CONF" ]] || write_conf; apply ;;
  --ask) ask_all ;;
  "") ask_all; apply; echo "Open a new Ghostty window (or restart Zellij) to see the change." ;;
  -h|--help) sed -n '2,8p' "$0"; exit 0 ;;
  *) echo "setup.sh: unknown argument '$1'" >&2; exit 2 ;;
esac
