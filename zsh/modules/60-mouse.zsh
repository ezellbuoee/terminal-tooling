# Click-to-move-cursor for the zsh line editor (works inside Zellij).
# Left click on the command line moves the cursor there. Double click selects
# the word, triple click the whole line. cmd+c copies the selection, cmd+v
# pastes (over a selection it replaces it), typing/backspace/delete over a
# selection replaces or removes it, ctrl+y pastes the last selection. Mouse wheel scrolls the Zellij pane.
# Shift+drag still selects text in the terminal itself.
zmodload zsh/datetime
typeset -g _ZM_LAST_T=0 _ZM_LAST_POS="" _ZM_CLICKS=0 _ZM_LAST_TARGET=0 _ZM_SEL=0

# Mouse reporting is only requested while the command line has text in it.
# With an empty line, a drag over command output goes to Zellij/Ghostty and is
# selected + copied as usual; with text, a click moves the cursor (see below).
typeset -gi _ZM_TRACK=0
_zle_mouse_on()  { [[ -o zle ]] && (( ! _ZM_TRACK )) && { printf '\e[?1000h\e[?1006h' > /dev/tty; _ZM_TRACK=1; } }
_zle_mouse_off() { [[ -o zle ]] && (( _ZM_TRACK )) && { printf '\e[?1006l\e[?1000l' > /dev/tty; _ZM_TRACK=0; } ; return 0 }
_zle_mouse_sync() { if [[ -n $BUFFER ]]; then _zle_mouse_on; else _zle_mouse_off; fi }

# Ask the terminal where the cursor is: answers "\e[row;colR"
_zle_cursor_pos() {
  local c cur="" pending=""
  printf '\e[6n' > /dev/tty
  while read -t 0.3 -k 1 c; do
    if [[ $c == $'\e' ]]; then
      # a mouse event queued before the answer (fast double click): keep it for later
      [[ $cur == $'\e['\<*[Mm] ]] && pending+=$cur
      cur=""
    fi
    cur+=$c
    [[ $c == R ]] && break
  done
  [[ -n $pending ]] && zle -U -- "$pending"
  [[ $cur == $'\e['*\;*R ]] || return 1
  cur=${cur#*\[}; cur=${cur%R}
  _ZM_ROW=${cur%%;*}; _ZM_COL=${cur##*;}
  [[ -n $_ZM_ROW && -n $_ZM_COL ]]
}

_zle_mouse_event() {
  local c seq="" btn col row
  while read -t 0.2 -k 1 c; do
    seq+=$c
    [[ $c == [Mm] ]] && break
  done
  [[ $seq == *M ]] || return 0          # only button presses
  seq=${seq%M}
  btn=${seq%%;*}; seq=${seq#*;}
  col=${seq%%;*}; row=${seq#*;}
  case $btn in
    64) zellij action scroll-up   2>/dev/null; return ;;
    65) zellij action scroll-down 2>/dev/null; return ;;
    0)  ;;
    *)  return ;;
  esac
  # count rapid clicks on the same cell; a repeat reuses the first click's
  # target (the line may not be redrawn yet, so asking the terminal would lie)
  local now=$EPOCHREALTIME target
  if [[ "$col;$row" == "$_ZM_LAST_POS" ]] && (( now - _ZM_LAST_T < 0.45 )); then
    (( _ZM_CLICKS++ )); target=$_ZM_LAST_TARGET
  else
    _ZM_CLICKS=1
    _zle_cursor_pos || return 0
    target=$(( CURSOR + (row - _ZM_ROW) * COLUMNS + (col - _ZM_COL) ))
    (( target < 0 )) && target=0
    (( target > $#BUFFER )) && target=$#BUFFER
  fi
  _ZM_LAST_T=$now; _ZM_LAST_POS="$col;$row"; _ZM_LAST_TARGET=$target

  case $_ZM_CLICKS in
    1) REGION_ACTIVE=0; _ZM_SEL=0; CURSOR=$target ;;
    2) _zle_select_word $target ;;
    *) MARK=0; CURSOR=$#BUFFER; REGION_ACTIVE=1; _zle_copy_region; _ZM_CLICKS=0 ;;
  esac
}

_zle_select_word() {
  local pos=$1 wc='[[:alnum:]_./~-]' s e
  (( pos >= $#BUFFER )) && pos=$(( $#BUFFER - 1 ))
  (( pos < 0 )) && return
  s=$pos; e=$pos
  if [[ ${BUFFER[pos+1]} == ${~wc} ]]; then
    while (( s > 0 )) && [[ ${BUFFER[s]} == ${~wc} ]]; do (( s-- )); done
    while (( e < $#BUFFER )) && [[ ${BUFFER[e+1]} == ${~wc} ]]; do (( e++ )); done
  else
    e=$(( pos + 1 ))
  fi
  MARK=$s; CURSOR=$e; REGION_ACTIVE=1
  _zle_copy_region
}

# remember the selection (ctrl+y pastes it); the system clipboard is only
# touched by cmd+c so that cmd+v can paste something else over a selection
_zle_copy_region() {
  _ZM_SEL=1
  local a=$MARK b=$CURSOR
  (( a > b )) && { local t=$a; a=$b; b=$t; }
  CUTBUFFER=${BUFFER[a+1,b]}
}
zle -N _zle_mouse_event
bindkey -M emacs '\e[<' _zle_mouse_event
bindkey -M viins '\e[<' _zle_mouse_event
bindkey -M vicmd '\e[<' _zle_mouse_event

autoload -Uz add-zle-hook-widget
add-zle-hook-widget line-init       _zle_mouse_sync
add-zle-hook-widget line-pre-redraw _zle_mouse_sync
add-zle-hook-widget line-finish     _zle_mouse_off

# Typing over a mouse selection replaces it.
_zle_drop_selection() {
  if (( REGION_ACTIVE && _ZM_SEL )); then
    zle kill-region
    _ZM_SEL=0
    return 0
  fi
  return 1
}
_zm_self-insert()          { _zle_drop_selection; zle _zm_orig_self-insert -- "$@"; }
_zm_bracketed-paste()      { _zle_drop_selection; zle _zm_orig_bracketed-paste -- "$@"; }
_zm_backward-delete-char() { _zle_drop_selection || zle _zm_orig_backward-delete-char -- "$@"; }
_zm_delete-char()          { _zle_drop_selection || zle _zm_orig_delete-char -- "$@"; }
for _w in self-insert bracketed-paste backward-delete-char delete-char; do
  (( ${+widgets[_zm_orig_$_w]} )) && continue   # already wrapped (file sourced twice)
  zle -A "$_w" "_zm_orig_$_w"
  zle -N "$_w" "_zm_$_w"
done
unset _w

# cmd+c (sent by Ghostty as an APC string, see ghostty config): copy the
# selection to the clipboard and keep it selected.
_zm_copy() {
  if (( REGION_ACTIVE )); then
    _zle_copy_region
    print -rn -- "$CUTBUFFER" | pbcopy 2>/dev/null
  fi
}
zle -N _zm_copy
bindkey -M emacs $'\e_zm:copy\e\\' _zm_copy
bindkey -M viins $'\e_zm:copy\e\\' _zm_copy
bindkey -M vicmd $'\e_zm:copy\e\\' _zm_copy

# cmd+z / cmd+shift+z (sent by Ghostty as APC strings): undo / redo
for _m in emacs viins vicmd; do
  bindkey -M $_m $'\e_zm:undo\e\\' undo
  bindkey -M $_m $'\e_zm:redo\e\\' redo
done
unset _m

