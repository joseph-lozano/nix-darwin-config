{ pkgs, ... }: {
  imports = [
    ./home/git.nix
    ./home/zsh.nix
    # ../home/nvim 
  ];
  home = {
    stateVersion = "23.11";
    sessionVariables = {
      PAGER = "less";
      CLICLOLOR = 1;
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    packages = [
      pkgs.bun
      pkgs.curl
      pkgs.direnv
      pkgs.ffmpeg
      pkgs.gh
      pkgs.git
      pkgs.glow
      pkgs.htop
      pkgs.jq
      pkgs.less
      pkgs.neofetch
      pkgs.neovim
      pkgs.nix-direnv
      pkgs.pre-commit
      pkgs.tree
      pkgs.vim
      pkgs.wget
      pkgs.youtube-dl
      pkgs.zoxide
      pkgs.zsh
      pkgs.zsh-powerlevel10k

      pkgs.nodejs_20
    ];
  };

  programs = {
    git = {
      enable = true;
      ignores = [ ".DS_Store" ];
    };
    zsh = {
      enable = true;
      shellAliases = {
        phx = "iex -S mix phx.server";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
      initExtra = ''
      source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
      source ~/.p10k.zsh
      '';
    };
    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };
    direnv = {
      enable = true;
    };
  };
}
