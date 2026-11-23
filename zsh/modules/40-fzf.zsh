# fzf: Ctrl-R fuzzy history, Ctrl-T pick files into the command, Alt-C jump to a directory
if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
  export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded --color=bg+:#313244,bg:-1,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,selected-bg:#45475a,border:#6c7086'
fi
true
