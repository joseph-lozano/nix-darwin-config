_: {
  homebrew = {
    enable = true;
    caskArgs.no_quarantine = true;
    # Automatically remove packages not contained in list
    onActivation.cleanup = "zap";
    global.brewfile = true;
    masApps = { };
    taps = [
      # "homebrew/cask-versions"
    ];
    # Ideally leave this empty and only use nix to manage this 
    brews = [ ];
    casks = [
      "1password"
      "balenaetcher"
      "choosy" 
      "cursor"
      "discord"
      "firefox"
      "ghostty"
      "google-chrome@canary"
      "livebook"
      "nvidia-geforce-now"
      "ollama"
      "orbstack"
      "postgres-unofficial"
      "raycast"
      "rectangle-pro"
      "screenflow"
      "setapp"
      "slack"
      "spotify"
      "steam"
      "vlc"
      "zoom"
    ];
  };
}
