{ self, pkgs }: {
  security.pam.enableSudoTouchIdAuth = true;
  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  system.defaults = {
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

  system.keyboard = {
    enableKeyMapping = true;
    swapLeftCommandAndLeftAlt = true;
  };

  fonts.packages = [
    pkgs.nerd-fonts.intone-mono
  ];
}
