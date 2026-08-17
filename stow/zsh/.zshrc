autoload -Uz compinit
compinit

HISTFILE="$HOME/.zsh_history"
HISTSIZE=10000
SAVEHIST=50000
setopt EXTENDED_HISTORY
setopt HIST_EXPIRE_DUPS_FIRST
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY

function cheat() {
  command curl "cheat.sh/$1"
}

alias ll='ls -la'
alias la='ls -A'
alias ..='cd ..'
alias ...='cd ../..'

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# Route node and npm-family commands through Aube's project-aware shims.
if command -v aube >/dev/null 2>&1; then
  eval "$(aube activate zsh)"
fi

if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook zsh)"
fi

if command -v zoxide >/dev/null 2>&1; then
  export _ZO_ECHO=1
  export _ZO_RESOLVE_SYMLINKS=1
  eval "$(zoxide init zsh --cmd cd)"
fi

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

# Syntax highlighting must be sourced after other Zsh plugins and setup.
if [[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi
