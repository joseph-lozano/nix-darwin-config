#!/bin/bash

set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
  printf '%s\n' "error: macOS settings can only be applied on Darwin" >&2
  exit 1
fi

sudo -v

if ! /usr/bin/arch -x86_64 /usr/bin/true >/dev/null 2>&1; then
  printf '%s\n' "Installing Rosetta 2..."
  sudo /usr/sbin/softwareupdate --install-rosetta --agree-to-license
fi

sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setglobalstate on
sudo /usr/libexec/ApplicationFirewall/socketfilterfw --setstealthmode on

sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool true
sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool true
sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate ConfigDataInstall -bool true
sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool true
sudo /usr/bin/defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool true

pam_module="/opt/homebrew/lib/pam/pam_reattach.so"
if [[ ! -f "$pam_module" ]]; then
  printf 'error: expected pam-reattach module at %s\n' "$pam_module" >&2
  exit 1
fi

pam_config="$(mktemp)"
trap 'rm -f "$pam_config"' EXIT
cat >"$pam_config" <<EOF
# sudo_local: local config file which survives system updates and is included for sudo
auth       optional       $pam_module ignore_ssh
auth       sufficient     pam_tid.so
EOF
sudo /usr/bin/install -o root -g wheel -m 0444 "$pam_config" /etc/pam.d/sudo_local

/usr/bin/defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
/usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 15
/usr/bin/defaults write NSGlobalDomain KeyRepeat -int 2
/usr/bin/defaults write com.apple.dock autohide -bool true
/usr/bin/defaults write com.apple.dock orientation -string left
/usr/bin/defaults write com.apple.dock show-recents -bool false

disable_symbolic_hotkey() {
  /usr/bin/defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
    -dict-add "$1" '<dict><key>enabled</key><false/></dict>'
}

# Reserve the built-in screenshot shortcuts for CleanShot X.
disable_symbolic_hotkey 28
disable_symbolic_hotkey 29
disable_symbolic_hotkey 30
disable_symbolic_hotkey 31
disable_symbolic_hotkey 184

# Free Command-Space for Raycast. Raycast still needs that hotkey selected once.
disable_symbolic_hotkey 64

# Clear stale Command/Option remaps. The built-in keyboard should use standard keys.
/usr/bin/hidutil property --set '{"UserKeyMapping":[]}' >/dev/null

dockutil --remove all --no-restart
dockutil --add "/System/Applications/Messages.app" --no-restart
dockutil --add "/Applications/Ghostty.app" --no-restart
dockutil --add "/Applications/Cursor.app" --no-restart
dockutil --add "/Applications/Safari.app" --no-restart
dockutil --add "/Applications/Slack.app" --no-restart
dockutil --add "/Applications/Discord.app" --no-restart
dockutil --add "/System/Applications/System Settings.app" --no-restart

settings_activator="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
if [[ -x "$settings_activator" ]]; then
  "$settings_activator" -u
fi

/usr/bin/killall Dock >/dev/null 2>&1 || true
/usr/bin/killall cfprefsd >/dev/null 2>&1 || true

printf '%s\n' "macOS security, keyboard, shortcut, and Dock settings applied."
