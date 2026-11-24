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
if [[ -d "$tmp/.config/zellij" && ! -e "$tmp/.config/yazi" && ! -e "$tmp/.zshrc" && ! -e "$tmp/.config/terminal-tooling/init.zsh" ]]; then ok G; else bad G "wrong set installed"; fi

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

# stubbed oh-my-zsh installer: like the real one with KEEP_ZSHRC=yes, writes a template .zshrc only if none exists
ompinst() { printf '#!/bin/sh\ntouch "%s/.omz-ran"\nmkdir -p "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions"\n[ -e "$HOME/.zshrc" ] || echo "OMZ TEMPLATE" > "$HOME/.zshrc"\n' "$tmp" > "$tmp/omz-stub.sh"
  TT_OMZ_INSTALLER="$tmp/omz-stub.sh"; export TT_OMZ_INSTALLER; }
freshhome() { tmp="$(mktemp -d)"; mkdir -p "$tmp/zsh-syntax-highlighting"; ompinst; }

# M: fresh Mac, no .zshrc, oh-my-zsh not installed: .zshrc is exactly the block, installer ran
freshhome; inst
[[ -e "$tmp/.omz-ran" && "$(cat "$tmp/.zshrc")" == "$BLOCK" ]] && ok M || bad M "zshrc: $(cat "$tmp/.zshrc" 2>/dev/null)"

# N: --skip omz does not run the oh-my-zsh step
freshhome; inst --skip omz
[[ ! -e "$tmp/.omz-ran" && ! -d "$tmp/.oh-my-zsh" ]] && ok N || bad N "omz step ran"

# U: --only shell on a fresh HOME runs the omz step; .zshrc is exactly the block
freshhome; inst --only shell
[[ -e "$tmp/.omz-ran" && "$(cat "$tmp/.zshrc")" == "$BLOCK" ]] && ok U || bad U "omz step or zshrc wrong"

# V: --skip shell on a fresh HOME does not run the omz step and creates no .zshrc
freshhome; inst --skip shell; inst
[[ ! -e "$tmp/.omz-ran" && ! -e "$tmp/.zshrc" ]] && ok V || bad V "omz ran or zshrc created"
unset TT_OMZ_INSTALLER

# O: --skip persists across plain re-runs
newhome; mkdir -p "$tmp/.config/nvim"; echo x > "$tmp/.config/nvim/mine.lua"; inst --skip nvim; inst
if [[ -f "$tmp/.config/nvim/mine.lua" && ! -d "$tmp/.config/nvim/lua" ]] && ! ls -d "$tmp"/.config-backup-*/.config/nvim >/dev/null 2>&1 \
  && grep -qx nvim "$tmp/.config/terminal-tooling/skip"; then ok O; else bad O "nvim skip not persistent"; fi

# P: --skip shell then plain re-run never adds the managed line
newhome; inst --skip shell; inst
[[ ! -e "$tmp/.zshrc" && ! -e "$tmp/.config/terminal-tooling/init.zsh" ]] && ok P || bad P "shell installed"

# Q: skip file merges, sorted unique; --only neither reads nor writes it
newhome; inst --skip zellij,nvim; inst --skip nvim,btop
[[ "$(cat "$tmp/.config/terminal-tooling/skip")" == "$(printf 'btop\nnvim\nzellij')" ]] || bad Q "merge wrong"
cp "$tmp/.config/terminal-tooling/skip" "$tmp/skip.1"; rm -rf "$tmp/.config/zellij"; inst --only zellij
cmp -s "$tmp/skip.1" "$tmp/.config/terminal-tooling/skip" && [[ -d "$tmp/.config/zellij" ]] && ok Q || bad Q "--only changed or obeyed skip file"

# R: read-only .zshrc via symlink: install continues, block printed, exit 0
newhome; echo "alias x=1" > "$tmp/real-zshrc"; chmod 444 "$tmp/real-zshrc"; ln -s "$tmp/real-zshrc" "$tmp/.zshrc"; inst; rc=$?
if [[ $rc == 0 && -d "$tmp/.config/zellij" && "$(cat "$tmp/real-zshrc")" == "alias x=1" ]] && grep -qF "$BLOCK" "$tmp/.out" \
  && grep -q 'add this to your ~/.zshrc' "$tmp/.out"; then ok R; else bad R "rc=$rc"; fi

# S: writable symlink: appended to target
newhome; echo "alias x=1" > "$tmp/real-zshrc"; ln -s "$tmp/real-zshrc" "$tmp/.zshrc"; inst
grep -qF 'terminal-tooling (managed' "$tmp/real-zshrc" && grep -q 'symlink' "$tmp/.out" && ok S || bad S "not appended to target"

# T: empty lists are usage errors and change nothing
t=1
for args in "--only ''" "--only ," "--skip ''" "--skip ,"; do
  newhome; eval "inst $args"; rc=$?
  [[ $rc == 2 && ! -e "$tmp/.zshrc" && ! -e "$tmp/.config" ]] || { t=0; bad T "'$args' rc=$rc"; }
done
[[ $t == 1 ]] && ok T

# W: a non-interactive install writes default setup answers and regenerates the layout for this HOME
newhome; inst
[[ "$(grep ^TT_PANES= "$tmp/.config/terminal-tooling/setup.conf")" == "TT_PANES=3" ]] \
  && grep -q "command=\"$tmp/.config/zellij/bin/files-pane\"" "$tmp/.config/zellij/layouts/dev.kdl" && ok W || bad W "setup defaults not applied"

# X: existing setup answers survive a re-install (2 panes, btop sidebar)
newhome; mkdir -p "$tmp/.config/terminal-tooling"; printf 'TT_BACKGROUND=none\nTT_PANES=2\nTT_SIDEBAR=btop\n' > "$tmp/.config/terminal-tooling/setup.conf"; inst
p="$(sed -n '/tt:panes-begin/,/tt:panes-end/p' "$tmp/.config/zellij/layouts/dev-tab.kdl")"
[[ "$p" == *'command="btop"'* && "$p" != *'name="shell"'* ]] && grep -q '^#background-image = ' "$tmp/.config/ghostty/config" && ok X || bad X "answers not re-applied: $p"

# Y: fresh Mac (empty ~/Pictures, no wallpapers yet): a non-interactive install keeps the default wallpaper
newhome; mkdir -p "$tmp/Pictures"; inst --only zellij,ghostty-config,wallpapers
[[ "$(grep ^TT_BACKGROUND= "$tmp/.config/terminal-tooling/setup.conf")" == "TT_BACKGROUND=$tmp/Pictures/ghostty/yujiro-demon-back.jpg" ]] \
  && grep -q '^background-image = ~/Pictures/ghostty/yujiro-demon-back.jpg$' "$tmp/.config/ghostty/config" && ok Y || bad Y "default wallpaper lost: $(grep background-image "$tmp/.config/ghostty/config" | head -1)"

exit $fail
