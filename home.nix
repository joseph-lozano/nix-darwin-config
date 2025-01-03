{ pkgs, ... }: {
  imports = [
    ./home/git.nix
    ./home/zsh.nix
    # ../home/nvim 
  ];

  home = {
    stateVersion = "24.05";

    sessionVariables = {
      PAGER = "less";
      CLICLOLOR = 1;
      EDITOR = "nvim";
      VISUAL = "nvim";
      SSH_AUTH_SOCK = "$HOME/Library/Group\\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";
    };

    file = {
      ".p10k.zsh".source = ./home/p10k.zsh;

      "/Library/Application Support/com.mitchellh.ghostty/config".text = ''
        font-family="IntoneMono Nerd Font Mono"
        theme=catppuccin-mocha
        font-size=22
      '';

      ".config/nvim" = {
        source = ./home/nvim;
        recursive = true;
      };
    };

    packages = [
      pkgs.bun
      pkgs.curl
      pkgs.devenv
      pkgs.direnv
      pkgs.ffmpeg
      pkgs.gh
      pkgs.git
      pkgs.glow
      pkgs.htop
      pkgs.jq
      pkgs.less
      pkgs.mise
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

      pkgs.nodejs_22
      pkgs.nodejs_22.pkgs."gitmoji-cli"
    ];
  };

  programs = {
    git = {
      enable = true;
      ignores = [ ".DS_Store" ];
    };

    ssh = {
      enable = true;
      extraConfig = ''
      Host *
        IdentityAgent "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
      '';
    };

    zsh = {
      enable = true;
      shellAliases = {
        phx = "iex -S mix phx.server";
        pn = "pnpm";
      };
      oh-my-zsh = {
        enable = true;
        plugins = [ "git" ];
      };
      initExtra = ''
        eval "$(/opt/homebrew/bin/brew shellenv)"
        source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme
        source ~/.p10k.zsh
        export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock
      '';
    };

    zoxide = {
      enable = true;
      enableZshIntegration = true;
      options = [ "--cmd cd" ];
    };

    direnv.enable = true;
  };
}
