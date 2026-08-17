#!/bin/bash

set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
checks=0
failures=()

pass() {
  checks=$((checks + 1))
}

fail() {
  checks=$((checks + 1))
  failures+=("$1")
}

check_command() {
  if command -v "$1" >/dev/null 2>&1; then
    pass "$1 is available"
  else
    fail "$1 is not available"
  fi
}

check_runs() {
  local label="$1"
  shift

  if "$@" >/dev/null 2>&1; then
    pass "$label"
  else
    fail "$label"
  fi
}

check_symlink() {
  if [[ -L "$1" && "$1" -ef "$2" ]]; then
    pass "$1 points to its Stow source"
  else
    fail "$1 does not point to $2"
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
  jq mise node npm pi plannotator rg sbx starship stow vim yt-dlp zoxide; do
  check_command "$command_name"
done

check_runs "Amp starts successfully" amp --version
check_runs "Codex starts successfully" codex --version
check_runs "Pi loads configured extensions" pi --help --offline
check_runs "Aube's npm shim starts successfully" npm --version
check_runs "Pi's explicit mise/npm route starts successfully" \
  mise exec node@lts -- npm --version

if brew bundle check --file="$repo_dir/Brewfile" >/dev/null; then
  pass "Brewfile dependencies are installed"
else
  fail "Brewfile dependencies are incomplete; run brew bundle check --file=$repo_dir/Brewfile"
fi

check_symlink \
  "$HOME/.config/ghostty/config" \
  "$repo_dir/stow/ghostty/.config/ghostty/config"
check_symlink "$HOME/.gitconfig" "$repo_dir/stow/git/.gitconfig"
check_symlink "$HOME/.ssh/config" "$repo_dir/stow/ssh/.ssh/config"
check_symlink "$HOME/.zprofile" "$repo_dir/stow/zsh/.zprofile"
check_symlink "$HOME/.zshenv" "$repo_dir/stow/zsh/.zshenv"
check_symlink "$HOME/.zshrc" "$repo_dir/stow/zsh/.zshrc"
check_symlink \
  "$HOME/.config/starship.toml" \
  "$repo_dir/stow/starship/.config/starship.toml"

if [[ -f "$HOME/.codex/config.toml" && -w "$HOME/.codex/config.toml" && ! -L "$HOME/.codex/config.toml" ]]; then
  pass "Codex config is writable application state"
else
  fail "Codex config must be a writable regular file"
fi

if [[ -f "$HOME/.codex/hooks.json" && -w "$HOME/.codex/hooks.json" && ! -L "$HOME/.codex/hooks.json" ]]; then
  pass "Codex hooks are writable application state"
else
  fail "Codex hooks must be a writable regular file"
fi

if /usr/bin/awk '
  /^[[:space:]]*\[features\][[:space:]]*$/ { in_features = 1; next }
  /^[[:space:]]*\[/ { in_features = 0 }
  in_features && /^[[:space:]]*hooks[[:space:]]*=[[:space:]]*true([[:space:]]|$)/ {
    enabled = 1
  }
  END { exit !enabled }
' "$HOME/.codex/config.toml"; then
  pass "Codex hooks are explicitly enabled"
else
  fail "Codex config does not enable hooks"
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
  "$HOME/.codex/herdr-agent-state.sh" \
  "$HOME/.config/amp/plugins/plannotator.ts" \
  "$HOME/.pi/agent/extensions/herdr-agent-state.ts"; do
  if [[ -f "$path" ]]; then
    pass "$path exists"
  else
    fail "$path is missing"
  fi
done

for zsh_file in "$HOME/.zshenv" "$HOME/.zprofile" "$HOME/.zshrc"; do
  if /bin/zsh -n "$zsh_file"; then
    pass "$zsh_file parses"
  else
    fail "$zsh_file has a syntax error"
  fi
done

if [[ "$(uname -s)" == "Darwin" ]]; then
  if /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate | grep -q 'enabled'; then
    pass "macOS application firewall is enabled"
  else
    fail "macOS application firewall is disabled"
  fi

  if /usr/bin/awk '
    /^[[:space:]]*auth[[:space:]]+optional[[:space:]]+\/opt\/homebrew\/lib\/pam\/pam_reattach\.so[[:space:]]+ignore_ssh([[:space:]]|$)/ {
      reattach = NR
    }
    /^[[:space:]]*auth[[:space:]]+sufficient[[:space:]]+pam_tid\.so([[:space:]]|$)/ {
      touch_id = NR
    }
    END { exit !(reattach > 0 && touch_id > reattach) }
  ' /etc/pam.d/sudo_local; then
    pass "Touch ID for sudo is ordered after pam-reattach"
  else
    fail "Touch ID PAM entries are missing or ordered incorrectly"
  fi

  for hotkey in 28 29 30 31 64 184; do
    hotkey_enabled="$(
      /usr/libexec/PlistBuddy \
        -c "Print :AppleSymbolicHotKeys:$hotkey:enabled" \
        "$HOME/Library/Preferences/com.apple.symbolichotkeys.plist" \
        2>/dev/null || true
    )"
    if [[ "$hotkey_enabled" == "false" ]]; then
      pass "macOS symbolic hotkey $hotkey is disabled"
    else
      fail "macOS symbolic hotkey $hotkey is not disabled"
    fi
  done

  if keyboard_mapping="$(/usr/bin/hidutil property --get UserKeyMapping 2>/dev/null)" \
    && ! grep -q 'HIDKeyboardModifierMappingSrc' <<<"$keyboard_mapping"; then
    pass "Command and Option have no HID remapping"
  else
    fail "a Command or Option HID remapping is still active"
  fi
fi

if ((${#failures[@]} > 0)); then
  printf '\nVerification failed (%d of %d checks):\n' "${#failures[@]}" "$checks" >&2
  printf '  - %s\n' "${failures[@]}" >&2
  printf '\nRerun ./scripts/verify.sh from the setup checkout after correcting the failures.\n' >&2
  exit 1
fi

printf '\nAll %d setup verification checks passed.\n' "$checks"
