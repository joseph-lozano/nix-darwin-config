#!/bin/bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

command -v stow >/dev/null 2>&1 || {
  printf '%s\n' "error: stow is required; run brew bundle first" >&2
  exit 1
}

mkdir -p "$HOME/.config" "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [[ -L "$HOME/.p10k.zsh" ]]; then
  rm "$HOME/.p10k.zsh"
fi

stow \
  --dir="$repo_dir/stow" \
  --target="$HOME" \
  --no-folding \
  --restow \
  ghostty git ssh starship zsh

printf '%s\n' "Static dotfiles linked with Stow."
