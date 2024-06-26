_: {
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    # autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    history = {
      # Expire duplicates first
      expireDuplicatesFirst = true;
      # Save timestamp into the history file
      extended = true;
      # If a new command line being added to the history list duplicates an older one, the older command is removed from the list (even if it is not the previous event)
      ignoreAllDups = true;
      # Do not enter command lines into the history list if they are duplicates of the previous event
      ignoreDups = true;
      # Do not enter command lines into the history list if they match any one of the given shell patterns
      ignorePatterns = [ ];
      # Do not enter command lines into the history list if the first character is a space
      ignoreSpace = true;
      # History file location	string
      # programs.zsh.history.path = "${pkgs.home-manager.home}/.zsh_history";
      # Number of history lines to save	
      save = 50000;
      # Number of history lines to keep
      size = 10000;
      # Share command history between zsh sessions
      share = true;
    };
    initExtra = ''
      eval "$(direnv hook zsh)"
      function cheat() {
        command curl "cheat.sh/$1"
      }
    '';
  };
}
