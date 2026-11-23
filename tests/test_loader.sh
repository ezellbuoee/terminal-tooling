#!/bin/bash
# Tests for zsh/init.zsh and the modules. Compatible with bash 3.2.
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

fail() { echo "FAIL: $1" >&2; exit 1; }

# run_zsh <setup-snippet> : prints TT_LOADED; stderr in $tmp/err
run_zsh() {
  HOME="$tmp" zsh -f -c "TT_DIR='$1'; $2; source \$TT_DIR/init.zsh; $3" 2>"$tmp/err"
}

# 1. default: all eight names, in order
out=$(run_zsh "$ROOT/zsh" ':' 'print -r -- $TT_LOADED')
[[ "$out" == "omz tools ghostty fzf keys mouse yazi starship" ]] || fail "case 1: got '$out'"
echo "ok 1"

# 2. TT_DISABLE via local.zsh
d="$tmp/d2"; mkdir -p "$d"; cp -R "$ROOT/zsh/init.zsh" "$ROOT/zsh/modules" "$d/"
echo 'TT_DISABLE=(mouse starship)' > "$d/local.zsh"
out=$(run_zsh "$d" ':' 'print -r -- $TT_LOADED')
[[ "$out" == "omz tools ghostty fzf keys yazi" ]] || fail "case 2: got '$out'"
echo "ok 2"

# 3. TT_ONLY
d="$tmp/d3"; mkdir -p "$d"; cp -R "$ROOT/zsh/init.zsh" "$ROOT/zsh/modules" "$d/"
echo 'TT_ONLY=(tools)' > "$d/local.zsh"
out=$(run_zsh "$d" ':' 'print -r -- $TT_LOADED')
[[ "$out" == "tools" ]] || fail "case 3: got '$out'"
echo "ok 3"

# 4. missing tools: silent, exit 0
HOME="$tmp" PATH=/usr/bin:/bin zsh -f -c "TT_DIR='$ROOT/zsh'; source \$TT_DIR/init.zsh" 2>"$tmp/err"
rc=$?
[[ $rc -eq 0 ]] || fail "case 4: exit $rc"
[[ ! -s "$tmp/err" ]] || fail "case 4: stderr not empty: $(cat "$tmp/err")"
echo "ok 4"

# 5. tt_after runs after modules
d="$tmp/d5"; mkdir -p "$d"; cp -R "$ROOT/zsh/init.zsh" "$ROOT/zsh/modules" "$d/"
echo 'tt_after() { TT_AFTER_RAN=1 }' > "$d/local.zsh"
out=$(run_zsh "$d" ':' 'print -r -- ${TT_AFTER_RAN:-unset}')
[[ "$out" == "1" ]] || fail "case 5: got '$out'"
echo "ok 5"

# 6. omz disabled, no autosuggestions: keys module is silent
d="$tmp/d6"; mkdir -p "$d"; cp -R "$ROOT/zsh/init.zsh" "$ROOT/zsh/modules" "$d/"
echo 'TT_DISABLE=(omz)' > "$d/local.zsh"
HOME="$tmp" PATH=/usr/bin:/bin zsh -f -c "TT_DIR='$d'; source \$TT_DIR/init.zsh" 2>"$tmp/err"
[[ ! -s "$tmp/err" ]] || fail "case 6: stderr not empty: $(cat "$tmp/err")"
echo "ok 6"
