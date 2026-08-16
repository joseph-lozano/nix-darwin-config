#!/bin/sh

set -eu

repo_url="https://github.com/joseph-lozano/nix-darwin-config.git"
config_dir="/Users/joseph/nix-darwin-config"

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

[ "$(/usr/bin/uname -s)" = "Darwin" ] || fail "this setup requires macOS"
[ "$(/usr/bin/uname -m)" = "arm64" ] || fail "this setup requires an Apple-silicon Mac running a native arm64 shell"
[ "$(/usr/bin/id -un)" = "joseph" ] || fail "this setup requires the macOS user joseph"
[ "$HOME" = "/Users/joseph" ] || fail "expected HOME to be /Users/joseph"

if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  printf '%s\n' "Apple Command Line Tools are required. Complete the installer window; setup will continue automatically."
  /usr/bin/xcode-select --install >/dev/null 2>&1 || true
  until /usr/bin/xcode-select -p >/dev/null 2>&1; do
    /bin/sleep 5
  done
fi

if [ "${JOSEPH_MAC_SETUP_FROM_CHECKOUT:-0}" != "1" ]; then
  if [ -e "$config_dir" ]; then
    [ -d "$config_dir/.git" ] || fail "$config_dir exists but is not a Git checkout"
    [ "$(/usr/bin/git -C "$config_dir" branch --show-current)" = "main" ] || fail "$config_dir must be on the main branch"
    [ -z "$(/usr/bin/git -C "$config_dir" status --porcelain)" ] || fail "$config_dir has uncommitted changes"
    printf '%s\n' "Updating the existing setup checkout..."
    /usr/bin/git -C "$config_dir" fetch --prune origin main
    /usr/bin/git -C "$config_dir" merge --ff-only origin/main
  else
    printf '%s\n' "Cloning the setup repository..."
    /usr/bin/git clone "$repo_url" "$config_dir"
  fi

  exec /usr/bin/env JOSEPH_MAC_SETUP_FROM_CHECKOUT=1 /bin/sh "$config_dir/install.sh"
fi

if [ ! -x /opt/homebrew/bin/brew ]; then
  printf '%s\n' "Homebrew requires administrator access. Enter your macOS password when prompted."
  /usr/bin/sudo -v || fail "administrator access is required to install Homebrew"

  printf '%s\n' "Installing Homebrew..."
  homebrew_installer="$(/usr/bin/curl --proto '=https' --tlsv1.2 -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  NONINTERACTIVE=1 /bin/bash -c "$homebrew_installer"
fi

eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$HOME/.amp/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

printf '%s\n' "Installing or upgrading Homebrew applications and tools..."
brew update
if brew list --cask firefox >/dev/null 2>&1; then
  printf '%s\n' "Uninstalling Firefox..."
  brew uninstall --cask firefox
fi
brew bundle install --file="$config_dir/Brewfile"

/bin/bash "$config_dir/scripts/dotfiles.sh"
/bin/bash "$config_dir/scripts/agents.sh"
/bin/bash "$config_dir/scripts/macos.sh"
/bin/bash "$config_dir/scripts/verify.sh"

cat <<'EOF'

Setup completed successfully. Restart the Mac, then finish the account,
permissions, and app hotkey checklist in ~/nix-darwin-config/README.md.
Rerun this same installer at any time to update the managed setup.
EOF
