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
  && [[ "$(panes "$tmp/.config/zellij/layouts/dev.kdl")" == *'name="files" size="25%" command="btop" borderless=true'* ]] && ok 3 || bad 3 "outside the markers changed, or btop missing"

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

exit $fail
