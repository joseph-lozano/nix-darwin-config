{self}: {
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
      "/System/Applications/Utilities/Terminal.app"
      "/Applications/Arc.app"
      "/Applications/Nix Apps/Slack.app"
      "/Applications/Nix Apps/Discord.app"
      "/Applications/Arc.app"
      "/System/Applications/System Settings.app"
    ];
    NSGlobalDomain."com.apple.swipescrolldirection" = false;
  };
}
