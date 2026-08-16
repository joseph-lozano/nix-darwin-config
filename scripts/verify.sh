#!/bin/bash

set -euo pipefail

failures=0

pass() {
  printf 'ok: %s\n' "$1"
}

fail() {
  printf 'not ok: %s\n' "$1" >&2
  failures=$((failures + 1))
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 is available"
  else
    fail "$1 is not available"
  fi
}

check_symlink() {
  if [[ -L "$1" ]]; then
    pass "$1 is Stow-managed"
  else
    fail "$1 is not a symlink"
  fi
}

export PATH="$HOME/.local/bin:$HOME/.amp/bin:/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate bash)"
fi
if command -v aube >/dev/null 2>&1; then
  eval "$(aube activate bash)"
fi

for command_name in \
  amp aube brew codex delta direnv fastfetch fd ffmpeg gh git glow herdr \
  jq mise node npm pi plannotator rg sbx stow vim yt-dlp zoxide; do
  check_command "$command_name"
done

if brew bundle check --file="$HOME/nix-darwin-config/Brewfile" >/dev/null; then
  pass "Brewfile dependencies are installed"
else
  fail "Brewfile dependencies are incomplete"
fi

check_symlink "$HOME/.gitconfig"
check_symlink "$HOME/.zshrc"
check_symlink "$HOME/.config/ghostty/config"

if [[ -f "$HOME/.codex/config.toml" && -w "$HOME/.codex/config.toml" && ! -L "$HOME/.codex/config.toml" ]]; then
  pass "Codex config is writable application state"
else
  fail "Codex config must be a writable regular file"
fi

if [[ -f "$HOME/.pi/agent/settings.json" && -w "$HOME/.pi/agent/settings.json" && ! -L "$HOME/.pi/agent/settings.json" ]]; then
  pass "Pi settings are writable application state"
else
  fail "Pi settings must be a writable regular file"
fi

if jq -e '.npmCommand == ["mise", "exec", "node@lts", "--", "npm"]' \
  "$HOME/.pi/agent/settings.json" >/dev/null; then
  pass "Pi has an explicit mise-managed npm command"
else
  fail "Pi npmCommand is missing or incorrect"
fi

if jq -e '
  any(.hooks.Stop[]?.hooks[]?;
    .type == "command" and ((.command // "") | endswith("/plannotator"))
  )
' "$HOME/.codex/hooks.json" >/dev/null; then
  pass "Codex Plannotator hook is installed"
else
  fail "Codex Plannotator hook is missing"
fi

for path in \
  "$HOME/.agents/skills/herdr/SKILL.md" \
  "$HOME/.agents/skills/plannotator-review/SKILL.md" \
  "$HOME/.config/amp/plugins/plannotator.ts" \
  "$HOME/.pi/agent/extensions/herdr-agent-state.ts"; do
  if [[ -f "$path" ]]; then
    pass "$path exists"
  else
    fail "$path is missing"
  fi
done

for command_name in amp codex; do
  command_path="$(command -v "$command_name" 2>/dev/null || true)"
  case "$command_path" in
    /nix/store/* | "$HOME/.nix-profile"/*)
      fail "$command_name resolves to a Nix-owned binary at $command_path"
      ;;
    *)
      pass "$command_name is not Nix-owned"
      ;;
  esac
done

if /bin/zsh -n "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.zshrc" "$HOME/.p10k.zsh"; then
  pass "Zsh configuration parses"
else
  fail "Zsh configuration has a syntax error"
fi

if [[ "$(uname -s)" == "Darwin" ]]; then
  if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q 'enabled'; then
    pass "macOS application firewall is enabled"
  else
    fail "macOS application firewall is disabled"
  fi
  if grep -q 'pam_tid.so' /etc/pam.d/sudo_local; then
    pass "Touch ID for sudo is configured"
  else
    fail "Touch ID for sudo is not configured"
  fi
fi

if ((failures > 0)); then
  printf '\n%d verification check(s) failed.\n' "$failures" >&2
  exit 1
fi

printf '\nAll setup verification checks passed.\n'
