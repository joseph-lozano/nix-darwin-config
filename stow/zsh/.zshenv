export PAGER=less
export EDITOR=vim
export VISUAL=vim
export CLICOLOR=1
export SSH_AUTH_SOCK="$HOME/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"

typeset -U path PATH
path=(
  "$HOME/.local/bin"
  "$HOME/.amp/bin"
  /opt/homebrew/opt/curl/bin
  /opt/homebrew/bin
  /opt/homebrew/sbin
  $path
)
