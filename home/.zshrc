# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
#if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
#fi  # p10k instant prompt disabled: replaced by starship


#Zelig
# Development workspaces
alias dev="zellij attach --create java-dev"
alias k8s="zellij attach --create k8s-lab"
alias dockerlab="zellij attach --create docker-lab"


#kubernates kubeconfigurations
##AGCS
agcskubectlprodaws() {
  KUBECONFIG=~/.kube/.kube_agcs/.kube_aws/config kubectl $@
}
alias agcsprodaws='agcskubectlprodaws'

agcskubectlprodrow() {
  KUBECONFIG=~/.kube/.kube_agcs/.kube_row/config kubectl $@
}

alias agcsprodrow='agcskubectlprodrow'

agcssternprodrow() {
  KUBECONFIG=~/.kube/.kube_agcs/.kube_row/config stern $@
}

alias sagcsprodrow='agcssternprodrow'

agcskubectlprodrowk9s() {
  KUBECONFIG=~/.kube/.kube_agcs/.kube_row/config k9s $@
}
alias agcsprodrowk9s='agcskubectlprodrowk9s'

agcskubectlprodshowcase() {
  KUBECONFIG=~/.kube/.kube_agcs/.kube_showcase/config kubectl $@
}

alias agcsshowcase='agcskubectlprodshowcase'


##COSMO DEV
cosmodev() {
  KUBECONFIG=~/.kube/.kube_cosmodev/config kubectl $@
}

##COSMO DEV
hcosmodev() {
  KUBECONFIG=~/.kube/.kube_cosmodev/config helm $@
}

##COSMO DEV
mcicluster() {
  KUBECONFIG=~/.kube/.kube_mci/config kubectl $@
}

alias mci='mcicluster'


##COSMO DEV
smcicluster() {
  KUBECONFIG=~/.kube/.kube_mci/config stern $@
}

alias smci='smcicluster'


##SCOSMO DEV
scosmodev() {
  KUBECONFIG=~/.kube/.kube_cosmodev/config stern $@
}


cosmodevk9s() {
  KUBECONFIG=~/.kube/.kube_cosmodev/config k9s --all-namespaces $@
}

cosmoshowcase() {
  KUBECONFIG=~/.kube/.kube_cosmodev/.kube_showcase/config kubectl $@
}


cosmoshowcasek9s() {
  KUBECONFIG=~/.kube/.kube_cosmodev/.kube_showcase/config k9s --all-namespaces $@
}

rolanddev() {
  KUBECONFIG=~/.kube/.kube_roland/.kube_dev/config kubectl $@
}

rolandtest() {
  KUBECONFIG=~/.kube/.kube_roland/.kube_test/config kubectl $@
}

rolandprod() {
  KUBECONFIG=~/.kube/.kube_roland/.kube_prod/config kubectl $@
}

srolandprod() {
  KUBECONFIG=~/.kube/.kube_roland/.kube_prod/config stern $@
}

sagcssshowcase() {
  KUBECONFIG=~/.kube/.kube_agcs/.kube_showcase/config stern $@
}


kacluster() {
  KUBECONFIG=~/.kube/.kube_ka/config kubectl $@
}

skacluster() {
  KUBECONFIG=~/.kube/.kube_ka/config stern $@
}

ggwcluster() {
  KUBECONFIG=~/.kube/.kube_ggw/.kube_prod/config kubectl $@
}


srccluster() {
  KUBECONFIG=~/.kube/.kube_src/config kubectl $@
}

sternsrc() {
  KUBECONFIG=~/.kube/.kube_src/config stern $@
}

howdencluster() {
  KUBECONFIG=~/.kube/.kube_howden/config kubectl $@
}

sternhowden() {
  KUBECONFIG=~/.kube/.kube_howden/config stern $@
}


alias concho="safehouse claude --dangerously-skip-permissions"


#k9s plugin configurations

source ~/.antigen.zsh

export PATH="$PATH:/Library/Developer/CommandLineTools/Library/Frameworks/Python3.framework/Versions/3.9/bin/python3:/usr/local/bin"


# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
ZSH_THEME=""  # prompt handled by starship (was powerlevel10k/powerlevel10k)

# Set list of themes to pick from when loading at random
# Setting this variable when ZSH_THEME=random will cause zsh to load
# a theme from this variable instead of looking in $ZSH/themes/
# If set to an empty array, this variable will have no effect.
# ZSH_THEME_RANDOM_CANDIDATES=( "robbyrussell" "agnoster" )

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to use hyphen-insensitive completion.
# Case-sensitive completion must be off. _ and - will be interchangeable.
# HYPHEN_INSENSITIVE="true"

