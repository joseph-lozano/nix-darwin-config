{ pkgs, ... }: {
  imports = [
    ./home/git.nix
    # ../home/nvim ../home/starship ../home/zsh 
  ];
  home = {
    stateVersion = "24.05";
    sessionVariables = {
      PAGER = "less";
      CLICLOLOR = 1;
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    packages = [
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
      pkgs.nixfmt
      pkgs.tree
      pkgs.vim
      pkgs.wget
      pkgs.youtube-dl
      pkgs.zsh
    ];
  };

  programs = {
    git = {
      enable = true;
      ignores = [ ".DS_Store" ];
    };
    zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
        theme = "robbyrussell";
      };
    };
  };
}
