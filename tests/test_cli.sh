#!/bin/bash
# Tests for bin/terminal-tooling. Never touches the network or the real HOME.
R="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0
ok() { echo "ok $1"; }
bad() { echo "FAIL $1: $2"; fail=1; }

# 1
[[ "$("$R/bin/terminal-tooling" version)" == "terminal-tooling 2.0.0" ]] && ok 1 || bad 1 "version wrong"

# 2: flags reach install.sh (effects in temp HOME)
tmp="$(mktemp -d)"
mkdir -p "$tmp/.oh-my-zsh/custom/plugins/zsh-autosuggestions" "$tmp/zsh-syntax-highlighting" "$tmp/.stub"
printf '#!/bin/sh\nexit 0\n' > "$tmp/.stub/ya"; chmod +x "$tmp/.stub/ya"
PATH="$tmp/.stub:$PATH" HOME="$tmp" "$R/bin/terminal-tooling" configs --only zellij >"$tmp/.out" 2>"$tmp/.err"
if [[ -d "$tmp/.config/zellij" && ! -e "$tmp/.zshrc" && ! -e "$tmp/.config/yazi" ]]; then ok 2; else bad 2 "flags not passed through"; fi

# 3
h="$("$R/bin/terminal-tooling" help)"
[[ "$h" == *--skip* && "$h" == *--only* && "$h" == *local.zsh* && "$h" == *zellij* ]] && ok 3 || bad 3 "help text incomplete"

exit $fail
