_: {
  homebrew = {
    enable = true;
    # Automatically remove packages not contained in list
    onActivation.cleanup = "uninstall";
    global.brewfile = true;
    masApps = { };
    taps = [
      # "homebrew/cask-versions"
    ];
    # Ideally leave this empty and only use nix to manage this
    brews = [ ];
    casks = [
      "1password"
      "1password-cli"
      "balenaetcher"
      "chatgpt"
      "choosy"
      "cursor"
      "discord"
      "firefox"
      "font-intone-mono-nerd-font"
      "ghostty"
      "google-chrome"
      "handy"
      "iina"
      "nvidia-geforce-now"
      "obsidian"
      "orbstack"
      "postgres-app"
      "raycast"
      "rectangle-pro"
      "screenflow"
      "setapp"
      "slack"
      "spotify"
      "steam"
      "tailscale-app"
      "zoom"
    ];
  };
}
