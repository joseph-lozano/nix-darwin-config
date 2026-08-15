#!/bin/sh

set -eu

repo_url="https://github.com/joseph-lozano/nix-darwin-config.git"
config_dir="/Users/joseph/nix-darwin-config"
flake_config="Josephs-MacBook-Pro"
operation="install"

fail() {
  printf 'error: %s\n' "$1" >&2
  exit 1
}

[ "$(/usr/bin/uname -s)" = "Darwin" ] || fail "this configuration requires macOS"
[ "$(/usr/bin/uname -m)" = "arm64" ] || fail "this configuration requires an Apple-silicon Mac running a native arm64 shell"
[ "$(/usr/bin/id -un)" = "joseph" ] || fail "this configuration requires the macOS user joseph"
[ "$HOME" = "/Users/joseph" ] || fail "expected HOME to be /Users/joseph"

if ! /usr/bin/xcode-select -p >/dev/null 2>&1; then
  printf '%s\n' "Apple Command Line Tools are required. Complete the installer window; this script will continue automatically."
  /usr/bin/xcode-select --install >/dev/null 2>&1 || true
  until /usr/bin/xcode-select -p >/dev/null 2>&1; do
    /bin/sleep 5
  done
fi

if ! command -v nix >/dev/null 2>&1 && [ ! -x /nix/var/nix/profiles/default/bin/nix ]; then
  printf '%s\n' "Installing Determinate Nix..."
  /usr/bin/curl --proto '=https' --tlsv1.2 -fsSL https://install.determinate.systems/nix \
    | /bin/sh -s -- install
fi

if [ -f /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
  # shellcheck disable=SC1091
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

nix_bin="$(command -v nix 2>/dev/null || true)"
if [ -z "$nix_bin" ] && [ -x /nix/var/nix/profiles/default/bin/nix ]; then
  nix_bin="/nix/var/nix/profiles/default/bin/nix"
fi
[ -n "$nix_bin" ] || fail "Nix was not found after installation"

if [ -e "$config_dir" ]; then
  operation="update"
  [ -d "$config_dir/.git" ] || fail "$config_dir exists but is not a Git checkout"
  [ "$(/usr/bin/git -C "$config_dir" branch --show-current)" = "main" ] || fail "$config_dir must be on the main branch"
  [ -z "$(/usr/bin/git -C "$config_dir" status --porcelain)" ] || fail "$config_dir has uncommitted changes"
  printf '%s\n' "Updating the existing configuration checkout..."
  /usr/bin/git -C "$config_dir" fetch origin
  /usr/bin/git -C "$config_dir" merge --ff-only origin/main
else
  printf '%s\n' "Installing the configuration checkout..."
  /usr/bin/git clone "$repo_url" "$config_dir"
fi

printf '%s\n' "Checking and building the complete configuration..."
(
  cd "$config_dir"
  "$nix_bin" flake check --no-update-lock-file --show-trace
  "$nix_bin" build --no-link --no-update-lock-file ".#darwinConfigurations.$flake_config.system"
)

cat <<'EOF'

The build succeeded. Activation will install the declared applications and
change macOS settings. Homebrew cleanup is set to "uninstall", so any formula
or cask not declared in this repository will be removed.
EOF

printf 'Apply this configuration %s now? [y/N] ' "$operation" >/dev/tty
answer=
IFS= read -r answer </dev/tty || true
case "$answer" in
  y | Y | yes | YES)
    ;;
  *)
    printf '%s\n' "Activation skipped. The checked configuration is available at $config_dir."
    exit 0
    ;;
esac

(
  cd "$config_dir"
  /usr/bin/sudo "$nix_bin" run nix-darwin/master#darwin-rebuild -- \
    switch --flake ".#$flake_config"
)

mise_bin=""
for candidate in "/etc/profiles/per-user/joseph/bin/mise" "$HOME/.nix-profile/bin/mise"; do
  if [ -x "$candidate" ]; then
    mise_bin="$candidate"
    break
  fi
done
[ -n "$mise_bin" ] || fail "mise was not found after activation"

printf '%s\n' "Installing or updating the declared Node LTS and Aube versions..."
"$mise_bin" install
"$mise_bin" exec -- npm ci --prefix "$HOME/.pi/agent"

cat <<'EOF'

Configuration applied. On a new Mac, restart it and then follow the account
and app setup checklists in ~/nix-darwin-config/README.md.
EOF
