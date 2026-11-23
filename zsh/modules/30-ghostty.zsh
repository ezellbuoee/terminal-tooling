# ghostty shell integration (needed when windows start inside zellij)
if [[ "$TERM_PROGRAM" == "ghostty" || -n "$GHOSTTY_RESOURCES_DIR" ]]; then
  GHOSTTY_SI="${GHOSTTY_RESOURCES_DIR:-/Applications/Ghostty.app/Contents/Resources/ghostty}/shell-integration/zsh/ghostty-integration"
  [[ -f "$GHOSTTY_SI" ]] && source "$GHOSTTY_SI"
  unset GHOSTTY_SI
fi
true
