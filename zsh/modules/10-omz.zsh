# oh-my-zsh, autosuggestions, syntax highlighting.
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME=""  # prompt handled by starship
plugins=(git zsh-autosuggestions zsh-interactive-cd)

[[ -r "$ZSH/oh-my-zsh.sh" ]] && source "$ZSH/oh-my-zsh.sh"

for _tt_f in /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
             /usr/local/share/zsh-autosuggestions/zsh-autosuggestions.zsh; do
  if [[ -f "$_tt_f" ]]; then source "$_tt_f"; break; fi
done
unset _tt_f
[[ -f "$HOME/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && source "$HOME/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# autosuggest color setting
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f8dda6"
true
