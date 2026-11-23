# terminal-tooling loader. Source this from ~/.zshrc.
# Reads TT_DIR (default: directory of this file), then local.zsh, then modules.
: ${TT_DIR:=${${(%):-%x}:A:h}}

[[ -r "$TT_DIR/local.zsh" ]] && source "$TT_DIR/local.zsh"

typeset -a _tt_loaded
local _tt_file _tt_name
for _tt_file in "$TT_DIR"/modules/[0-9][0-9]-*.zsh(N); do
  _tt_name="${${_tt_file:t:r}#[0-9][0-9]-}"
  (( ${TT_DISABLE[(Ie)$_tt_name]} )) && continue
  if (( ${#TT_ONLY} )) && (( ! ${TT_ONLY[(Ie)$_tt_name]} )); then
    continue
  fi
  source "$_tt_file"
  _tt_loaded+=("$_tt_name")
done

(( $+functions[tt_after] )) && tt_after

export TT_LOADED="${(j: :)_tt_loaded}"
unset _tt_loaded _tt_file _tt_name
