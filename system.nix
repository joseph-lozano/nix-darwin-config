{ self, pkgs }: {
  security.pam.services.sudo_local = {
    reattach = true;
    touchIdAuth = true;
  };

  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  system.defaults = {
    CustomSystemPreferences."/Library/Preferences/com.apple.SoftwareUpdate" = {
      AutomaticCheckEnabled = true;
      AutomaticDownload = true;
      ConfigDataInstall = true;
      CriticalUpdateInstall = true;
    };
    SoftwareUpdate.AutomaticallyInstallMacOSUpdates = true;
    dock.autohide = true;
    dock.orientation = "left";
    dock.show-recents = false;
    dock.persistent-apps = [
      "/System/Applications/Messages.app"
      "/Applications/Ghostty.app"
      "/Applications/Cursor.app"
      "/Applications/Safari.app"
      "/Applications/Slack.app"
      "/Applications/Discord.app"
      "/System/Applications/System Settings.app"
    ];
    NSGlobalDomain."com.apple.swipescrolldirection" = false;
    NSGlobalDomain.InitialKeyRepeat = 15;
    NSGlobalDomain.KeyRepeat = 2;
  };

  system.activationScripts.postActivation.text = ''
    if ! /usr/bin/arch -x86_64 /usr/bin/true 2>/dev/null; then
      echo >&2 "installing Rosetta 2..."
      /usr/sbin/softwareupdate --install-rosetta --agree-to-license
    fi

    # Preserve unrelated macOS shortcuts while freeing shortcuts for preferred apps.
    disable_symbolic_hotkey() {
      /bin/launchctl asuser "$(/usr/bin/id -u joseph)" \
        /usr/bin/sudo --user=joseph -- \
        /usr/bin/defaults write com.apple.symbolichotkeys \
          AppleSymbolicHotKeys -dict-add "$1" \
          '<dict><key>enabled</key><false/></dict>'
    }

    disable_symbolic_hotkey 28  # Shift-Command-3: capture the screen
    disable_symbolic_hotkey 29  # Control-Shift-Command-3: copy the screen
    disable_symbolic_hotkey 30  # Shift-Command-4: capture an area
    disable_symbolic_hotkey 31  # Control-Shift-Command-4: copy an area
    disable_symbolic_hotkey 184 # Shift-Command-5: screenshot and recording options
    disable_symbolic_hotkey 64  # Command-Space: Spotlight search

    /bin/launchctl asuser "$(/usr/bin/id -u joseph)" \
      /usr/bin/sudo --user=joseph -- \
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
  '';

  system.keyboard = {
    enableKeyMapping = true;
    swapLeftCommandAndLeftAlt = true;
  };
}
