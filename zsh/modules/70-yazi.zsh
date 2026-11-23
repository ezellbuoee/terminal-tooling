# yazi: when it quits (or "cd to path" is chosen), the shell follows into that folder
if command -v yazi >/dev/null 2>&1; then
  y() { local tmp; tmp="$(mktemp -t yazi-cwd.XXXXXX)"; command yazi "$@" --cwd-file="$tmp"; local d; d="$(cat -- "$tmp" 2>/dev/null)"; rm -f -- "$tmp"; [[ -n "$d" && "$d" != "$PWD" ]] && cd -- "$d"; }
  alias yazi=y
fi
true
