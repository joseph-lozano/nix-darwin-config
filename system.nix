{ self, pkgs }: {
  security.pam.enableSudoTouchIdAuth = true;
  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  system.defaults = {
    dock.autohide = false;
    dock.orientation = "left";
    dock.show-recents = false;
    dock.persistent-apps = [
      "/System/Applications/Messages.app"
      "/Applications/iTerm.app"
      "/Applications/Visual Studio Code.app"
      "/Applications/Arc.app"
      "/Applications/Slack.app"
      "/Applications/Discord.app"
      "/System/Applications/System Settings.app"
    ];
    NSGlobalDomain."com.apple.swipescrolldirection" = false;
    NSGlobalDomain."InitialKeyRepeat" = 1;
    NSGlobalDomain."KeyRepeat" = 1;
  };

  fonts = {
    fontDir.enable = true;
    fonts =
      [ (pkgs.nerdfonts.override { fonts = [ "IntelOneMono" ]; }) ];
  };
}
