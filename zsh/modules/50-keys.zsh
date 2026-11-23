# word jumps: Option+Left/Right and Alt-b/Alt-f, Option+Backspace deletes a word
bindkey '^[[1;3D' backward-word
bindkey '^[[1;3C' forward-word
bindkey '^[b' backward-word
bindkey '^[f' forward-word
bindkey '^[^?' backward-kill-word
# Home/End and Cmd-Left/Right (Ghostty sends these as line start/end)
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
# accept an autosuggestion with Ctrl-Space
if (( $+widgets[autosuggest-accept] )); then bindkey '^ ' autosuggest-accept; fi
