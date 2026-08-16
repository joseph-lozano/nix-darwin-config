if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# Keep mise-managed commands available in login shells before interactive
# activation in .zshrc takes over.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi
