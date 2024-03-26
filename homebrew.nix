_: {
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    # Automatically remove packages not contained in list
    onActivation.cleanup = "zap";
    global.brewfile = true;
    masApps = { };
    taps = [
      "homebrew/cask-versions"
    ];
    # Ideally leave this empty and only use nix to manage this 
    brews = [ ];
    casks = [
      "1password"
      "arc"
      "discord"
      "firefox-developer-edition"
      "iterm2"
      "obs"
      "raycast"
      "slack"
      "spotify"
      "visual-studio-code"
      "vlc"
    ];
  };
}