# Uncomment one of the following lines to change the auto-update behavior
# zstyle ':omz:update' mode disabled  # disable automatic updates
# zstyle ':omz:update' mode auto      # update automatically without asking
# zstyle ':omz:update' mode reminder  # just remind me to update when it's time

# Uncomment the following line to change how often to auto-update (in days).
# zstyle ':omz:update' frequency 13

# Uncomment the following line if pasting URLs and other text is messed up.
# DISABLE_MAGIC_FUNCTIONS="true"

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
# DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# You can also set it to another string to have that shown instead of the default red dots.
# e.g. COMPLETION_WAITING_DOTS="%F{yellow}waiting...%f"
# Caution: this setting can cause issues with multiline prompts in zsh < 5.7.1 (see #5765)
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# You can set one of the optional three formats:
# "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# or set a custom format using the strftime function format specifications,
# see 'man strftime' for details.
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(
   git
   zsh-autosuggestions
   zsh-interactive-cd
   helm
   docker
)

source $ZSH/oh-my-zsh.sh

# User configuration

# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
# export PATH="$PATH:/Users/eolasehinde/.rd/bin"

eval "$(/opt/homebrew/bin/brew shellenv)"

#THIS MUST BE AT THE END OF THE FILE FOR SDKMAN TO WORK!!!
#export SDKMAN_DIR="$HOME/.sdkman"
#[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /Users/eolasehinde/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

#autosuggest color setting
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#f8dda6"

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
#[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh  # disabled: replaced by starship

# Added by Windsurf
export PATH="/Users/eolasehinde/.codeium/windsurf/bin:$PATH"
export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"

# OpenClaw Completion
[ -f "/Users/eolasehinde/.openclaw/completions/openclaw.zsh" ] && source "/Users/eolasehinde/.openclaw/completions/openclaw.zsh"

# opencode
export PATH=/Users/eolasehinde/.opencode/bin:$PATH

### MANAGED BY RANCHER DESKTOP START (DO NOT EDIT)
export PATH="/Users/eolasehinde/.rd/bin:$PATH"
### MANAGED BY RANCHER DESKTOP END (DO NOT EDIT)

# --- terminal tools (added 2026-11-04) ---
eval "$(zoxide init zsh)"
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --git --group-directories-first'
alias lt='eza --tree --level=2 --icons'
export BAT_THEME='Catppuccin Mocha'
alias cat='bat --paging=never --style=plain'
export EDITOR="nvim"
export VISUAL="nvim"
alias vim="nvim"
alias vi="nvim"

# --- ghostty shell integration (needed because windows start inside zellij) ---
if [[ "$TERM_PROGRAM" == "ghostty" || -n "$GHOSTTY_RESOURCES_DIR" ]]; then
  GHOSTTY_SI="${GHOSTTY_RESOURCES_DIR:-/Applications/Ghostty.app/Contents/Resources/ghostty}/shell-integration/zsh/ghostty-integration"
  [[ -f "$GHOSTTY_SI" ]] && source "$GHOSTTY_SI"
  unset GHOSTTY_SI
fi

# --- fast line editing (added 2026-11-04) ---
# fzf: Ctrl-R fuzzy history, Ctrl-T pick files into the command, Alt-C jump to a directory
source <(fzf --zsh)
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border=rounded --color=bg+:#313244,bg:-1,spinner:#f5e0dc,hl:#f38ba8,fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc,marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8,selected-bg:#45475a,border:#6c7086'
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
bindkey '^ ' autosuggest-accept

# --- starship prompt (added 2026-11-04) --- keep at end of file
eval "$(starship init zsh)"

# click on the command line to move the cursor (see ~/.config/zsh/mouse.zsh)
source ~/.config/zsh/mouse.zsh

# yazi: when it quits (or "cd to path" is chosen), the shell follows into that folder
y() { local tmp; tmp="$(mktemp -t yazi-cwd.XXXXXX)"; command yazi "$@" --cwd-file="$tmp"; local d; d="$(cat -- "$tmp" 2>/dev/null)"; rm -f -- "$tmp"; [[ -n "$d" && "$d" != "$PWD" ]] && cd -- "$d"; }
alias yazi=y
