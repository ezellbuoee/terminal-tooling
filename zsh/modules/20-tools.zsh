# CLI tool setup: Homebrew, zoxide, eza, bat, nvim. Each behind a check.
[[ -x /opt/homebrew/bin/brew ]] && eval "$(/opt/homebrew/bin/brew shellenv)"

command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -la --icons --git --group-directories-first'
  alias lt='eza --tree --level=2 --icons'
fi

if command -v bat >/dev/null 2>&1; then
  export BAT_THEME='Catppuccin Mocha'
  alias cat='bat --paging=never --style=plain'
fi

if command -v nvim >/dev/null 2>&1; then
  export EDITOR="nvim"
  export VISUAL="nvim"
  alias vim="nvim"
  alias vi="nvim"
fi
true
