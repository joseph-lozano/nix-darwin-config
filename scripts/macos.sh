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

while IFS= read -r service; do
  [[ -n "$service" ]] || continue
  sudo /usr/sbin/networksetup -setdnsservers "$service" 1.1.1.1 1.0.0.1
done < <(/usr/sbin/networksetup -listallnetworkservices | /usr/bin/tail -n +2 | /usr/bin/sed 's/^*//')

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
pam_existing="$(mktemp)"
trap 'rm -f "$pam_config" "$pam_existing"' EXIT
if sudo /bin/test -f /etc/pam.d/sudo_local; then
  sudo /bin/cat /etc/pam.d/sudo_local | /bin/cat >"$pam_existing"
fi

pam_marker="# Managed by ~/nix-darwin-config/scripts/macos.sh; other lines are preserved."
{
  printf '%s\n' "$pam_marker"
  printf 'auth       optional       %s ignore_ssh\n' "$pam_module"
  printf '%s\n' "auth       sufficient     pam_tid.so"
  /usr/bin/awk -v marker="$pam_marker" '
    $0 == marker { next }
    /pam_reattach\.so/ { next }
    /pam_tid\.so/ { next }
    { print }
  ' "$pam_existing"
} >"$pam_config"
sudo /usr/bin/install -o root -g wheel -m 0444 "$pam_config" /etc/pam.d/sudo_local

/usr/bin/defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
/usr/bin/defaults write NSGlobalDomain InitialKeyRepeat -int 15
/usr/bin/defaults write NSGlobalDomain KeyRepeat -int 2
/usr/bin/defaults write NSGlobalDomain AppleShowAllExtensions -bool true
/usr/bin/defaults write NSGlobalDomain NSAutomaticCapitalizationEnabled -bool false
/usr/bin/defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false
/usr/bin/defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
/usr/bin/defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
/usr/bin/defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
/usr/bin/defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
/usr/bin/defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Clicking -bool true
/usr/bin/defaults write com.apple.finder ShowPathbar -bool true
/usr/bin/defaults write com.apple.finder ShowStatusBar -bool true
/usr/bin/defaults write com.apple.finder AppleShowAllFiles -bool true
/usr/bin/defaults write com.apple.finder FXDefaultSearchScope -string SCcf
/usr/bin/defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
/usr/bin/defaults write com.apple.menuextra.battery ShowPercent -string YES
/usr/bin/defaults write com.apple.controlcenter BatteryShowPercentage -bool true
/usr/bin/defaults write com.apple.dock autohide -bool true
/usr/bin/defaults write com.apple.dock autohide-delay -float 0
/usr/bin/defaults write com.apple.dock autohide-time-modifier -float 0.5
/usr/bin/defaults write com.apple.dock orientation -string left
/usr/bin/defaults write com.apple.dock tilesize -int 48
/usr/bin/defaults write com.apple.dock show-recents -bool false
/usr/bin/defaults write com.apple.dock wvous-tl-corner -int 1
/usr/bin/defaults write com.apple.dock wvous-tr-corner -int 1
/usr/bin/defaults write com.apple.dock wvous-bl-corner -int 1
/usr/bin/defaults write com.apple.dock wvous-br-corner -int 1
/usr/bin/defaults write com.apple.dock wvous-tl-modifier -int 0
/usr/bin/defaults write com.apple.dock wvous-tr-modifier -int 0
/usr/bin/defaults write com.apple.dock wvous-bl-modifier -int 0
/usr/bin/defaults write com.apple.dock wvous-br-modifier -int 0

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

add_login_item() {
  local app_path="$1"
  local hidden="$2"

  if [[ -d "$app_path" ]]; then
    osascript -e "tell application \"System Events\" to make login item at end with properties {path:\"$app_path\", hidden:$hidden}" >/dev/null
  fi
}

add_login_item "/Applications/Rectangle Pro.app" false
add_login_item "/Applications/1Password.app" true
add_login_item "/Applications/Raycast.app" true

settings_activator="/System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings"
if [[ -x "$settings_activator" ]]; then
  "$settings_activator" -u
fi

/usr/bin/killall Dock >/dev/null 2>&1 || true
/usr/bin/killall cfprefsd >/dev/null 2>&1 || true

printf '%s\n' "macOS security, keyboard, shortcut, and Dock settings applied."
