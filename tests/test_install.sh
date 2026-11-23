#!/bin/bash
# Tests for install.sh. Never touches the network or the real HOME.
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
BLOCK='# terminal-tooling (managed line; remove to opt out entirely)
[[ -f ~/.config/terminal-tooling/init.zsh ]] && source ~/.config/terminal-tooling/init.zsh'

newhome() {
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$tmp/zsh-syntax-highlighting"
}
inst() { mkdir -p "$tmp/.stub"; printf '#!/bin/sh\ntouch "%s/.ya-ran"\n' "$tmp" > "$tmp/.stub/ya"; chmod +x "$tmp/.stub/ya"
  PATH="$tmp/.stub:$PATH" HOME="$tmp" SKIP_BREW=1 bash "$R/install.sh" "$@" >"$tmp/.out" 2>"$tmp/.err"; }
ok() { echo "ok $1"; }
bad() { echo "FAIL $1: $2"; fail=1; }

# A
newhome; inst
[[ "$(cat "$tmp/.zshrc" 2>/dev/null)" == "$BLOCK" ]] && ok A || bad A "zshrc is not exactly the block"

# B
newhome; echo "alias x=1" > "$tmp/.zshrc"; inst
exp="$(printf 'alias x=1\n\n%s' "$BLOCK")"
[[ "$(cat "$tmp/.zshrc")" == "$exp" ]] || bad B "content wrong"
cp "$tmp/.zshrc" "$tmp/.zshrc.1"; inst
cmp -s "$tmp/.zshrc" "$tmp/.zshrc.1" && [[ "$(grep -c 'terminal-tooling (managed' "$tmp/.zshrc")" == 1 ]] && ok B || bad B "not idempotent"

# C
newhome; inst
d="$tmp/.config/terminal-tooling"
[[ -f $d/init.zsh && -f $d/modules/60-mouse.zsh ]] && cmp -s "$d/local.zsh" "$R/zsh/local.zsh.example" && ok C || bad C "files missing or local.zsh differs"

# D
newhome; mkdir -p "$tmp/.config/terminal-tooling"; echo "TT_DISABLE=(mouse)" > "$tmp/.config/terminal-tooling/local.zsh"
cp "$tmp/.config/terminal-tooling/local.zsh" "$tmp/l.orig"; inst
cmp -s "$tmp/l.orig" "$tmp/.config/terminal-tooling/local.zsh" && ok D || bad D "local.zsh overwritten"

# E
newhome; mkdir -p "$tmp/.config/nvim"; echo x > "$tmp/.config/nvim/mine.lua"; inst --skip nvim
if [[ -f "$tmp/.config/nvim/mine.lua" ]] && ! ls -d "$tmp"/.config-backup-*/.config/nvim >/dev/null 2>&1; then ok E; else bad E "nvim touched"; fi

# F
newhome; inst --skip mouse,starship
grep -qx 'TT_DISABLE=(mouse starship)' "$tmp/.config/terminal-tooling/local.zsh" && ok F || bad F "$(grep TT_DISABLE "$tmp/.config/terminal-tooling/local.zsh")"

# G
newhome; inst --only zellij
if [[ -d "$tmp/.config/zellij" && ! -e "$tmp/.config/yazi" && ! -e "$tmp/.zshrc" && ! -e "$tmp/.config/terminal-tooling" ]]; then ok G; else bad G "wrong set installed"; fi

# H
newhome; inst --skip bogus; rc=$?
[[ $rc == 2 ]] && grep -q bogus "$tmp/.err" && [[ ! -e "$tmp/.zshrc" ]] && ok H || bad H "rc=$rc"

# I
newhome; inst --skip mouse --only zellij; rc=$?
[[ $rc == 2 && ! -e "$tmp/.zshrc" && ! -e "$tmp/.config" ]] && ok I || bad I "rc=$rc"

# J: --only shell keeps all modules enabled
newhome; inst --only shell
grep -qx 'TT_DISABLE=()' "$tmp/.config/terminal-tooling/local.zsh" && ok J || bad J "$(grep TT_DISABLE "$tmp/.config/terminal-tooling/local.zsh")"

# K: --only mouse disables the other seven
newhome; inst --only mouse
grep -qx 'TT_DISABLE=(omz tools ghostty fzf keys yazi starship)' "$tmp/.config/terminal-tooling/local.zsh" && ok K || bad K "wrong TT_DISABLE"

# L: ya runs on full install, not with --skip yazi-config
newhome; inst; [[ -e "$tmp/.ya-ran" ]] || bad L "stub ya not used on full install"
newhome; inst --skip yazi-config
[[ ! -e "$tmp/.ya-ran" ]] && ok L || bad L "ya ran despite --skip yazi-config"

exit $fail
