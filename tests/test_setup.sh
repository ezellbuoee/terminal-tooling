#!/bin/bash
# Tests for setup.sh: answers -> setup.conf -> regenerated layouts and Ghostty background.
set -u
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
casefail=0
ok() { (( casefail )) || echo "ok $1"; casefail=0; }
bad() { echo "FAIL $1: $2"; fail=1; casefail=1; }

# a HOME with the shipped configs installed (as install.sh would leave them, author's paths)
newhome() {
  casefail=0
  tmp="$(mktemp -d)"
  mkdir -p "$tmp/.config/terminal-tooling" "$tmp/.config/zellij/layouts" "$tmp/.config/ghostty" "$tmp/Pictures/ghostty"
  cp "$R"/config/zellij/layouts/dev.kdl "$R"/config/zellij/layouts/dev-tab.kdl "$tmp/.config/zellij/layouts/"
  sed -i '' "s|/Users/eolasehinde|$tmp|g" "$tmp"/.config/zellij/layouts/*.kdl
  cp "$R/config/ghostty/config" "$tmp/.config/ghostty/config"
  cp "$R"/pictures/ghostty/* "$tmp/Pictures/ghostty/"
}
run() { HOME="$tmp" bash "$R/setup.sh" "$@" >"$tmp/.out" 2>"$tmp/.err"; }
conf() { grep "^$1=" "$tmp/.config/terminal-tooling/setup.conf" | cut -d= -f2-; }
panes() { sed -n '/tt:panes-begin/,/tt:panes-end/p' "$1"; }

# 1. --defaults writes the default answers and leaves the layouts byte-identical to the shipped ones
newhome; run --defaults && run --apply
[[ "$(conf TT_PANES)" == 3 && "$(conf TT_SIDEBAR)" == yazi && "$(conf TT_BACKGROUND)" == "$tmp/Pictures/ghostty/yujiro-demon-back.jpg" ]] || bad 1 "defaults wrong: $(cat "$tmp/.config/terminal-tooling/setup.conf")"
# (install.sh rewrites the author's home path to $HOME, so compare against that)
cmp -s "$tmp/.config/zellij/layouts/dev.kdl" <(sed "s|/Users/eolasehinde|$tmp|g" "$R/config/zellij/layouts/dev.kdl") \
  && cmp -s "$tmp/.config/zellij/layouts/dev-tab.kdl" <(sed "s|/Users/eolasehinde|$tmp|g" "$R/config/zellij/layouts/dev-tab.kdl") \
  && grep -q '^background-image = ~/Pictures/ghostty/yujiro-demon-back.jpg$' "$tmp/.config/ghostty/config" \
  && ok 1 || bad 1 "defaults changed the shipped files"

# 2. piped answers: own image, 2 panes, lazygit
newhome; touch "$tmp/mine.png"
printf 'o\n%s\n2\n2\n' "$tmp/mine.png" | run
[[ "$(conf TT_BACKGROUND)" == "$tmp/mine.png" && "$(conf TT_PANES)" == 2 && "$(conf TT_SIDEBAR)" == lazygit ]] || bad 2 "conf: $(cat "$tmp/.config/terminal-tooling/setup.conf")"
p="$(panes "$tmp/.config/zellij/layouts/dev.kdl")"
[[ "$p" == *'name="files" size="25%" command="lazygit" borderless=true'* && "$p" == *'name="work" size="75%" focus=true'* && "$p" != *'name="shell"'* ]] \
  && [[ "$(panes "$tmp/.config/zellij/layouts/dev-tab.kdl")" == *'command="lazygit"'* ]] \
  && grep -q "^background-image = ~/mine.png\$" "$tmp/.config/ghostty/config" \
  && ok 2 || bad 2 "layout/ghostty not regenerated: $p"

# 3. the rest of the layout file is untouched by a regeneration
newhome; printf '1\n2\n3\n' | run
diff <(sed '/tt:panes-begin/,/tt:panes-end/d' "$tmp/.config/zellij/layouts/dev.kdl") <(sed -e "s|/Users/eolasehinde|$tmp|g" -e '/tt:panes-begin/,/tt:panes-end/d' "$R/config/zellij/layouts/dev.kdl") >/dev/null \
  && [[ "$(panes "$tmp/.config/zellij/layouts/dev.kdl")" == *'name="files" size="40%" command="btop" borderless=true'* ]] && ok 3 || bad 3 "outside the markers changed, or btop missing"

# 4. background "none" comments the line out; choosing an image again restores it
newhome; printf 'n\n3\n1\n' | run
grep -q '^#background-image = ' "$tmp/.config/ghostty/config" && ! grep -q '^background-image = ' "$tmp/.config/ghostty/config" || bad 4 "none did not comment the line"
printf '2\n3\n1\n' | run
grep -q "^background-image = ~/Pictures/ghostty/baki-faceoff.jpg\$" "$tmp/.config/ghostty/config" && [[ "$(grep -c 'background-image = ' "$tmp/.config/ghostty/config")" == 1 ]] && ok 4 || bad 4 "image not restored (or duplicated)"

# 5. an own path that does not exist is re-asked; "shell" sidebar has no command attribute
newhome; printf 'o\n/nonexistent.png\no\n%s\n3\n4\n' "$tmp/Pictures/ghostty/sakura-night.png" | run
[[ "$(conf TT_BACKGROUND)" == "$tmp/Pictures/ghostty/sakura-night.png" && "$(conf TT_SIDEBAR)" == shell ]] \
  && [[ "$(panes "$tmp/.config/zellij/layouts/dev.kdl")" == *'pane name="files" size="22%" borderless=true'* ]] \
  && grep -q "not found" "$tmp/.out" && ok 5 || bad 5 "$(cat "$tmp/.out" | tail -3)"

# 6. Enter keeps the defaults; --apply twice is idempotent; missing zellij/ghostty configs are tolerated
newhome; printf '\n\n\n' | run
[[ "$(conf TT_PANES)" == 3 && "$(conf TT_SIDEBAR)" == yazi ]] || bad 6 "Enter did not keep defaults"
cp "$tmp/.config/zellij/layouts/dev.kdl" "$tmp/.dev1"; run --apply
cmp -s "$tmp/.dev1" "$tmp/.config/zellij/layouts/dev.kdl" || bad 6 "apply not idempotent"
rm -rf "$tmp/.config/zellij" "$tmp/.config/ghostty"; run --apply && [[ ! -s "$tmp/.err" ]] && ok 6 || bad 6 "apply failed without configs: $(cat "$tmp/.err")"

# 7. --apply without a conf uses defaults and writes the conf; another user's HOME path is used in the sidebar command
newhome; run --apply
[[ -f "$tmp/.config/terminal-tooling/setup.conf" ]] && [[ "$(panes "$tmp/.config/zellij/layouts/dev.kdl")" == *"command=\"$tmp/.config/zellij/bin/files-pane\""* ]] && ok 7 || bad 7 "conf missing or sidebar command path wrong"

# 8. a bad value on the last conf line is ignored with a warning; apply still succeeds
newhome; mkdir -p "$tmp/.config/terminal-tooling"; printf 'TT_PANES=2\nTT_SIDEBAR=nvim' > "$tmp/.config/terminal-tooling/setup.conf"
run --apply; rc=$?
[[ $rc == 0 ]] && grep -q "ignoring TT_SIDEBAR=nvim" "$tmp/.err" && [[ "$(panes "$tmp/.config/zellij/layouts/dev.kdl")" == *'size="25%"'*'files-pane'* ]] && ok 8 || bad 8 "rc=$rc err=$(cat "$tmp/.err")"

# 9. TT_APPLY=zellij leaves the Ghostty config byte-identical
newhome; printf 'font-size = 14\n' > "$tmp/.config/ghostty/config"; TT_APPLY=zellij run --apply
[[ "$(cat "$tmp/.config/ghostty/config")" == "font-size = 14" ]] && ok 9 || bad 9 "ghostty touched: $(cat "$tmp/.config/ghostty/config")"

# 10. a begin marker without an end marker leaves the file unchanged and warns
newhome; sed -i '' '/tt:panes-end/d' "$tmp/.config/zellij/layouts/dev-tab.kdl"; cp "$tmp/.config/zellij/layouts/dev-tab.kdl" "$tmp/.tab1"
printf '1\n2\n2\n' | run
cmp -s "$tmp/.tab1" "$tmp/.config/zellij/layouts/dev-tab.kdl" && grep -q "markers missing or broken" "$tmp/.err" && [[ "$(panes "$tmp/.config/zellij/layouts/dev.kdl")" == *lazygit* ]] && ok 10 || bad 10 "broken-marker file changed or no warning"

# 11. paths with & or | are written literally (no sed mangling)
newhome; mkdir -p "$tmp/a&b"; touch "$tmp/a&b/x.jpg"; printf 'TT_BACKGROUND=%s\nTT_PANES=3\nTT_SIDEBAR=yazi\n' "$tmp/a&b/x.jpg" > "$tmp/.config/terminal-tooling/setup.conf"; run --apply
grep -qF "background-image = ~/a&b/x.jpg" "$tmp/.config/ghostty/config" && [[ "$(grep -c '^background-image = ' "$tmp/.config/ghostty/config")" == 1 ]] || bad 11 "& path mangled: $(grep background-image "$tmp/.config/ghostty/config")"
mkdir -p "$tmp/c|d"; touch "$tmp/c|d/y.png"; printf 'o\n%s\n3\n1\n' "$tmp/c|d/y.png" | run
[[ "$(conf TT_BACKGROUND)" == "$tmp/c|d/y.png" ]] && grep -qF "background-image = ~/c|d/y.png" "$tmp/.config/ghostty/config" && ok 11 || bad 11 "| path: $(conf TT_BACKGROUND)"

# 12. a saved image that no longer exists: end of input keeps the answer, apply disables the background with a warning
newhome; printf 'TT_BACKGROUND=%s/gone.png\nTT_PANES=3\nTT_SIDEBAR=yazi\n' "$tmp" > "$tmp/.config/terminal-tooling/setup.conf"
( HOME="$tmp" bash "$R/setup.sh" </dev/null >"$tmp/.out" 2>"$tmp/.err" & p=$!; ( sleep 5; kill $p 2>/dev/null ) & w=$!; wait $p; echo $? > "$tmp/.rc"; kill $w 2>/dev/null ) 2>/dev/null
[[ "$(cat "$tmp/.rc")" == 0 && "$(conf TT_BACKGROUND)" == "$tmp/gone.png" ]] && grep -q "not found; background disabled" "$tmp/.err" && grep -q '^#background-image = ' "$tmp/.config/ghostty/config" && ok 12 || bad 12 "rc=$(cat "$tmp/.rc") bg=$(conf TT_BACKGROUND) err=$(head -1 "$tmp/.err")"

# 13. a wallpaper with spaces in its name is one entry and selectable
newhome; touch "$tmp/Pictures/ghostty/a my wall.jpg"; printf '1\n3\n1\n' | run
grep -q "1) a my wall.jpg" "$tmp/.out" && [[ "$(conf TT_BACKGROUND)" == "$tmp/Pictures/ghostty/a my wall.jpg" ]] && grep -qF "background-image = ~/Pictures/ghostty/a my wall.jpg" "$tmp/.config/ghostty/config" && ok 13 || bad 13 "space name split: $(grep '1)' "$tmp/.out")"

# 14. other spellings of the Ghostty key are handled, and never duplicated
newhome; printf 'font-size = 14\n# background-image = old.jpg\n' > "$tmp/.config/ghostty/config"; printf '2\n3\n1\n' | run
[[ "$(grep -c 'background-image' "$tmp/.config/ghostty/config")" == 1 ]] && grep -q '^background-image = ~/Pictures/ghostty/baki-faceoff.jpg$' "$tmp/.config/ghostty/config" || bad 14 "commented variant: $(cat "$tmp/.config/ghostty/config")"
printf 'font-size = 14\nbackground-image=x.jpg\n' > "$tmp/.config/ghostty/config"; printf 'n\n3\n1\n' | run
[[ "$(cat "$tmp/.config/ghostty/config")" == $'font-size = 14\n#background-image=x.jpg' ]] && ok 14 || bad 14 "no-space variant: $(cat "$tmp/.config/ghostty/config")"

# 15. a last answer without a trailing newline still counts; setup.conf CRLF tolerated
newhome; printf '1\n3\n2' | run
[[ "$(conf TT_SIDEBAR)" == lazygit ]] || bad 15 "last answer dropped"
printf 'TT_PANES=2\r\nTT_SIDEBAR=btop\r\n' > "$tmp/.config/terminal-tooling/setup.conf"; run --apply
[[ "$(panes "$tmp/.config/zellij/layouts/dev.kdl")" == *'command="btop"'* && ! -s "$tmp/.err" ]] && ok 15 || bad 15 "CRLF conf: $(cat "$tmp/.err")"

# 16. a layout that is a symlink stays a symlink and its target is updated
newhome; mv "$tmp/.config/zellij/layouts/dev.kdl" "$tmp/dev.real"; ln -s "$tmp/dev.real" "$tmp/.config/zellij/layouts/dev.kdl"; printf '1\n2\n1\n' | run
[[ -L "$tmp/.config/zellij/layouts/dev.kdl" ]] && [[ "$(panes "$tmp/dev.real")" == *'size="25%"'* ]] && ok 16 || bad 16 "symlink replaced"

# 17. before the wallpapers are copied (empty ~/Pictures), the default and a picked image still point at ~/Pictures/ghostty
newhome; rm -rf "$tmp/Pictures/ghostty"; mkdir -p "$tmp/Pictures"; run --defaults
[[ "$(conf TT_BACKGROUND)" == "$tmp/Pictures/ghostty/yujiro-demon-back.jpg" ]] || bad 17 "default: $(conf TT_BACKGROUND)"
rm -f "$tmp/.config/terminal-tooling/setup.conf"; printf '2\n3\n1\n' | run --ask
[[ "$(conf TT_BACKGROUND)" == "$tmp/Pictures/ghostty/baki-faceoff.jpg" ]] && ok 17 || bad 17 "picked: $(conf TT_BACKGROUND)"

# 18. end of input after an invalid answer stops the questions with a warning (no loop); an unsafe saved path is ignored
newhome; ( printf 'x' | HOME="$tmp" bash "$R/setup.sh" --ask >"$tmp/.out" 2>"$tmp/.err" & p=$!; ( sleep 5; kill $p 2>/dev/null ) & w=$!; wait $p; echo $? > "$tmp/.rc"; kill $w 2>/dev/null ) 2>/dev/null
[[ "$(cat "$tmp/.rc")" == 0 ]] && grep -q "end of input" "$tmp/.err" && [[ "$(grep -c 'pick a number' "$tmp/.out")" == 1 ]] || bad 18 "rc=$(cat "$tmp/.rc") prompts=$(grep -c 'pick a number' "$tmp/.out")"
printf 'TT_BACKGROUND=\nTT_PANES=3\nTT_SIDEBAR=yazi\n' > "$tmp/.config/terminal-tooling/setup.conf"
( HOME="$tmp" bash "$R/setup.sh" --ask </dev/null >"$tmp/.out" 2>"$tmp/.err" & p=$!; ( sleep 5; kill $p 2>/dev/null ) & w=$!; wait $p; echo $? > "$tmp/.rc"; kill $w 2>/dev/null ) 2>/dev/null
[[ "$(cat "$tmp/.rc")" == 0 ]] && grep -q "ignoring empty TT_BACKGROUND" "$tmp/.err" && ok 18 || bad 18 "empty path: rc=$(cat "$tmp/.rc") $(head -2 "$tmp/.err")"

exit $fail
